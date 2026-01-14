import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'secure_storage_service.dart';

/// Simplified encryption service using flutter_secure_storage exclusively
/// 
/// This service provides:
/// - Cross-platform secure key storage (Android Keystore + iOS Keychain)
/// - XChaCha20-Poly1305 AEAD encryption
/// - Automatic hardware-backed security when available
/// - No custom native implementations needed
class EncryptionService {
  final SecureStorageService _secureStorage;
  
  // Single encryption key identifier
  static const String _encryptionKeyId = 'app_master_encryption_key_v1';
  
  // Envelope versioning for future compatibility
  static const int _currentVersion = 1;
  static const String _algorithm = 'XChaCha20-Poly1305';
  
  // In-memory key cache for performance
  crypto.SecretKey? _cachedKey;
  DateTime? _cacheTimestamp;
  static const Duration _cacheLifetime = Duration(minutes: 15);
  
  EncryptionService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  /// Get or create the master encryption key
  /// 
  /// Uses flutter_secure_storage which automatically:
  /// - Android: Stores in Android Keystore with hardware backing
  /// - iOS: Stores in iOS Keychain with hardware backing
  /// - Handles platform-specific security configurations
  Future<crypto.SecretKey> _getEncryptionKey() async {
    // Check memory cache first
    if (_cachedKey != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age < _cacheLifetime) {
        return _cachedKey!;
      } else {
        _clearKeyCache();
      }
    }

