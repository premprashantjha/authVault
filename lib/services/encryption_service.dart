import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'secure_storage_service.dart';
import 'keystore_service.dart';

/// Custom exception types for better error handling
class EncryptionException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;
  
  EncryptionException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'EncryptionException: $message${code != null ? ' (code: $code)' : ''}';
}

class KeystoreException extends EncryptionException {
  KeystoreException(String message, {String? code, Object? originalError})
      : super(message, code: code, originalError: originalError);
}

class DecryptionException extends EncryptionException {
  DecryptionException(String message, {String? code, Object? originalError})
      : super(message, code: code, originalError: originalError);
}

class EncryptionService {
  final SecureStorageService _secureStorage;
  final KeystoreService _keystoreService;
  
  // Key identifiers with version
  static const String _keystoreAlias = 'authenticator_master_kek_v1';
  static const String _wrappedDekKey = 'authenticator_wrapped_dek';
  static const String _directDekKey = 'authenticator_direct_dek';
  static const String _keystoreModeKey = 'authenticator_keystore_mode';
  
  // Envelope versioning
  static const int _currentVersion = 2;
  static const String _currentAlgorithm = 'XChaCha20-Poly1305';
  
  // Key management
  crypto.SecretKey? _cachedDek;
  DateTime? _cacheTimestamp;
  static const Duration _cacheLifetime = Duration(minutes: 15);
  
  EncryptionService({
    SecureStorageService? secureStorage,
    KeystoreService? keystoreService,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _keystoreService = keystoreService ?? KeystoreService();

  /// Get or create encryption key with platform keystore wrapping
  Future<crypto.SecretKey> _getEncryptionKey() async {
    // Check cache first
    if (_cachedDek != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age < _cacheLifetime) {
        return _cachedDek!;
      } else {
        await _clearKeyCache();
      }
    }

    try {
      // 1) If there is a wrapped DEK, try to unwrap it. Do NOT delete the wrapped blob
      // on failure here — we want to avoid destructive behavior that could cause
      // permanent data loss. If unwrap succeeds we'll migrate a copy into direct
      // secure storage for broader compatibility.
      final wrappedDek = await _secureStorage.getSecret(_wrappedDekKey);
      if (wrappedDek != null && wrappedDek.isNotEmpty) {
        try {
          final dek = await _loadKeystoreWrappedKey(wrappedDek);
          // Migrate a direct copy for compatibility (best-effort)
          try {
            final dekBytes = await dek.extractBytes();
            await _storeDirectKey(Uint8List.fromList(dekBytes));
          } catch (_) {
            // Migration failure is non-fatal — keep using the unwrapped DEK.
            if (kDebugMode) debugPrint('⚠ Migration to direct storage failed (non-fatal)');
          }
          return dek;
        } catch (e) {
          // Log and fall through to try direct storage next
          if (kDebugMode) debugPrint('⚠ Keystore unwrap attempt failed, will try direct secure storage: $e');
        }
      }

      // 2) Try loading direct DEK (stored in flutter_secure_storage)
      final directDek = await _secureStorage.getSecret(_directDekKey);
      if (directDek != null && directDek.isNotEmpty) {
        try {
          return await _loadDirectKey(directDek);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠ Loading direct DEK failed: $e');
          // fall through to generate new key
        }
      }

      // 3) No usable key found — generate a new DEK and store it in secure storage.
      // After storing directly, attempt to create a keystore-wrapped copy as a
      // best-effort (non-fatal) operation so devices with hardware keystore
      // can benefit later.
      return await _generateAndStoreNewKey();
    } catch (e) {
      throw EncryptionException(
        'Failed to obtain encryption key',
        code: 'KEY_RETRIEVAL_FAILED',
        originalError: e,
      );
    }
  }

  /// Load and unwrap keystore-protected DEK
  Future<crypto.SecretKey> _loadKeystoreWrappedKey(String wrappedDekBase64) async {
    try {
      final wrappedBytes = base64Decode(wrappedDekBase64);
      final dekBytes = await _keystoreService.unwrapKey(
        _keystoreAlias,
        wrappedBytes,
      );
      
      final secretKey = crypto.SecretKey(dekBytes);
      _cacheKey(secretKey);
      
      if (kDebugMode) {
        debugPrint('✓ Loaded keystore-wrapped DEK');
      }
      
      return secretKey;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠ Keystore unwrap failed: $e');
      }

      // Do NOT delete the wrapped blob here to avoid destructive behavior.
      // Higher-level logic may choose to retry or migrate. Surface a
      // KeystoreException so callers can decide how to proceed.
      throw KeystoreException(
        'Keystore unwrap failed',
        code: 'UNWRAP_FAILED',
        originalError: e,
      );
    }
  }

