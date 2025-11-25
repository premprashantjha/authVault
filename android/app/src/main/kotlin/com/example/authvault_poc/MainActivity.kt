package com.example.authenticator

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
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
	private var cipherTransformation: String? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		// Optimize startup: prevent window preview flash
		// This helps the splash screen appear faster
		if (savedInstanceState == null) {
			// First launch - optimize window creation
			window.setBackgroundDrawable(null)
		}
		
		super.onCreate(savedInstanceState)
		
		// Prevent screenshots and screen recording for security
		window.setFlags(
			WindowManager.LayoutParams.FLAG_SECURE,
			WindowManager.LayoutParams.FLAG_SECURE
		)
	}

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
				android.util.Log.e("KeystoreService", "Error: ${e.message}", e)
				result.error("keystore_error", e.message, null)
			}
		}
	}
	
	private fun getCipherTransformation(): String {
		// Cache the cipher transformation to ensure consistency
		if (cipherTransformation != null) {
			return cipherTransformation!!
		}
		
		// Try to determine which OAEP variant is supported
		cipherTransformation = try {
			val cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")
			"RSA/ECB/OAEPWithSHA-256AndMGF1Padding"
		} catch (e: Exception) {
			"RSA/ECB/OAEPPadding"
		}
		
		android.util.Log.d("KeystoreService", "Using cipher: $cipherTransformation")
		return cipherTransformation!!
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
		
		// Ensure the key exists
		if (!keyStore.containsAlias(alias)) {
			throw Exception("Keystore alias not found: $alias. Call generateKey first.")
		}
		
		val entry = keyStore.getCertificate(alias) ?: throw Exception("Certificate not found for alias: $alias")
		val publicKey = entry.publicKey

		// Use consistent cipher transformation
		val cipher = Cipher.getInstance(getCipherTransformation())
		cipher.init(Cipher.ENCRYPT_MODE, publicKey)
		val wrapped = cipher.doFinal(keyBytes)
		return Base64.getEncoder().encodeToString(wrapped)
	}

	private fun unwrapKey(alias: String, wrappedBase64: String): String {
		val wrapped = Base64.getDecoder().decode(wrappedBase64)
		val keyStore = KeyStore.getInstance("AndroidKeyStore")
		keyStore.load(null)
		
		// Ensure the key exists
		if (!keyStore.containsAlias(alias)) {
			throw Exception("Keystore alias not found: $alias. Key may have been cleared.")
		}
		
		val privKey = keyStore.getKey(alias, null) ?: throw Exception("Private key not found for alias: $alias")

		// Use the same consistent cipher transformation
		val cipher = Cipher.getInstance(getCipherTransformation())
		cipher.init(Cipher.DECRYPT_MODE, privKey)
		val unwrapped = cipher.doFinal(wrapped)
		return Base64.getEncoder().encodeToString(unwrapped)
	}
}
