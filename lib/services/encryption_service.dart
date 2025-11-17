import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'secure_storage_service.dart';
import 'keystore_service.dart';

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
  // Previously stored raw key (legacy)
  static const String _encryptionKeyKey = 'authenticator_encryption_key';
  // New wrapped key storage
  static const String _wrappedKeyKey = 'authenticator_wrapped_encryption_key';
  static const String _keystoreAlias = 'authenticator_data_key';
  
  EncryptionService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();
  
  static const int _keyLength = 32; // 256 bits for AES-256
  
  /// Get or create encryption key
  /// Key is stored in hardware-backed secure storage (Keychain/Keystore)
  Future<Key> _getEncryptionKey() async {
    final keystore = KeystoreService();

    // 1) Check for wrapped key (new flow)
    final wrapped = await _secureStorage.getSecret(_wrappedKeyKey);
    if (wrapped != null && wrapped.isNotEmpty) {
      // Unwrap via platform keystore
      final unwrappedBytes = await keystore.unwrapKey(_keystoreAlias, wrapped);
      return Key(Uint8List.fromList(unwrappedBytes));
    }

    // 2) Legacy raw key present? If so, migrate: wrap it and store wrapped key
    String? legacyKey = await _secureStorage.getSecret(_encryptionKeyKey);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      // Ensure keystore key exists
      await keystore.generateKey(_keystoreAlias);
      final legacyBytes = base64Decode(legacyKey);
      final wrappedNew = await keystore.wrapKey(_keystoreAlias, Uint8List.fromList(legacyBytes));
      await _secureStorage.saveSecret(_wrappedKeyKey, wrappedNew);
      // Remove legacy raw key
      await _secureStorage.deleteSecret(_encryptionKeyKey);
      return Key(Uint8List.fromList(legacyBytes));
    }

    // 3) No key exists yet: generate a new random AES key, wrap it and store wrapped
    final random = Random.secure();
    final keyBytes = List<int>.generate(_keyLength, (i) => random.nextInt(256));
    // Ensure keystore key exists
    await keystore.generateKey(_keystoreAlias);
    final wrappedKey = await keystore.wrapKey(_keystoreAlias, Uint8List.fromList(keyBytes));
    await _secureStorage.saveSecret(_wrappedKeyKey, wrappedKey);

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
  }
}

