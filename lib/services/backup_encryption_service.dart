import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';
import 'keystore_service.dart';

/// Backup encryption service using hardware-backed DEK
/// 
/// IMPORTANT:
/// Hardware-backed DEKs are DEVICE-BOUND.
/// AndroidKeyStore keys are NOT backed up or migrated.
/// After app reinstall or device change, the hardware KEK is lost.
/// Automatic backups become unrecoverable.
/// 
/// Cross-device recovery requires:
/// - Password-based backup, or
/// - Password-based cloud sync
/// 
/// Architecture:
/// 1. DEK generated randomly using CSPRNG (NOT derived from account ID)
/// 2. DEK wrapped with hardware KEK and stored in SharedPreferences
/// 3. Hardware KEK stored in AndroidKeyStore (device-bound, never backed up)
/// 4. Backup encrypted with DEK using XChaCha20-Poly1305 AEAD
/// 5. For cross-device: Use password-based backup or cloud sync
/// 
/// Key Points:
/// - DEK is RANDOM (not derived) - generated once per installation
/// - Hardware KEK wraps DEK but is NOT backed up by OS
/// - After reinstall: KEK is lost, wrapped DEK becomes unrecoverable
/// - Automatic local backups are device-bound only
/// - Password-based backups and cloud sync work across devices
/// 
/// Security Features:
/// - Random DEK generation (CSPRNG using Random.secure())
/// - Hardware-backed KEK storage (when available)
/// - XChaCha20-Poly1305 AEAD encryption (no redundant HMAC)
/// - Argon2id for password-based key derivation
/// - Zero-knowledge cloud sync architecture
class BackupEncryptionService {
  final KeystoreService _keystoreService;
  
  // Keystore alias for wrapped DEK (versioned)
  static const String _dekKeystoreAlias = 'backup_dek_v1';
  static const int _dekLength = 32; // 256-bit DEK
  
  // Argon2id parameters for password-based encryption (manual backup & cloud sync)
  static const int _argon2Memory = 65536; // 64 MB
  static const int _argon2Iterations = 3;
  static const int _argon2Parallelism = 4;
  static const int _saltLength = 32;
  static const int _keyLength = 32; // 256-bit key for encryption (no separate MAC key needed)
  
  // Cloud sync parameters
  static const int _cloudKekLength = 32; // 256-bit key for wrapping Backup DEK
  
  // Encryption parameters
  static const String _aadContext = 'authvault-backup-v1';
  static const int _currentVersion = 1;

  BackupEncryptionService({KeystoreService? keystoreService})
      : _keystoreService = keystoreService ?? KeystoreService();

  /// Encrypt backup data with hardware-backed DEK (for automatic backup)
  /// 
  /// DEK is randomly generated and stored in hardware keystore with backup enabled
  /// Returns encrypted backup envelope as JSON string
  /// 
  /// Returns null if hardware DEK is unavailable (e.g., after app reinstall)
  Future<String?> encryptBackupWithHardwareDEK(String jsonData) async {
    print('=== encryptBackupWithHardwareDEK() ===');
    print('Data to encrypt: ${jsonData.length} bytes');
    
    try {
      // Get or generate random DEK (stored in hardware keystore)
      final dek = await _getOrGenerateDEK();
      
      if (dek == null) {
        print('⚠️ Hardware DEK unavailable (KEK lost after reinstall)');
        print('⚠️ Automatic local backup not available');
        print('✅ User can still use password-based backup or cloud sync');
        return null;
      }
      
      print('Using DEK for encryption (${dek.length} bytes)');
      
      // Encrypt data with XChaCha20-Poly1305 using DEK
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = crypto.SecretKey(dek);
      final nonce = algorithm.newNonce();
      
      final secretBox = await algorithm.encrypt(
        utf8.encode(jsonData),
        secretKey: secretKey,
        nonce: nonce,
        aad: utf8.encode(_aadContext),
      );
      
      // Create backup envelope
      // XChaCha20-Poly1305 is AEAD - authentication is built-in via Poly1305 tag
      // No need for additional HMAC
      final envelope = {
        'version': _currentVersion,
        'cipher': 'xchacha20-poly1305',
        'encryption_type': 'hardware_dek',
        'nonce': base64Encode(secretBox.nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
      };
      
      final finalJson = json.encode(envelope);
      print('✓ Backup encrypted successfully (${finalJson.length} bytes)');
      
      return finalJson;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backup encryption error: $e');
      }
      throw BackupException('Failed to encrypt backup: $e');
    }
  }

