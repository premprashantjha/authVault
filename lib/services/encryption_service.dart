import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' hide Key;
import 'package:encrypt/encrypt.dart';
import 'secure_storage_service.dart';

/// Service for encrypting/decrypting sensitive data
/// Uses AES-256 encryption with a key derived from secure storage
/// 
/// SECURITY: 
/// - Encryption key is stored in Flutter Secure Storage (hardware-backed)
/// - Each secret is encrypted with AES-256-GCM
/// - Uses secure random IV for each encryption
/// - Secrets are encrypted before storage in database
class EncryptionService {
  final SecureStorageService _secureStorage;
  // Direct key storage (current method)
  static const String _encryptionKeyKey = 'authenticator_encryption_key';
  // Legacy wrapped key storage keys (for cleanup)
  static const String _wrappedKeyKey = 'authenticator_wrapped_encryption_key';
  static const String _keystoreAvailableKey = 'authenticator_keystore_available';
  
  EncryptionService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();
  
  static const int _keyLength = 32; // 256 bits for AES-256
  
  /// Get or create encryption key using direct secure storage
  /// Keystore proved unreliable (IllegalBlockSizeException on all devices)
  Future<Key> _getEncryptionKey() async {
    // Check for existing direct key
    String? directKey = await _secureStorage.getSecret(_encryptionKeyKey);
    if (directKey != null && directKey.isNotEmpty) {
      return Key(Uint8List.fromList(base64Decode(directKey)));
    }

    // Clean up any old keystore-wrapped keys
    final wrapped = await _secureStorage.getSecret(_wrappedKeyKey);
    if (wrapped != null) {
      await _secureStorage.deleteSecret(_wrappedKeyKey);
      await _secureStorage.deleteSecret(_keystoreAvailableKey);
      if (kDebugMode) {
        debugPrint('Info: Cleaned up old keystore-wrapped keys');
      }
    }

    // Generate new key and store directly
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
    final keyBase64 = base64Encode(keyBytes);
    await _secureStorage.saveSecret(_encryptionKeyKey, keyBase64);
    if (kDebugMode) {
      debugPrint('Info: Generated new encryption key in secure storage');
    }
    return Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypt a string value
  Future<String> encrypt(String plainText) async {
    try {
      final key = await _getEncryptionKey();
  // Use AES-GCM (authenticated encryption). Use a 96-bit (12-byte) nonce for GCM.
  final iv = IV.fromSecureRandom(12);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Combine IV and encrypted data: base64(iv) + ':' + base64(encrypted)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt a string value
  Future<String> decrypt(String encryptedText) async {
    try {
      final key = await _getEncryptionKey();
      final parts = encryptedText.split(':');
      
      if (parts.length != 2) {
        throw FormatException('Invalid encrypted format');
      }
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

  return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Clear encryption key (for logout/reset)
  /// WARNING: This will make all encrypted data unrecoverable
  Future<void> clearEncryptionKey() async {
    await _secureStorage.deleteSecret(_encryptionKeyKey);
    await _secureStorage.deleteSecret(_wrappedKeyKey);
    await _secureStorage.deleteSecret(_keystoreAvailableKey);
  }
}