  /// Load direct DEK from secure storage (fallback mode)
  Future<crypto.SecretKey> _loadDirectKey(String directDekBase64) async {
    try {
      final dekBytes = base64Decode(directDekBase64);
      final secretKey = crypto.SecretKey(dekBytes);
      _cacheKey(secretKey);
      
      if (kDebugMode) {
        debugPrint('✓ Loaded direct DEK (fallback mode)');
      }
      
      return secretKey;
    } catch (e) {
      throw EncryptionException(
        'Failed to load direct key',
        code: 'DIRECT_KEY_LOAD_FAILED',
        originalError: e,
      );
    }
  }

  /// Generate new DEK using cryptographic RNG
  Future<crypto.SecretKey> _generateAndStoreNewKey() async {
    // Generate cryptographically secure random DEK
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = await algorithm.newSecretKey();
    final dekBytes = await secretKey.extractBytes();
    
    if (kDebugMode) {
      debugPrint('⚙ Generating new DEK with cryptographic RNG...');
    }

    // Store direct copy in secure storage first to guarantee app works across
    // devices without relying on keystore compatibility. Then attempt to
    // create a keystore-wrapped copy as a best-effort background step.
    try {
      await _storeDirectKey(Uint8List.fromList(dekBytes));
      _cacheKey(secretKey);

      if (kDebugMode) {
        debugPrint('✓ DEK stored directly in secure storage');
      }

      // Best-effort: try to create a keystore-wrapped copy. If it fails, do
      // not surface an error to callers — the app can continue using the
      // direct copy. This preserves compatibility and avoids crashes.
      try {
        await _storeKeystoreWrappedKey(Uint8List.fromList(dekBytes));
        if (kDebugMode) debugPrint('✓ Also stored DEK with keystore wrapping (best-effort)');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠ Best-effort keystore wrapping failed: $e');
      }

      return secretKey;
    } catch (e) {
      throw EncryptionException(
        'Failed to store encryption key',
        code: 'KEY_STORAGE_FAILED',
        originalError: e,
      );
    }
  }

  /// Store DEK wrapped by platform keystore
  Future<void> _storeKeystoreWrappedKey(List<int> dekBytes) async {
    try {
      // Ensure keystore key exists
      final generated = await _keystoreService.generateKey(_keystoreAlias);
      if (!generated) {
        throw KeystoreException(
          'Failed to generate keystore key',
          code: 'KEYSTORE_GEN_FAILED',
        );
      }

      // Wrap DEK with keystore KEK
      final wrappedDek = await _keystoreService.wrapKey(
        _keystoreAlias,
        Uint8List.fromList(dekBytes),
      );

      if (wrappedDek.length == 0) {
        throw KeystoreException(
          'Keystore returned empty wrapped key',
          code: 'EMPTY_WRAPPED_KEY',
        );
      }

      // Store wrapped DEK as base64 string
      await _secureStorage.saveSecret(_wrappedDekKey, base64Encode(wrappedDek));

      // If a direct copy exists, mark hybrid; otherwise mark wrapped.
      final directExists = await _secureStorage.getSecret(_directDekKey);
      if (directExists != null && directExists.isNotEmpty) {
        await _secureStorage.saveSecret(_keystoreModeKey, 'hybrid');
      } else {
        await _secureStorage.saveSecret(_keystoreModeKey, 'wrapped');
      }
    } catch (e) {
      if (e is KeystoreException) rethrow;
      throw KeystoreException(
        'Keystore wrapping failed',
        code: 'WRAP_FAILED',
        originalError: e,
      );
    }
  }

  /// Store DEK directly in secure storage (fallback)
  Future<void> _storeDirectKey(List<int> dekBytes) async {
    try {
      final dekBase64 = base64Encode(dekBytes);
      await _secureStorage.saveSecret(_directDekKey, dekBase64);
      // If a wrapped copy exists, mark hybrid; otherwise mark direct.
      final wrappedExists = await _secureStorage.getSecret(_wrappedDekKey);
      if (wrappedExists != null && wrappedExists.isNotEmpty) {
        await _secureStorage.saveSecret(_keystoreModeKey, 'hybrid');
      } else {
        await _secureStorage.saveSecret(_keystoreModeKey, 'direct');
      }
    } catch (e) {
      throw EncryptionException(
        'Failed to store direct key',
        code: 'DIRECT_STORAGE_FAILED',
        originalError: e,
      );
    }
  }

  /// Cache key in memory for performance
  void _cacheKey(crypto.SecretKey key) {
    _cachedDek = key;
    _cacheTimestamp = DateTime.now();
  }

