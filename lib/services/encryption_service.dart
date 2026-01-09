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
}

/// Custom exception for encryption operations
class EncryptionException implements Exception {
  final String message;
  final String? code;
  
  EncryptionException(this.message, {this.code});
  
  @override
  String toString() => 'EncryptionException: $message${code != null ? ' (code: $code)' : ''}';
}