  /// Decrypt backup data with hardware-backed DEK (for automatic backup)
  /// 
  /// DEK is restored by OS from cloud backup and re-wrapped with new device hardware
  /// Returns decrypted JSON data
  /// 
  /// Throws BackupException if hardware DEK is unavailable
  Future<String> decryptBackupWithHardwareDEK(String encryptedData) async {
    print('=== decryptBackupWithHardwareDEK() ===');
    print('Encrypted data to decrypt: ${encryptedData.length} bytes');
    
    try {
      // Parse backup envelope
      Map<String, dynamic> envelope;
      try {
        envelope = json.decode(encryptedData) as Map<String, dynamic>;
        print('✓ Backup envelope parsed successfully');
      } catch (e) {
        print('❌ Failed to parse backup envelope: $e');
        throw BackupException('Invalid backup file format. The file may be corrupted or not a valid backup.');
      }
      
      // Validate required fields
      if (!envelope.containsKey('version') || 
          !envelope.containsKey('nonce') ||
          !envelope.containsKey('ciphertext') ||
          !envelope.containsKey('tag')) {
        throw BackupException('Invalid backup file structure. The file may be corrupted or incomplete.');
      }
      
      // Verify version
      final version = envelope['version'] as int?;
      if (version == null || version > _currentVersion) {
        throw BackupException('Unsupported backup version: $version');
      }
      
      // Get DEK from hardware keystore
      print('Getting DEK for decryption...');
      final dek = await _getOrGenerateDEK();
      
      if (dek == null) {
        print('❌ Hardware DEK unavailable (KEK lost after reinstall)');
        throw BackupException(
          'Automatic Local Backup Unavailable\n\n'
          'Your automatic backup cannot be decrypted because the encryption key was lost '
          '(this happens after app reinstall).\n\n'
          '✅ Solutions:\n'
          '• Restore from password-based backup\n'
          '• Restore from cloud sync (if enabled)\n'
          '• Reset backup and add accounts manually'
        );
      }
      
      print('Using DEK for decryption (${dek.length} bytes)');
      
      // Extract encrypted data
      Uint8List nonce, ciphertext, tag;
      try {
        nonce = base64Decode(envelope['nonce'] as String);
        ciphertext = base64Decode(envelope['ciphertext'] as String);
        tag = base64Decode(envelope['tag'] as String);
      } catch (e) {
        throw BackupException('Invalid backup file: corrupted encryption data.');
      }
      
      // XChaCha20-Poly1305 provides authentication via Poly1305 tag
      // No separate HMAC verification needed
      
      // Decrypt data
      print('Decrypting ciphertext with DEK...');
      print('XChaCha20-Poly1305 will verify authentication tag automatically');
      final algorithm = crypto.Xchacha20.poly1305Aead();
      final secretKey = crypto.SecretKey(dek);
      
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
      
      print('✓ Decryption successful (${decryptedBytes.length} bytes)');
      print('✓ Authentication tag verified by XChaCha20-Poly1305');
      final decryptedJson = utf8.decode(decryptedBytes);
      print('✓ UTF-8 decode successful');
      
      return decryptedJson;
    } on crypto.SecretBoxAuthenticationError {
      print('❌ Authentication tag verification FAILED');
      print('This means either:');
      print('  1. Wrong DEK (different from encryption DEK)');
      print('  2. Backup file was tampered with');
      print('  3. Backup file is corrupted');
      throw BackupException('Backup integrity check failed. Wrong account or corrupted file.');
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('UTF-8 decode error: $e');
      }
      throw BackupException('Failed to decrypt backup. Wrong account or corrupted file.');
    } catch (e) {
      if (e is BackupException) rethrow;
      if (kDebugMode) {
        debugPrint('Backup decryption error: $e');
      }
      throw BackupException('Failed to decrypt backup: ${e.toString()}');
    }
  }

  /// Get or generate random DEK
  /// 
  /// DEK is randomly generated (CSPRNG) and stored in hardware keystore
  /// 
  /// ⚠️ REALITY CHECK (Android Security Model):
  /// - AndroidKeyStore KEK is NEVER backed up (by design)
  /// - After app reinstall, KEK is LOST
  /// - Wrapped DEK becomes unrecoverable
  /// - This is NOT a bug - it's Android's security model
  /// 
  /// ✅ CORRECT BEHAVIOR:
  /// - Generate DEK once per installation
  /// - Never regenerate automatically
  /// - Never delete unless user explicitly resets
  /// - Return null if KEK is lost (non-fatal)
  /// - User can still use password-based backups or cloud sync
  Future<Uint8List?> _getOrGenerateDEK() async {
    print('=== _getOrGenerateDEK() ===');
    
    try {
      // Try to get existing DEK from keystore
      print('Attempting to retrieve existing DEK from keystore...');
      final existingDEK = await _keystoreService.getKey(_dekKeystoreAlias);
      
      if (existingDEK != null) {
        print('✓ Existing DEK retrieved successfully (${existingDEK.length} bytes)');
        print('DEK hash: ${existingDEK.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
        return existingDEK;
      } else {
        print('⚠️ No existing DEK found or unwrap failed');
        
        // Check if wrapped DEK exists but couldn't be unwrapped
        final prefs = await SharedPreferences.getInstance();
        final wrappedExists = prefs.getString('wrapped_$_dekKeystoreAlias');
        
        if (wrappedExists != null) {
          // ❌ Wrapped DEK exists but KEK is missing
          // This is EXPECTED after app reinstall - KEK is NEVER backed up
          // This is Android's security model, not a bug
          
          print('❌ Wrapped DEK exists but cannot be unwrapped');
          print('❌ KEK is missing from AndroidKeyStore (expected after reinstall)');
          print('❌ Automatic local backups are UNRECOVERABLE');
          print('✅ Password-based backups and cloud sync still work');
          
          // Return null instead of throwing - this is non-fatal
          // User can still use password-based backups or cloud sync
          return null;
        }
      }
    } catch (e) {
      print('Error retrieving existing DEK: $e');
      // Non-fatal - return null
      return null;
    }
    
    // No wrapped DEK exists - this is a fresh installation
    // Generate new random DEK
    print('No wrapped DEK found - generating NEW random DEK...');
    final newDEK = await _generateAndStoreDEK();
    print('✓ New DEK generated (${newDEK.length} bytes)');
    print('New DEK hash: ${newDEK.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
    return newDEK;
  }

  /// Generate random DEK and store in hardware keystore with backup enabled
  Future<Uint8List> _generateAndStoreDEK() async {
    // Generate random 256-bit DEK using CSPRNG
    final dek = _generateRandomBytes(_dekLength);
    
    // Ensure keystore key exists (with backup enabled)
    await _keystoreService.generateKey(_dekKeystoreAlias);
    
    // Store DEK in hardware keystore (OS will back up wrapped blob)
    await _keystoreService.storeKey(_dekKeystoreAlias, dek);
    
    if (kDebugMode) {
      final isHardwareBacked = await _keystoreService.isKeyHardwareBacked(_dekKeystoreAlias);
      debugPrint('Random DEK generated and stored in hardware keystore (hardware-backed: $isHardwareBacked)');
    }
    
    return dek;
  }

  /// Delete DEK (for backup disable/reset)
  /// ⚠️ WARNING: This will make all existing backups unrecoverable
  /// Only call when user explicitly chooses to reset backup
  Future<void> deleteDEK() async {
    print('⚠️ WARNING: User requested backup reset');
    print('⚠️ Deleting wrapped DEK - all existing backups will be LOST');
    
    try {
      await _keystoreService.deleteKey(_dekKeystoreAlias);
      
      if (kDebugMode) {
        debugPrint('✓ DEK deleted from hardware keystore');
        debugPrint('✓ User can now create new backups with a fresh DEK');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete DEK: $e');
      }
      throw BackupException('Failed to reset backup: $e');
    }
  }

  /// Check if DEK exists
  Future<bool> hasDEK() async {
    try {
      final dek = await _keystoreService.getKey(_dekKeystoreAlias);
      return dek != null;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // CLOUD SYNC - Password-Based DEK Wrapping
  // ============================================================================
  
  /// Enable cloud sync by wrapping the Backup DEK with a password-derived key
  /// 
  /// This allows the Backup DEK to be recovered on new devices using only the password.
  /// The wrapped DEK can be uploaded to a server for cross-device sync.
  /// 
  /// Architecture:
  /// 1. Get existing Backup DEK (must exist - user must have accounts)
  /// 2. Derive Cloud KEK from password using Argon2id
  /// 3. Wrap Backup DEK with Cloud KEK using XChaCha20-Poly1305
  /// 4. Return wrapped DEK + KDF params for upload to server
  /// 
  /// CRITICAL: Cloud sync wraps the EXISTING Backup DEK
  /// If hardware DEK is unavailable (after reinstall), user must:
  /// - First restore from existing cloud sync, OR
  /// - First restore from password backup, OR
  /// - Add accounts manually (which generates new DEK)
  /// Then enable cloud sync with the recovered/new DEK
  /// 
  /// This ensures cloud sync and local backups use the SAME DEK
  /// 
  /// Security:
  /// - Password never stored or transmitted
  /// - Server never sees plaintext DEK
  /// - Argon2id makes brute-force attacks expensive
  /// - XChaCha20-Poly1305 provides authenticated encryption
  /// 
  /// Returns: CloudSyncEnvelope (ready for upload to server)
  /// Throws: BackupException if no DEK exists (user must restore or add accounts first)
  Future<CloudSyncEnvelope> enableCloudSync(String password) async {
    if (password.isEmpty) {
      throw BackupException('Cloud sync password cannot be empty');
    }
    
    print('=== enableCloudSync() ===');
    
    // Get existing Backup DEK - must exist
    // Cloud sync wraps the EXISTING DEK to ensure consistency
    final backupDEK = await _getOrGenerateDEK();
    
    if (backupDEK == null) {
      print('❌ No Backup DEK available');
      print('❌ User must restore accounts or add accounts first');
      throw BackupException(
        'Cannot Enable Cloud Sync\n\n'
        'No backup encryption key is available. This happens after app reinstall.\n\n'
        '✅ To enable cloud sync:\n'
        '1. Restore from existing cloud sync (if you have one), OR\n'
        '2. Restore from password backup, OR\n'
        '3. Add accounts manually\n\n'
        'Then you can enable cloud sync to protect your accounts.'
      );
    }
    
    print('✓ Using existing Backup DEK (${backupDEK.length} bytes)');
    
    // Generate random salt for Argon2id
    final salt = _generateRandomBytes(_saltLength);
    print('Generated salt (${salt.length} bytes)');
    
    // Derive Cloud KEK from password
    print('Deriving Cloud KEK with Argon2id...');
    final cloudKEK = await _deriveKey(password, salt);
    print('Cloud KEK derived (${cloudKEK.length} bytes)');
    
    // Wrap Backup DEK with Cloud KEK using XChaCha20-Poly1305
    print('Wrapping Backup DEK with Cloud KEK...');
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(cloudKEK);
    final nonce = algorithm.newNonce();
    
    final secretBox = await algorithm.encrypt(
      backupDEK,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    print('✓ Backup DEK wrapped successfully');
    
    // Create cloud sync envelope
    final envelope = CloudSyncEnvelope(
      version: _currentVersion,
      kdfParams: KdfParams(
        kdf: 'argon2id',
        memory: _argon2Memory,
        iterations: _argon2Iterations,
        parallelism: _argon2Parallelism,
        salt: salt,
      ),
      wrappedDEK: WrappedDEK(
        cipher: 'xchacha20-poly1305',
        nonce: secretBox.nonce,
        ciphertext: secretBox.cipherText,
        tag: secretBox.mac.bytes,
      ),
    );
    
    print('✓ Cloud sync envelope created');
    return envelope;
  }
  
  /// Unwrap Backup DEK using cloud sync password
  /// 
  /// This is used when restoring on a new device:
  /// 1. Download wrapped DEK from server
  /// 2. User enters cloud sync password
  /// 3. Derive Cloud KEK from password
  /// 4. Unwrap Backup DEK
  /// 5. Store unwrapped DEK in local keystore
  /// 6. Use DEK to decrypt backups
  /// 
  /// Returns: Unwrapped Backup DEK (ready to be stored in keystore)
  Future<Uint8List> unwrapCloudSyncDEK(
    CloudSyncEnvelope envelope,
    String password,
  ) async {
    if (password.isEmpty) {
      throw BackupException('Cloud sync password cannot be empty');
    }
    
    print('=== unwrapCloudSyncDEK() ===');
    
    // Verify version
    if (envelope.version > _currentVersion) {
      throw BackupException('Unsupported cloud sync version: ${envelope.version}');
    }
    
    // Derive Cloud KEK from password using same parameters
    print('Deriving Cloud KEK with Argon2id...');
    final cloudKEK = await _deriveKey(
      password,
      envelope.kdfParams.salt,
      memory: envelope.kdfParams.memory,
      iterations: envelope.kdfParams.iterations,
      parallelism: envelope.kdfParams.parallelism,
    );
    print('Cloud KEK derived (${cloudKEK.length} bytes)');
    
    // Unwrap Backup DEK using Cloud KEK
    print('Unwrapping Backup DEK...');
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(cloudKEK);
    
    final secretBox = crypto.SecretBox(
      envelope.wrappedDEK.ciphertext,
      nonce: envelope.wrappedDEK.nonce,
      mac: crypto.Mac(envelope.wrappedDEK.tag),
    );
    
    try {
      final unwrappedDEK = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      print('✓ Backup DEK unwrapped successfully (${unwrappedDEK.length} bytes)');
      return Uint8List.fromList(unwrappedDEK);
    } on crypto.SecretBoxAuthenticationError {
      print('❌ Authentication failed - wrong password or corrupted data');
      throw BackupException('Incorrect cloud sync password. Please try again.');
    }
  }
  
  /// Store unwrapped DEK in local keystore (after cloud sync restore)
  /// 
  /// This is called after successfully unwrapping the DEK from cloud sync.
  /// It stores the DEK in the local AndroidKeyStore so it can be used
  /// for automatic backups going forward.
  Future<void> storeUnwrappedDEK(Uint8List dek) async {
    print('=== storeUnwrappedDEK() ===');
    print('Storing unwrapped DEK in local keystore...');
    
    // Ensure keystore key exists
    await _keystoreService.generateKey(_dekKeystoreAlias);
    
    // Store DEK in hardware keystore
    await _keystoreService.storeKey(_dekKeystoreAlias, dek);
    
    print('✓ DEK stored in local keystore');
    print('✓ Automatic backups will now work on this device');
  }

  /// Encrypt backup data with user password (for manual export)
  /// 
  /// Returns encrypted backup envelope as JSON string
  Future<String> encryptBackup(String jsonData, String password) async {
    if (password.isEmpty) {
      throw BackupException('Password cannot be empty');
    }

    try {
      // Generate random salt for Argon2id
      final salt = _generateRandomBytes(_saltLength);
      
      // Derive 32-byte key using Argon2id
      final encryptionKey = await _deriveKey(password, salt);
      
      // Encrypt data with XChaCha20-Poly1305 AEAD
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
      // XChaCha20-Poly1305 is AEAD - authentication is built-in via Poly1305 tag
      // No need for additional HMAC
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
      if (!envelope.containsKey('ciphertext')) {
        return 'Missing encrypted data';
      }
      
      // Check version
      final version = envelope['version'] as int?;
      if (version == null) {
        return 'Invalid version format';
      }
      if (version > _currentVersion) {
        return 'Backup version $version is not supported (current: $_currentVersion)';
      }
      
      // Check encryption type
      final encryptionType = envelope['encryption_type'] as String?;
      if (encryptionType == 'hardware_dek') {
        // Hardware DEK backup - XChaCha20-Poly1305 AEAD (no separate HMAC)
        if (!envelope.containsKey('tag')) {
          return 'Missing authentication tag';
        }
      } else {
        // Password-based backup - XChaCha20-Poly1305 AEAD (no separate HMAC)
        if (!envelope.containsKey('kdf_params')) {
          return 'Missing encryption parameters';
        }
        if (!envelope.containsKey('tag')) {
          return 'Missing authentication tag';
        }
      }
      
      return null; // Valid
    } catch (e) {
      return 'Invalid JSON format';
    }
  }

  /// Decrypt backup data with user password (for manual export)
  /// 
  /// Returns decrypted JSON data
  Future<String> decryptBackup(String encryptedData, String password) async {
    if (password.isEmpty) {
      throw BackupException('Password cannot be empty');
    }

    return await _decryptBackupInternal(encryptedData, password);
  }

  /// Internal decrypt method
  Future<String> _decryptBackupInternal(String encryptedData, String key) async {

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
          !envelope.containsKey('tag')) {
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
      
      Uint8List salt, nonce, ciphertext, tag;
      try {
        salt = base64Decode(kdfParams['salt'] as String);
        nonce = base64Decode(envelope['nonce'] as String);
        ciphertext = base64Decode(envelope['ciphertext'] as String);
        tag = base64Decode(envelope['tag'] as String);
      } catch (e) {
        throw BackupException('Invalid backup file: corrupted encryption data.');
      }
      
      // Derive 32-byte key using same parameters
      final encryptionKey = await _deriveKey(
        key,
        salt,
        memory: kdfParams['memory'] as int,
        iterations: kdfParams['iterations'] as int,
        parallelism: kdfParams['parallelism'] as int,
      );
      
      // Decrypt data with XChaCha20-Poly1305 AEAD
      // Authentication is built-in via Poly1305 tag - no separate HMAC needed
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
      // Authentication failed - wrong password or corrupted file
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

  /// Generate cryptographically secure random bytes using OS-level CSPRNG
  /// 
  /// CRITICAL: Uses Random.secure() which provides OS-level entropy
  /// This is the ONLY safe way to generate key material in Dart
  /// 
  /// Made public for cloud sync service
  Uint8List generateRandomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
  
  /// Wrap DEK with password (for cloud backup)
  /// 
  /// This creates a password-protected wrapper around the Backup DEK
  /// The wrapped DEK can be stored and later unwrapped with the same password
  /// 
  /// CRITICAL: This does NOT use Hardware KEK - only password!
  /// This ensures the backup is recoverable after reinstall
  Future<CloudSyncEnvelope> wrapDEKWithPassword(
    Uint8List dek,
    String password,
  ) async {
    print('🔐 [Encryption] Wrapping DEK with password...');
    
    // Generate random salt for Argon2id
    final salt = generateRandomBytes(_saltLength);
    print('✓ [Encryption] Generated salt (${salt.length} bytes)');
    
    // Derive Backup KEK from password
    print('🔐 [Encryption] Deriving Backup KEK with Argon2id...');
    final backupKEK = await _deriveKey(password, salt);
    print('✓ [Encryption] Backup KEK derived (${backupKEK.length} bytes)');
    
    // Wrap DEK with Backup KEK using XChaCha20-Poly1305
    print('🔐 [Encryption] Encrypting DEK with Backup KEK...');
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(backupKEK);
    final nonce = algorithm.newNonce();
    
    final secretBox = await algorithm.encrypt(
      dek,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    print('✓ [Encryption] DEK wrapped successfully');
    
    // Return envelope
    return CloudSyncEnvelope(
      version: _currentVersion,
      kdfParams: KdfParams(
        kdf: 'argon2id',
        memory: _argon2Memory,
        iterations: _argon2Iterations,
        parallelism: _argon2Parallelism,
        salt: salt,
      ),
      wrappedDEK: WrappedDEK(
        cipher: 'xchacha20-poly1305',
        nonce: secretBox.nonce,
        ciphertext: secretBox.cipherText,
        tag: secretBox.mac.bytes,
      ),
    );
  }
  
  /// Unwrap DEK with password (for cloud restore)
  /// 
  /// This recovers the Backup DEK from the password-protected wrapper
  /// 
  /// CRITICAL: This does NOT use Hardware KEK - only password!
  /// This is why cloud backup works after reinstall
  Future<Uint8List> unwrapDEKWithPassword(
    CloudSyncEnvelope envelope,
    String password,
  ) async {
    print('🔐 [Encryption] Unwrapping DEK with password...');
    
    // Derive Backup KEK from password using same parameters
    print('🔐 [Encryption] Deriving Backup KEK with Argon2id...');
    final backupKEK = await _deriveKey(
      password,
      envelope.kdfParams.salt,
      memory: envelope.kdfParams.memory,
      iterations: envelope.kdfParams.iterations,
      parallelism: envelope.kdfParams.parallelism,
    );
    print('✓ [Encryption] Backup KEK derived (${backupKEK.length} bytes)');
    
    // Unwrap DEK
    print('🔓 [Encryption] Decrypting DEK with Backup KEK...');
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(backupKEK);
    
    final secretBox = crypto.SecretBox(
      envelope.wrappedDEK.ciphertext,
      nonce: envelope.wrappedDEK.nonce,
      mac: crypto.Mac(envelope.wrappedDEK.tag),
    );
    
    try {
      final unwrappedDEK = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      print('✓ [Encryption] DEK unwrapped successfully (${unwrappedDEK.length} bytes)');
      return Uint8List.fromList(unwrappedDEK);
    } on crypto.SecretBoxAuthenticationError {
      print('❌ [Encryption] Authentication failed - wrong password');
      throw BackupException('Incorrect password');
    }
  }
  
  /// Encrypt data with DEK (for cloud backup)
  /// 
  /// This encrypts the backup data using the Backup DEK directly
  /// NO Hardware KEK involved!
  Future<String> encryptWithDEK(String jsonData, Uint8List dek) async {
    print('🔐 [Encryption] Encrypting data with DEK...');
    
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(dek);
    final nonce = algorithm.newNonce();
    
    final secretBox = await algorithm.encrypt(
      utf8.encode(jsonData),
      secretKey: secretKey,
      nonce: nonce,
      aad: utf8.encode(_aadContext),
    );
    
    final envelope = {
      'version': _currentVersion,
      'cipher': 'xchacha20-poly1305',
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'tag': base64Encode(secretBox.mac.bytes),
    };
    
    print('✓ [Encryption] Data encrypted successfully');
    return json.encode(envelope);
  }
  
  /// Decrypt data with DEK (for cloud restore)
  /// 
  /// This decrypts the backup data using the Backup DEK directly
  /// NO Hardware KEK involved!
  Future<String> decryptWithDEK(String encryptedData, Uint8List dek) async {
    print('🔓 [Encryption] Decrypting data with DEK...');
    
    final envelope = json.decode(encryptedData) as Map<String, dynamic>;
    
    final nonce = base64Decode(envelope['nonce'] as String);
    final ciphertext = base64Decode(envelope['ciphertext'] as String);
    final tag = base64Decode(envelope['tag'] as String);
    
    final algorithm = crypto.Xchacha20.poly1305Aead();
    final secretKey = crypto.SecretKey(dek);
    
    final secretBox = crypto.SecretBox(
      ciphertext,
      nonce: nonce,
      mac: crypto.Mac(tag),
    );
    
    try {
      final decryptedBytes = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: utf8.encode(_aadContext),
      );
      
      print('✓ [Encryption] Data decrypted successfully');
      return utf8.decode(decryptedBytes);
    } on crypto.SecretBoxAuthenticationError {
      print('❌ [Encryption] Authentication failed');
      throw BackupException('Backup integrity check failed');
    }
  }

  /// Generate cryptographically secure random bytes using OS-level CSPRNG
  /// 
  /// CRITICAL: Uses Random.secure() which provides OS-level entropy
  /// This is the ONLY safe way to generate key material in Dart
  Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
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

// ============================================================================
// Cloud Sync Data Models
// ============================================================================

/// KDF parameters for password-based key derivation
class KdfParams {
  final String kdf;
  final int memory;
  final int iterations;
  final int parallelism;
  final Uint8List salt;
  
  KdfParams({
    required this.kdf,
    required this.memory,
    required this.iterations,
    required this.parallelism,
    required this.salt,
  });
  
  Map<String, dynamic> toJson() => {
    'kdf': kdf,
    'memory': memory,
    'iterations': iterations,
    'parallelism': parallelism,
    'salt': base64Encode(salt),
  };
  
  factory KdfParams.fromJson(Map<String, dynamic> json) => KdfParams(
    kdf: json['kdf'] as String,
    memory: json['memory'] as int,
    iterations: json['iterations'] as int,
    parallelism: json['parallelism'] as int,
    salt: base64Decode(json['salt'] as String),
  );
}

/// Wrapped DEK (encrypted with Cloud KEK)
class WrappedDEK {
  final String cipher;
  final List<int> nonce;
  final List<int> ciphertext;
  final List<int> tag;
  
  WrappedDEK({
    required this.cipher,
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });
  
  Map<String, dynamic> toJson() => {
    'cipher': cipher,
    'nonce': base64Encode(nonce),
    'ciphertext': base64Encode(ciphertext),
    'tag': base64Encode(tag),
  };
  
  factory WrappedDEK.fromJson(Map<String, dynamic> json) => WrappedDEK(
    cipher: json['cipher'] as String,
    nonce: base64Decode(json['nonce'] as String),
    ciphertext: base64Decode(json['ciphertext'] as String),
    tag: base64Decode(json['tag'] as String),
  );
}

/// Cloud sync envelope (uploaded to server)
/// 
/// This contains everything needed to unwrap the Backup DEK on a new device:
/// - KDF parameters (for deriving Cloud KEK from password)
/// - Wrapped DEK (Backup DEK encrypted with Cloud KEK)
/// 
/// Server stores this blob but cannot decrypt it without the password.
class CloudSyncEnvelope {
  final int version;
  final KdfParams kdfParams;
  final WrappedDEK wrappedDEK;
  
  CloudSyncEnvelope({
    required this.version,
    required this.kdfParams,
    required this.wrappedDEK,
  });
  
  Map<String, dynamic> toJson() => {
    'version': version,
    'kdf_params': kdfParams.toJson(),
    'wrapped_dek': wrappedDEK.toJson(),
  };
  
  factory CloudSyncEnvelope.fromJson(Map<String, dynamic> json) => CloudSyncEnvelope(
    version: json['version'] as int,
    kdfParams: KdfParams.fromJson(json['kdf_params'] as Map<String, dynamic>),
    wrappedDEK: WrappedDEK.fromJson(json['wrapped_dek'] as Map<String, dynamic>),
  );
  
  /// Serialize to JSON string (for upload to server)
  String toJsonString() => json.encode(toJson());
  
  /// Deserialize from JSON string (after download from server)
  factory CloudSyncEnvelope.fromJsonString(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return CloudSyncEnvelope.fromJson(map);
  }
}