  /// Clear sensitive key material from memory
  Future<void> _clearKeyCache() async {
    if (_cachedDek != null) {
      // Extract and overwrite the key bytes
      final bytes = await _cachedDek!.extractBytes();
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = 0; // Overwrite in place
      }
    }
    _cachedDek = null;
    _cacheTimestamp = null;
  }

  /// Encrypt plaintext with XChaCha20-Poly1305 AEAD
  Future<String> encrypt(String plainText, {String? associatedData}) async {
    if (plainText.isEmpty) {
      throw EncryptionException(
        'Cannot encrypt empty plaintext',
        code: 'EMPTY_PLAINTEXT',
      );
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

      final envelope = {
        'v': _currentVersion,
        'alg': _currentAlgorithm,
        'iv': base64Encode(secretBox.nonce),
        'ct': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
        // Store AAD in the envelope when provided so decryption can validate it
        // automatically. Stored as base64 to avoid charset issues.
        if (associatedData != null) 'aad': base64Encode(utf8.encode(associatedData)),
      };

      return json.encode(envelope);
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        'Encryption failed',
        code: 'ENCRYPT_FAILED',
        originalError: e,
      );
    }
  }

  /// Decrypt ciphertext with AAD validation
  Future<String> decrypt(String encryptedText, {String? associatedData}) async {
    if (encryptedText.isEmpty) {
      throw DecryptionException(
        'Cannot decrypt empty ciphertext',
        code: 'EMPTY_CIPHERTEXT',
      );
    }

    try {
      return await _decryptVersionedEnvelope(encryptedText, associatedData);
    } on FormatException {
      throw DecryptionException(
        'Invalid encrypted format',
        code: 'INVALID_FORMAT',
      );
    } catch (e) {
      if (e is DecryptionException) rethrow;
      throw DecryptionException(
        'Decryption failed',
        code: 'DECRYPT_FAILED',
        originalError: e,
      );
    }
  }

  /// Decrypt versioned JSON envelope
  Future<String> _decryptVersionedEnvelope(
    String encryptedText,
    String? associatedData,
  ) async {
    final envelope = json.decode(encryptedText) as Map<String, dynamic>;
    
    final version = envelope['v'] as int?;
    if (version == null || version > _currentVersion) {
      throw DecryptionException(
        'Unsupported envelope version: $version',
        code: 'UNSUPPORTED_VERSION',
      );
    }

    final algorithm = envelope['alg'] as String?;
    if (algorithm != _currentAlgorithm) {
      throw DecryptionException(
        'Unsupported algorithm: $algorithm',
        code: 'UNSUPPORTED_ALGORITHM',
      );
    }

    try {
      final iv = base64Decode(envelope['iv'] as String);
      final ct = base64Decode(envelope['ct'] as String);
      final tag = base64Decode(envelope['tag'] as String);

      // Determine AAD: prefer envelope-stored AAD (if present), otherwise use
      // the associatedData parameter provided by the caller. AAD must match
      // exactly the bytes used during encryption.
      List<int> aadBytes = [];
      if (envelope.containsKey('aad') && (envelope['aad'] as String).isNotEmpty) {
        aadBytes = base64Decode(envelope['aad'] as String);
      } else if (associatedData != null) {
        aadBytes = utf8.encode(associatedData);
      }

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
      throw DecryptionException(
        'Authentication failed - data may be tampered or AAD mismatch',
        code: 'AUTH_FAILED',
      );
    } catch (e) {
      throw DecryptionException(
        'Envelope decryption failed',
        code: 'ENVELOPE_DECRYPT_FAILED',
        originalError: e,
      );
    }
  }

  /// Clear all encryption keys and cached data
  Future<void> clearEncryptionKey() async {
    await _clearKeyCache();
    await _secureStorage.deleteSecret(_wrappedDekKey);
    await _secureStorage.deleteSecret(_directDekKey);
    await _secureStorage.deleteSecret(_keystoreModeKey);
    
    if (kDebugMode) {
      debugPrint('✓ Encryption keys cleared');
    }
  }

  /// Get current key storage mode for diagnostics
  Future<String> getKeyStorageMode() async {
    try {
      final mode = await _secureStorage.getSecret(_keystoreModeKey);
      if (mode == 'wrapped') {
        // Check whether the wrapped key is hardware-backed
        final isHw = await _keystoreService.isKeyHardwareBacked(_keystoreAlias);
        return isHw ? 'wrapped-hw' : 'wrapped-sw';
      }
      if (mode == 'direct') return 'direct';
      if (mode == 'hybrid') {
        final isHw = await _keystoreService.isKeyHardwareBacked(_keystoreAlias);
        return isHw ? 'hybrid-wrapped-hw' : 'hybrid-wrapped-sw';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}