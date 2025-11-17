package com.example.authenticator

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.BadPaddingException
import javax.crypto.IllegalBlockSizeException
// Avoid depending on OAEPParameterSpec/MGF1/PSource imports which may not be
// available on all Android API levels. Use an OAEP transformation string and
// default parameters supported by the platform provider.

// local_auth on Android requires an Activity that supports fragments.
// Extend FlutterFragmentActivity so biometric prompts work correctly.
class MainActivity : FlutterFragmentActivity() {
	private val CHANNEL = "authenticator/keystore"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			try {
				when (call.method) {
					"generateKey" -> {
						val alias = call.argument<String>("alias") ?: "authenticator_key"
						val created = ensureKeyPair(alias)
						result.success(created)
					}
					"wrapKey" -> {
						val alias = call.argument<String>("alias") ?: "authenticator_key"
						val keyBase64 = call.argument<String>("key") ?: ""
						val wrapped = wrapKey(alias, keyBase64)
						result.success(wrapped)
					}
					"unwrapKey" -> {
						val alias = call.argument<String>("alias") ?: "authenticator_key"
						val wrappedBase64 = call.argument<String>("wrapped") ?: ""
						val unwrapped = unwrapKey(alias, wrappedBase64)
						result.success(unwrapped)
					}
					else -> result.notImplemented()
				}
			} catch (e: Exception) {
				result.error("keystore_error", e.message, null)
			}
		}
	}

	private fun ensureKeyPair(alias: String): Boolean {
		val keyStore = KeyStore.getInstance("AndroidKeyStore")
		keyStore.load(null)

		if (keyStore.containsAlias(alias)) return true

		val kpg = KeyPairGenerator.getInstance("RSA", "AndroidKeyStore")
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			val spec = android.security.keystore.KeyGenParameterSpec.Builder(
				alias,
				android.security.keystore.KeyProperties.PURPOSE_ENCRYPT or android.security.keystore.KeyProperties.PURPOSE_DECRYPT
			).apply {
				setAlgorithmParameterSpec(java.security.spec.RSAKeyGenParameterSpec(2048, java.math.BigInteger("65537")))
				setDigests(android.security.keystore.KeyProperties.DIGEST_SHA256)
				setEncryptionPaddings(android.security.keystore.KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
				setUserAuthenticationRequired(false)
			}.build()
			kpg.initialize(spec)
			kpg.generateKeyPair()
			return true
		}
		return false
	}

	private fun wrapKey(alias: String, keyBase64: String): String {
		val keyBytes = Base64.getDecoder().decode(keyBase64)
		val keyStore = KeyStore.getInstance("AndroidKeyStore")
		keyStore.load(null)
		val entry = keyStore.getCertificate(alias) ?: throw Exception("Keystore alias not found: $alias")
		val publicKey = entry.publicKey

				// Use a platform-supported OAEP transformation. On Android the
				// provider may support "RSA/ECB/OAEPWithSHA-256AndMGF1Padding" which
				// uses SHA-256 for OAEP and MGF1; initialize with the public key.
				val cipher = try {
					Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")
				} catch (e: Exception) {
					// Fallback to a generic OAEPPadding transformation if the more
					// specific one isn't available.
					Cipher.getInstance("RSA/ECB/OAEPPadding")
				}
				cipher.init(Cipher.ENCRYPT_MODE, publicKey)
		val wrapped = cipher.doFinal(keyBytes)
		return Base64.getEncoder().encodeToString(wrapped)
	}

	private fun unwrapKey(alias: String, wrappedBase64: String): String {
		val wrapped = Base64.getDecoder().decode(wrappedBase64)
		val keyStore = KeyStore.getInstance("AndroidKeyStore")
		keyStore.load(null)
		val privKey = keyStore.getKey(alias, null) ?: throw Exception("Private key not found for alias: $alias")

				val cipher = try {
					Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")
				} catch (e: Exception) {
					Cipher.getInstance("RSA/ECB/OAEPPadding")
				}
				cipher.init(Cipher.DECRYPT_MODE, privKey)
		val unwrapped = cipher.doFinal(wrapped)
		return Base64.getEncoder().encodeToString(unwrapped)
	}
}
