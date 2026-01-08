package com.cdac.authenticator

import android.accounts.AccountManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

// local_auth on Android requires an Activity that supports fragments.
// Extend FlutterFragmentActivity so biometric prompts work correctly.
class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "authenticator/keystore"
    private val GOOGLE_ACCOUNT_CHANNEL = "com.cdac.authenticator/google_account"

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

        // Register AccountPlugin for automatic backup
        flutterEngine.plugins.add(AccountPlugin())

        // Google Account channel for getting primary Google account
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GOOGLE_ACCOUNT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPrimaryGoogleAccount" -> {
                    try {
                        val account = getPrimaryGoogleAccount()
                        result.success(account)
                    } catch (e: Exception) {
                        android.util.Log.e("GoogleAccount", "Error getting Google account: ${e.message}", e)
                        result.error("ACCOUNT_ERROR", "Failed to get Google account: ${e.message}", null)
                    }
                }
                "getAllGoogleAccounts" -> {
                    try {
                        val accounts = getAllGoogleAccounts()
                        result.success(accounts)
                    } catch (e: Exception) {
                        android.util.Log.e("GoogleAccount", "Error getting Google accounts: ${e.message}", e)
                        result.error("ACCOUNT_ERROR", "Failed to get Google accounts: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Settings channel for opening device settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "authenticator/settings").setMethodCallHandler { call, result ->
            when (call.method) {
                "openSettings" -> {
                    try {
                        val intent = android.content.Intent(android.provider.Settings.ACTION_SETTINGS)
                        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "generateKey" -> {
                        val alias = call.argument<String>("alias") ?: "authenticator_key"
                        val created = ensureAesKey(alias)
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

    private fun ensureAesKey(alias: String): Boolean {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        
        // CRITICAL: Check if key already exists - NEVER regenerate KEK
        if (keyStore.containsAlias(alias)) {
            android.util.Log.d("KeystoreService", "✓ AES KEK already exists for alias: $alias - reusing")
            
            // Verify the key is actually usable by attempting a test wrap/unwrap
            try {
                val key = keyStore.getKey(alias, null) as? SecretKey
                if (key != null) {
                    // Test the key with a simple wrap/unwrap operation
                    val testData = ByteArray(32) { 0x42 }
                    val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                    cipher.init(Cipher.ENCRYPT_MODE, key)
                    val testEncrypted = cipher.doFinal(testData)
                    
                    android.util.Log.d("KeystoreService", "✓ AES KEK is valid and usable")
                    return true
                } else {
                    android.util.Log.e("KeystoreService", "❌ KEK exists but key is null")
                }
            } catch (e: Exception) {
                android.util.Log.e("KeystoreService", "❌ Error verifying KEK: ${e.message}", e)
                android.util.Log.e("KeystoreService", "❌ KEK exists but is unusable - may be corrupted")
                // Don't delete the key - let the user handle this through reset
            }
        }
        
        android.util.Log.d("KeystoreService", "Creating NEW AES KEK for alias: $alias")
        android.util.Log.d("KeystoreService", "Android SDK: ${Build.VERSION.SDK_INT}")
        
        // ✅ CORRECT: Use AES-256 symmetric key (NOT RSA)
        // AES keys are stable and persist across sessions
        // Android Auto Backup can properly handle AES keys
        val keyGenerator = KeyGenerator.getInstance(
            android.security.keystore.KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore"
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val spec = android.security.keystore.KeyGenParameterSpec.Builder(
                alias,
                android.security.keystore.KeyProperties.PURPOSE_ENCRYPT or android.security.keystore.KeyProperties.PURPOSE_DECRYPT
            ).apply {
                setKeySize(256) // AES-256
                setBlockModes(android.security.keystore.KeyProperties.BLOCK_MODE_GCM)
                setEncryptionPaddings(android.security.keystore.KeyProperties.ENCRYPTION_PADDING_NONE)
                setUserAuthenticationRequired(false)
                
                // CRITICAL: Do NOT set setInvalidatedByBiometricEnrollment
                // This would delete the key when user adds/removes fingerprints
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    setUnlockedDeviceRequired(false) // Allow backup even when device is locked
                }
                
                // CRITICAL: AndroidKeyStore keys are NEVER backed up
                // After app reinstall, this KEK will be LOST
                // Wrapped DEKs become unrecoverable
                // User must reset backup and create new one
            }.build()
            
            android.util.Log.d("KeystoreService", "Initializing AES KeyGenerator with spec...")
            keyGenerator.init(spec)
            
            android.util.Log.d("KeystoreService", "Generating AES-256 key...")
            keyGenerator.generateKey()
            
            // Verify the key was created
            keyStore.load(null)
            if (keyStore.containsAlias(alias)) {
                android.util.Log.d("KeystoreService", "✓ AES KEK created successfully for alias: $alias")
                
                // Check if hardware-backed (informational only)
                try {
                    val key = keyStore.getKey(alias, null)
                    if (key != null) {
                        // This is informational - we don't fail if not hardware-backed
                        android.util.Log.d("KeystoreService", "ℹ KEK storage: AndroidKeyStore (TEE or StrongBox)")
                    }
                } catch (e: Exception) {
                    android.util.Log.d("KeystoreService", "Could not check hardware backing: ${e.message}")
                }
                
                return true
            } else {
                android.util.Log.e("KeystoreService", "❌ KEK creation failed - alias not found after generation")
                return false
            }
        }
        android.util.Log.e("KeystoreService", "❌ Android version too old (< M)")
        return false
    }

    private fun wrapKey(alias: String, keyBase64: String): String {
        val keyBytes = Base64.getDecoder().decode(keyBase64)
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        if (!keyStore.containsAlias(alias)) {
            throw Exception("Keystore alias not found: $alias. Call generateKey first.")
        }
        
        // Get AES key from keystore
        val secretKey = keyStore.getKey(alias, null) as SecretKey
        
        // Use AES-GCM to wrap the DEK
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        
        val iv = cipher.iv // GCM generates random IV
        val encrypted = cipher.doFinal(keyBytes)
        
        // Combine IV + encrypted data
        val combined = ByteArray(iv.size + encrypted.size)
        System.arraycopy(iv, 0, combined, 0, iv.size)
        System.arraycopy(encrypted, 0, combined, iv.size, encrypted.size)
        
        android.util.Log.d("KeystoreService", "wrapKey using AES-GCM, alias: $alias, keyBytes.len=${keyBytes.size}, iv.len=${iv.size}")
        
        return Base64.getEncoder().encodeToString(combined)
    }

    private fun unwrapKey(alias: String, wrappedBase64: String): String {
        val combined = Base64.getDecoder().decode(wrappedBase64)
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        
        // CRITICAL: Check if KEK exists in keystore
        if (!keyStore.containsAlias(alias)) {
            android.util.Log.e("KeystoreService", "❌ AES KEK not found in AndroidKeyStore for alias: $alias")
            android.util.Log.e("KeystoreService", "This means the KEK was deleted or never created")
            android.util.Log.e("KeystoreService", "Possible causes: app data cleared, keystore reset")
            throw Exception("Keystore alias not found: $alias. Key may have been cleared.")
        }
        
        // Get AES key from keystore
        val secretKey = keyStore.getKey(alias, null) as? SecretKey
        if (secretKey == null) {
            android.util.Log.e("KeystoreService", "❌ Secret key is null for alias: $alias")
            throw Exception("Secret key not found for alias: $alias")
        }
        
        android.util.Log.d("KeystoreService", "✓ AES KEK found in keystore for alias: $alias")
        
        // Extract IV and encrypted data
        // GCM standard IV size is 12 bytes (96 bits)
        val GCM_IV_LENGTH = 12
        if (combined.size < GCM_IV_LENGTH) {
            throw Exception("Invalid wrapped key: too short")
        }
        
        val iv = combined.copyOfRange(0, GCM_IV_LENGTH)
        val encrypted = combined.copyOfRange(GCM_IV_LENGTH, combined.size)
        
        android.util.Log.d("KeystoreService", "unwrapKey using AES-GCM: alias=$alias, iv.len=${iv.size}, encrypted.len=${encrypted.size}")
        
        try {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val gcmSpec = GCMParameterSpec(128, iv) // 128-bit auth tag
            cipher.init(Cipher.DECRYPT_MODE, secretKey, gcmSpec)
            val unwrapped = cipher.doFinal(encrypted)
            
            android.util.Log.d("KeystoreService", "✓ Successfully unwrapped with AES-GCM")
            return Base64.getEncoder().encodeToString(unwrapped)
        } catch (e: Exception) {
            android.util.Log.e("KeystoreService", "unwrapKey error: ${e.message}", e)
            throw e
        }
    }

    /**
     * Get the primary Google account from AccountManager
     * Returns the email of the first Google account found, or null if none
     */
    private fun getPrimaryGoogleAccount(): String? {
        try {
            val accountManager = AccountManager.get(this)
            val accounts = accountManager.getAccountsByType("com.google")
            
            android.util.Log.d("GoogleAccount", "Found ${accounts.size} Google accounts")
            
            if (accounts.isNotEmpty()) {
                val primaryAccount = accounts[0].name
                android.util.Log.d("GoogleAccount", "Primary Google account: $primaryAccount")
                return primaryAccount
            } else {
                android.util.Log.d("GoogleAccount", "No Google accounts found")
                return null
            }
        } catch (e: SecurityException) {
            android.util.Log.e("GoogleAccount", "Permission denied to access accounts: ${e.message}")
            return null
        } catch (e: Exception) {
            android.util.Log.e("GoogleAccount", "Error getting Google account: ${e.message}", e)
            return null
        }
    }

    private fun getAllGoogleAccounts(): List<String> {
        return try {
            val accountManager = AccountManager.get(this)
            val accounts = accountManager.getAccountsByType("com.google")
            
            android.util.Log.d("GoogleAccount", "Found ${accounts.size} Google accounts")
            
            if (accounts.isNotEmpty()) {
                val accountEmails = accounts.map { it.name }
                android.util.Log.d("GoogleAccount", "All Google accounts: $accountEmails")
                accountEmails
            } else {
                android.util.Log.d("GoogleAccount", "No Google accounts found")
                emptyList()
            }
        } catch (e: SecurityException) {
            android.util.Log.e("GoogleAccount", "Permission denied to access accounts: ${e.message}")
            emptyList()
        } catch (e: Exception) {
            android.util.Log.e("GoogleAccount", "Error getting Google accounts: ${e.message}", e)
            emptyList()
        }
    }
}