    try {
      // Try to load existing key from secure storage
      final keyData = await _secureStorage.getSecret(_encryptionKeyId);
      
      if (keyData != null && keyData.isNotEmpty) {
        // Key exists, decode and cache it
        final keyBytes = base64Decode(keyData);
        final secretKey = crypto.SecretKey(keyBytes);
        _cacheKey(secretKey);
        
        if (kDebugMode) {
          debugPrint('✓ Loaded existing encryption key from secure storage');
        }
        
        return secretKey;
      }
      
      // No key exists, generate a new one
      return await _generateAndStoreNewKey();
      
    } catch (e) {
      throw EncryptionException(
        'Failed to obtain encryption key: $e',
        code: 'KEY_ACCESS_FAILED',
      );
    }
  }

  /// Generate a new encryption key and store it securely
  Future<crypto.SecretKey> _generateAndStoreNewKey() async {
    try {
      // Generate cryptographically secure random key
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = await algorithm.newSecretKey();
      final keyBytes = await secretKey.extractBytes();
      
      // Store key in secure storage (flutter_secure_storage handles platform specifics)
      final keyData = base64Encode(keyBytes);
      await _secureStorage.saveSecret(_encryptionKeyId, keyData);
      
      // Cache the key
      _cacheKey(secretKey);
      
      if (kDebugMode) {
        debugPrint('✓ Generated and stored new encryption key');
        debugPrint('  Platform: ${defaultTargetPlatform.name}');
        debugPrint('  Storage: flutter_secure_storage (automatic hardware backing)');
      }
      
      return secretKey;
      
    } catch (e) {
      throw EncryptionException(
        'Failed to generate encryption key: $e',
        code: 'KEY_GENERATION_FAILED',
      );
    }
  }

  /// Cache key in memory for performance
  void _cacheKey(crypto.SecretKey key) {
    _cachedKey = key;
    _cacheTimestamp = DateTime.now();
  }

  /// Clear sensitive key material from memory
  void _clearKeyCache() {
    _cachedKey = null;
    _cacheTimestamp = null;
  }

  /// Encrypt plaintext with XChaCha20-Poly1305 AEAD
  Future<String> encrypt(String plainText, {String? associatedData}) async {
    if (plainText.isEmpty) {
      throw EncryptionException('Cannot encrypt empty plaintext');
    }

    try {
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = await _getEncryptionKey();
      final nonce = algorithm.newNonce();

      final secretBox = await algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: secretKey,
        nonce: nonce,
        aad: associatedData != null ? utf8.encode(associatedData) : [],
      );

      // Create versioned envelope for future compatibility
      final envelope = {
        'v': _currentVersion,
        'alg': _algorithm,
        'iv': base64Encode(secretBox.nonce),
        'ct': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
        if (associatedData != null) 'aad': base64Encode(utf8.encode(associatedData)),
      };

      return json.encode(envelope);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt ciphertext with automatic AAD validation
  Future<String> decrypt(String encryptedText, {String? associatedData}) async {
    if (encryptedText.isEmpty) {
      throw EncryptionException('Cannot decrypt empty ciphertext');
    }

    try {
      final envelope = json.decode(encryptedText) as Map<String, dynamic>;
      
      // Validate envelope version
      final version = envelope['v'] as int?;
      if (version == null || version > _currentVersion) {
        throw EncryptionException('Unsupported envelope version: $version');
      }

      // Validate algorithm
      final algorithm = envelope['alg'] as String?;
      if (algorithm != _algorithm) {
        throw EncryptionException('Unsupported algorithm: $algorithm');
      }

      // Extract components
      final iv = base64Decode(envelope['iv'] as String);
      final ct = base64Decode(envelope['ct'] as String);
      final tag = base64Decode(envelope['tag'] as String);

      // Handle associated data
      List<int> aadBytes = [];
      if (envelope.containsKey('aad') && (envelope['aad'] as String).isNotEmpty) {
        aadBytes = base64Decode(envelope['aad'] as String);
      } else if (associatedData != null) {
        aadBytes = utf8.encode(associatedData);
      }

      // Decrypt
      final secretKey = await _getEncryptionKey();
      final xchacha = crypto.Xchacha20.poly1305Aead();

      final secretBox = crypto.SecretBox(
        ct,
        nonce: iv,
        mac: crypto.Mac(tag),
      );

      final clearBytes = await xchacha.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aadBytes,
      );

      return utf8.decode(clearBytes);
      
    } on crypto.SecretBoxAuthenticationError {
      throw EncryptionException('Authentication failed - data may be tampered');
    } on FormatException {
      throw EncryptionException('Invalid encrypted format');
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Clear all encryption keys and cached data
  Future<void> clearEncryptionKey() async {
    _clearKeyCache();
    await _secureStorage.deleteSecret(_encryptionKeyId);
    
    if (kDebugMode) {
      debugPrint('✓ Encryption key cleared from secure storage');
    }
  }

  /// Get storage information for diagnostics
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final hasKey = await _secureStorage.getSecret(_encryptionKeyId) != null;
      return {
        'hasKey': hasKey,
        'storage': 'flutter_secure_storage',
        'platform': defaultTargetPlatform.name,
        'security': 'automatic_hardware_backing',
        'cached': _cachedKey != null,
      };
    } catch (e) {
      return {
        'hasKey': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================================================
  // PASSWORD-BASED ENCRYPTION (for backups)
  // ============================================================================

  /// Encrypt data with password using Argon2id + XChaCha20-Poly1305
  /// 
  /// This is used for manual backups that need to be restored on different devices.
  /// The password is used to derive an encryption key using Argon2id KDF.
  /// 
  /// Security:
  /// - Argon2id makes brute-force attacks expensive
  /// - Random salt prevents rainbow table attacks
  /// - XChaCha20-Poly1305 provides authenticated encryption
  /// - Password never stored or transmitted
  Future<String> encryptWithPassword(String plainText, String password) async {
    if (plainText.isEmpty) {
      throw EncryptionException('Cannot encrypt empty plaintext');
    }
    if (password.isEmpty) {
      throw EncryptionException('Password cannot be empty');
    }

    try {
      // Generate random salt for Argon2id
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final salt = algorithm.newNonce(); // 24 bytes of random data
      
      // Derive encryption key from password using Argon2id
      final argon2id = crypto.Argon2id(
        memory: 65536, // 64 MB
        iterations: 3,
        parallelism: 4,
        hashLength: 32, // 256-bit key
      );
      
      final derivedKey = await argon2id.deriveKey(
        secretKey: crypto.SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      
      // Encrypt data with derived key
      final nonce = algorithm.newNonce();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: derivedKey,
        nonce: nonce,
      );
      
      // Create envelope with KDF parameters
      final envelope = {
        'v': _currentVersion,
        'alg': _algorithm,
        'kdf': 'argon2id',
        'kdf_params': {
          'memory': 65536,
          'iterations': 3,
          'parallelism': 4,
          'salt': base64Encode(salt),
        },
        'iv': base64Encode(secretBox.nonce),
        'ct': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
      };
      
      return json.encode(envelope);
      
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Password-based encryption failed: $e');
    }
  }

  /// Decrypt data with password
  /// 
  /// Derives the encryption key from the password using the same KDF parameters
  /// that were used during encryption (stored in the envelope).
  Future<String> decryptWithPassword(String encryptedText, String password) async {
    if (encryptedText.isEmpty) {
      throw EncryptionException('Cannot decrypt empty ciphertext');
    }
    if (password.isEmpty) {
      throw EncryptionException('Password cannot be empty');
    }

    try {
      // Parse envelope
      final envelope = json.decode(encryptedText) as Map<String, dynamic>;
      
      // Verify version
      final version = envelope['v'] as int?;
      if (version == null || version > _currentVersion) {
        throw EncryptionException('Unsupported envelope version: $version');
      }
      
      // Verify KDF
      final kdf = envelope['kdf'] as String?;
      if (kdf != 'argon2id') {
        throw EncryptionException('Unsupported KDF: $kdf');
      }
      
      // Extract KDF parameters
      final kdfParams = envelope['kdf_params'] as Map<String, dynamic>;
      final salt = base64Decode(kdfParams['salt'] as String);
      final memory = kdfParams['memory'] as int;
      final iterations = kdfParams['iterations'] as int;
      final parallelism = kdfParams['parallelism'] as int;
      
      // Derive encryption key from password
      final argon2id = crypto.Argon2id(
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
        hashLength: 32,
      );
      
      final derivedKey = await argon2id.deriveKey(
        secretKey: crypto.SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      
      // Extract encrypted data
      final iv = base64Decode(envelope['iv'] as String);
      final ct = base64Decode(envelope['ct'] as String);
      final tag = base64Decode(envelope['tag'] as String);
      
      // Decrypt data
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretBox = crypto.SecretBox(
        ct,
        nonce: iv,
        mac: crypto.Mac(tag),
      );
      
      final clearBytes = await algorithm.decrypt(
        secretBox,
        secretKey: derivedKey,
      );
      
      return utf8.decode(clearBytes);
      
    } on crypto.SecretBoxAuthenticationError {
      throw EncryptionException('Incorrect password or corrupted data');
    } on FormatException {
      throw EncryptionException('Invalid backup format');
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Password-based decryption failed: $e');
    }
  }

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Get password strength warning (non-blocking)
  String? getPasswordWarning(String password) {
    if (password.length < 12) {
      return 'Recommended: Use at least 12 characters for better security';
    }
    
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int variety = 0;
    if (hasLower) variety++;
    if (hasUpper) variety++;
    if (hasDigit) variety++;
    if (hasSpecial) variety++;
    
    if (variety < 2) {
      return 'Recommended: Mix letters, numbers, and symbols';
    }
    
    return null;
  }
}

/// Custom exception for encryption operations
class EncryptionException implements Exception {
  final String message;
  final String? code;
  
  EncryptionException(this.message, {this.code});
  
  @override
  String toString() => 'EncryptionException: $message${code != null ? ' (code: $code)' : ''}';
}