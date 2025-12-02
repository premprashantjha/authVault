package com.cdac.authenticator

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

// local_auth on Android requires an Activity that supports fragments.
// Extend FlutterFragmentActivity so biometric prompts work correctly.
class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "authenticator/keystore"
    private var cipherTransformation: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) {
            window.setBackgroundDrawable(null)
        }
        super.onCreate(savedInstanceState)
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
                    "isKeyHardwareBacked" -> {
                        val alias = call.argument<String>("alias") ?: "authenticator_key"
                        val isHw = isKeyHardwareBacked(alias)
                        result.success(isHw)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                android.util.Log.e("KeystoreService", "Error: ${e.message}", e)
                result.error("keystore_error", e.message, null)
            }
        }
    }

    private fun isKeyHardwareBacked(alias: String): Boolean {
        return try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)
            if (!keyStore.containsAlias(alias)) return false
            val key = keyStore.getKey(alias, null) ?: return false
            val format = key.format
            return format == null
        } catch (e: Exception) {
            android.util.Log.e("KeystoreService", "isKeyHardwareBacked error: ${e.message}", e)
            false
        }
    }

    private fun getCipherTransformation(): String {
        if (cipherTransformation != null) {
            return cipherTransformation!!
        }
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
        if (!keyStore.containsAlias(alias)) {
            throw Exception("Keystore alias not found: $alias. Call generateKey first.")
        }
        val entry = keyStore.getCertificate(alias) ?: throw Exception("Certificate not found for alias: $alias")
        val publicKey = entry.publicKey
        val transformation = getCipherTransformation()
        android.util.Log.d("KeystoreService", "wrapKey using transformation: $transformation, alias: $alias, keyBytes.len=${keyBytes.size}")
        val cipher = Cipher.getInstance(transformation)
        cipher.init(Cipher.ENCRYPT_MODE, publicKey)
        val wrapped = cipher.doFinal(keyBytes)
        return Base64.getEncoder().encodeToString(wrapped)
    }

    private fun unwrapKey(alias: String, wrappedBase64: String): String {
        val wrapped = Base64.getDecoder().decode(wrappedBase64)
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        if (!keyStore.containsAlias(alias)) {
            throw Exception("Keystore alias not found: $alias. Key may have been cleared.")
        }
        val privKey = keyStore.getKey(alias, null) ?: throw Exception("Private key not found for alias: $alias")

        // Try primary OAEP transformation first, and fall back to PKCS1 if needed.
        val primary = getCipherTransformation()
        android.util.Log.d("KeystoreService", "unwrapKey attempt: alias=$alias, wrapped.len=${wrapped.size}, primary=$primary")
        try {
            val cipher = Cipher.getInstance(primary)
            cipher.init(Cipher.DECRYPT_MODE, privKey)
            val unwrapped = cipher.doFinal(wrapped)
            return Base64.getEncoder().encodeToString(unwrapped)
        } catch (e: IllegalBlockSizeException) {
            // This often indicates padding/provider mismatch on some OEM devices. Try a PKCS1 fallback.
            android.util.Log.w("KeystoreService", "Primary unwrap failed with IllegalBlockSizeException, trying PKCS1 fallback", e)
            try {
                val fallback = "RSA/ECB/PKCS1Padding"
                val cipher2 = Cipher.getInstance(fallback)
                cipher2.init(Cipher.DECRYPT_MODE, privKey)
                val unwrapped2 = cipher2.doFinal(wrapped)
                android.util.Log.w("KeystoreService", "PKCS1 fallback unwrap succeeded for alias=$alias")
                return Base64.getEncoder().encodeToString(unwrapped2)
            } catch (e2: Exception) {
                android.util.Log.e("KeystoreService", "PKCS1 fallback also failed", e2)
                throw e2
            }
        } catch (e: Exception) {
            android.util.Log.e("KeystoreService", "unwrapKey error", e)
            throw e
        }
    }
}

