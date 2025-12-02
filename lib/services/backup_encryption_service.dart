import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:crypto/crypto.dart' as hash;

/// Backup encryption service using Argon2id + XChaCha20-Poly1305
/// 
/// Security Features:
/// - Argon2id key derivation (memory-hard, GPU-resistant)
/// - XChaCha20-Poly1305 AEAD encryption
/// - HMAC-SHA256 integrity protection
/// - Zero-knowledge architecture
class BackupEncryptionService {
  // Argon2id parameters (OWASP recommended)
  static const int _argon2Memory = 65536; // 64 MB
  static const int _argon2Iterations = 3;
  static const int _argon2Parallelism = 4;
  static const int _saltLength = 32;
  static const int _keyLength = 64; // 32 for encryption, 32 for MAC
  
  // Encryption parameters
  static const String _aadContext = 'authvault-backup-v1';
  static const int _currentVersion = 1;

  /// Encrypt backup data with user password
  /// 
  /// Returns encrypted backup envelope as JSON string
  Future<String> encryptBackup(String jsonData, String password) async {
    if (password.isEmpty) {
      throw BackupException('Password cannot be empty');
    }

    try {
      // Generate random salt for Argon2id
      final salt = _generateRandomBytes(_saltLength);
      
      // Derive 64-byte key using Argon2id
      final derivedKey = await _deriveKey(password, salt);
      final encryptionKey = derivedKey.sublist(0, 32);
      final macKey = derivedKey.sublist(32, 64);
      
      // Encrypt data with XChaCha20-Poly1305
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = crypto.SecretKey(encryptionKey);
      final nonce = algorithm.newNonce();
      
      final secretBox = await algorithm.encrypt(
        utf8.encode(jsonData),
        secretKey: secretKey,
        nonce: nonce,
        aad: utf8.encode(_aadContext),
      );
      
      // Create backup envelope
      final envelope = {
        'version': _currentVersion,
        'kdf': 'argon2id',
        'kdf_params': {
          'memory': _argon2Memory,
          'iterations': _argon2Iterations,
          'parallelism': _argon2Parallelism,
          'salt': base64Encode(salt),
        },
        'cipher': 'xchacha20-poly1305',
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
      };
      
      // Calculate HMAC-SHA256 for integrity
      final envelopeJson = json.encode(envelope);
      final mac = _calculateHMAC(macKey, envelopeJson);
      envelope['mac'] = base64Encode(mac);
      
      return json.encode(envelope);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backup encryption error: $e');
      }
      throw BackupException('Failed to encrypt backup: $e');
    }
  }

  /// Validate backup file format without decrypting
  /// 
  /// Returns null if valid, error message if invalid
  String? validateBackupFile(String encryptedData) {
    try {
      final envelope = json.decode(encryptedData) as Map<String, dynamic>;
      
      // Check required fields
      if (!envelope.containsKey('version')) {
        return 'Missing version field';
      }
      if (!envelope.containsKey('kdf_params')) {
        return 'Missing encryption parameters';
      }
      if (!envelope.containsKey('ciphertext')) {
        return 'Missing encrypted data';
      }
      if (!envelope.containsKey('mac')) {
        return 'Missing integrity check';
      }
      
      // Check version
      final version = envelope['version'] as int?;
      if (version == null) {
        return 'Invalid version format';
      }
      if (version > _currentVersion) {
        return 'Backup version $version is not supported (current: $_currentVersion)';
      }
      
      return null; // Valid
    } catch (e) {
      return 'Invalid JSON format';
    }
  }

  /// Decrypt backup data with user password
  /// 
  /// Returns decrypted JSON data
  Future<String> decryptBackup(String encryptedData, String password) async {
    if (password.isEmpty) {
      throw BackupException('Password cannot be empty');
    }

    try {
      // Parse backup envelope
      Map<String, dynamic> envelope;
      try {
        envelope = json.decode(encryptedData) as Map<String, dynamic>;
      } catch (e) {
        throw BackupException('Invalid backup file format. The file may be corrupted or not a valid backup.');
      }
      
      // Validate required fields exist
      if (!envelope.containsKey('version') || 
          !envelope.containsKey('kdf_params') ||
          !envelope.containsKey('nonce') ||
          !envelope.containsKey('ciphertext') ||
          !envelope.containsKey('tag') ||
          !envelope.containsKey('mac')) {
        throw BackupException('Invalid backup file structure. The file may be corrupted or incomplete.');
      }
      
      // Verify version
      final version = envelope['version'] as int?;
      if (version == null || version > _currentVersion) {
        throw BackupException('Unsupported backup version: $version');
      }
      
      // Extract parameters with validation
      final kdfParams = envelope['kdf_params'] as Map<String, dynamic>?;
      if (kdfParams == null || !kdfParams.containsKey('salt')) {
        throw BackupException('Invalid backup file: missing encryption parameters.');
      }
      
      Uint8List salt, nonce, ciphertext, tag, storedMac;
      try {
        salt = base64Decode(kdfParams['salt'] as String);
        nonce = base64Decode(envelope['nonce'] as String);
        ciphertext = base64Decode(envelope['ciphertext'] as String);
        tag = base64Decode(envelope['tag'] as String);
        storedMac = base64Decode(envelope['mac'] as String);
      } catch (e) {
        throw BackupException('Invalid backup file: corrupted encryption data.');
      }
      
      // Derive key using same parameters
      final derivedKey = await _deriveKey(
        password,
        salt,
        memory: kdfParams['memory'] as int,
        iterations: kdfParams['iterations'] as int,
        parallelism: kdfParams['parallelism'] as int,
      );
      final encryptionKey = derivedKey.sublist(0, 32);
      final macKey = derivedKey.sublist(32, 64);
      
      // Verify HMAC (constant-time comparison)
      final envelopeCopy = Map<String, dynamic>.from(envelope);
      envelopeCopy.remove('mac');
      final envelopeJson = json.encode(envelopeCopy);
      final calculatedMac = _calculateHMAC(macKey, envelopeJson);
      
      if (!_constantTimeCompare(storedMac, calculatedMac)) {
        // HMAC mismatch could mean wrong password OR corrupted file
        // Since we validated the file structure above, it's most likely wrong password
        throw BackupException('Incorrect password. Please try a different password.');
      }
      
      // Decrypt data
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = crypto.SecretKey(encryptionKey);
      
      final secretBox = crypto.SecretBox(
        ciphertext,
        nonce: nonce,
        mac: crypto.Mac(tag),
      );
      
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: utf8.encode(_aadContext),
      );
      
      return utf8.decode(decryptedBytes);
    } on crypto.SecretBoxAuthenticationError {
      // Authentication failed - most likely wrong password since we validated file structure
      throw BackupException('Incorrect password. Please try a different password.');
    } on FormatException catch (e) {
      // UTF-8 decoding failed - could be wrong password or corrupted data
      if (kDebugMode) {
        debugPrint('UTF-8 decode error: $e');
      }
      throw BackupException('Incorrect password. Please try a different password.');
    } catch (e) {
      if (e is BackupException) rethrow;
      if (kDebugMode) {
        debugPrint('Backup decryption error: $e');
      }
      // Unexpected error
      throw BackupException('❌ Restore failed\n\nAn unexpected error occurred: ${e.toString()}');
    }
  }

  /// Derive encryption key using Argon2id
  Future<Uint8List> _deriveKey(
    String password,
    Uint8List salt, {
    int memory = _argon2Memory,
    int iterations = _argon2Iterations,
    int parallelism = _argon2Parallelism,
  }) async {
    final argon2id = crypto.Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: _keyLength,
    );
    
    final derivedKey = await argon2id.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    
    return Uint8List.fromList(await derivedKey.extractBytes());
  }

  /// Calculate HMAC-SHA256 for integrity protection
  Uint8List _calculateHMAC(Uint8List key, String data) {
    final hmac = hash.Hmac(hash.sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return Uint8List.fromList(digest.bytes);
  }

  /// Constant-time comparison to prevent timing attacks
  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = crypto.Xchacha20.poly1305Aead();
    return Uint8List.fromList(random.newNonce().take(length).toList());
  }

  /// Validate password strength
  /// 
  /// Returns null if valid, error message if invalid
  /// Now more lenient - just requires minimum length
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null; // Valid - let user choose their password
  }
  
  /// Get password warning (non-blocking)
  /// Returns warning message if password is weak, null if strong
  String? getPasswordWarning(String password) {
    if (password.length < 12) {
      return 'Recommended: Use at least 12 characters for better security';
    }
    
    // Check for character variety
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
      return 'Recommended: Mix letters, numbers, and symbols for better security';
    }
    
    // Check for common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return 'Warning: Repeated characters make passwords easier to guess';
    }
    
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def)', caseSensitive: false).hasMatch(password)) {
      return 'Warning: Sequential characters make passwords easier to guess';
    }
    
    return null; // No warning - password is good
  }

  /// Estimate password strength (0-100)
  /// More forgiving scoring system
  int estimatePasswordStrength(String password) {
    int score = 0;
    
    // Length score (max 50 points) - more generous
    if (password.length >= 6) score += 20;
    if (password.length >= 8) score += 10;
    if (password.length >= 10) score += 10;
    if (password.length >= 12) score += 10;
    
    // Character variety (max 40 points)
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 10;
    
    // Entropy bonus (max 10 points)
    final uniqueChars = password.split('').toSet().length;
    score += (uniqueChars).clamp(0, 10);
    
    // Small penalties (not too harsh)
    if (RegExp(r'(.)\1{3,}').hasMatch(password)) score -= 5;
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)', caseSensitive: false).hasMatch(password)) score -= 5;
    
    return score.clamp(0, 100);
  }
}

/// Custom exception for backup operations
class BackupException implements Exception {
  final String message;
  
  BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}
