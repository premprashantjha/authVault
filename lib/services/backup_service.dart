import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import 'account_service.dart';
import 'encryption_service.dart';

/// Service for creating and restoring encrypted backups
/// 
/// Features:
/// - Password-based encryption for cross-device recovery
/// - Zero-knowledge encrypted backups
/// - Includes accounts, favorites, and settings
/// - Duplicate detection on restore
/// - Merge strategies (skip, replace, keep both)
class BackupService {
  final AccountService _accountService;
  final EncryptionService _encryptionService;
  
  static const String _backupFileExtension = '.cdac';
  static const String _favoriteAccountsKey = 'favorite_account_ids';

  BackupService({
    required AccountService accountService,
    EncryptionService? encryptionService,
  })  : _accountService = accountService,
        _encryptionService = encryptionService ?? EncryptionService();

  /// Create encrypted backup
  /// 
  /// Returns backup file path
  Future<String> createBackup(String password) async {
    try {
      // Validate password
      final passwordError = _encryptionService.validatePassword(password);
      if (passwordError != null) {
        throw EncryptionException(passwordError);
      }

      // Gather data to backup
      final accounts = await _accountService.getAllAccounts();
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoriteAccountsKey) ?? [];
      
      // Create backup payload
      final backupData = {
        'app_version': '1.0.0',
        'backup_timestamp': DateTime.now().millisecondsSinceEpoch,
        'accounts': accounts.map((account) => account.toMap()).toList(),
        'favorites': favoriteIds,
        'settings': {
          'theme': prefs.getString('theme_mode') ?? 'system',
          // Don't backup security settings (PIN, biometric) for security
        },
      };
      
      final jsonData = json.encode(backupData);
      
      // ✅ Encrypt backup with PASSWORD (cross-device compatible)
      final encryptedData = await _encryptionService.encryptWithPassword(jsonData, password);
      
      // Encode to base64 to hide JSON structure from users
      final encodedData = base64.encode(utf8.encode(encryptedData));
      
      // Save to file
      final filePath = await _saveBackupFile(encodedData);
      
      if (kDebugMode) {
        debugPrint('✅ Password-based backup created: $filePath (${accounts.length} accounts)');
      }
      
      return filePath;
    } catch (e) {
      if (e is EncryptionException) rethrow;
      if (kDebugMode) {
        debugPrint('Backup creation error: $e');
      }
      throw EncryptionException('Failed to create backup: $e');
    }
  }

  /// Restore from encrypted backup
  /// 
  /// Returns restore result with statistics
  Future<BackupRestoreResult> restoreBackup(
    String filePath,
    String password, {
    MergeStrategy strategy = MergeStrategy.skip,
  }) async {
    try {
      // Read backup file
      final file = File(filePath);
      if (!await file.exists()) {
        throw EncryptionException('❌ File not found\n\nThe backup file could not be found.');
      }
      
      final encodedData = await file.readAsString();
      
      // Decode from base64
      String encryptedData;
      try {
        final decodedBytes = base64.decode(encodedData);
        encryptedData = utf8.decode(decodedBytes);
      } catch (e) {
        throw EncryptionException('❌ Invalid backup file\n\nThe file appears to be corrupted or not a valid backup.');
      }
      
      // Validate file format first
      final validationError = _validateBackupFile(encryptedData);
      if (validationError != null) {
        throw EncryptionException('❌ Invalid backup file\n\n$validationError\n\nThis file may be corrupted or not a valid backup.');
      }
      
      // ✅ Decrypt backup with PASSWORD
      final jsonData = await _encryptionService.decryptWithPassword(encryptedData, password);
      final backupData = json.decode(jsonData) as Map<String, dynamic>;
      
      // Validate backup structure
      _validateBackupData(backupData);
      
      // Extract data
      final accountMaps = (backupData['accounts'] as List).cast<Map<String, dynamic>>();
      final accounts = accountMaps.map((map) => Account.fromMap(map)).toList();
      final favoriteIds = (backupData['favorites'] as List).cast<String>();
      
      // Restore accounts with merge strategy
      final result = await _restoreAccounts(accounts, strategy);
      
      // Restore favorites
      await _restoreFavorites(favoriteIds, result.importedIds);
      
      // Restore settings (optional)
      await _restoreSettings(backupData['settings'] as Map<String, dynamic>);
      
      if (kDebugMode) {
        debugPrint('Backup restored: ${result.imported} imported, ${result.skipped} skipped, ${result.replaced} replaced');
      }
      
      return result;
    } on EncryptionException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Backup restore error: $e');
      }
      throw EncryptionException('Failed to restore backup: $e');
    }
  }

  /// Get backup file info without decrypting
  Future<BackupInfo> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw EncryptionException('Backup file not found');
      }
      
      final encodedData = await file.readAsString();
      
      // Decode from base64
      String encryptedData;
      try {
        final decodedBytes = base64.decode(encodedData);
        encryptedData = utf8.decode(decodedBytes);
      } catch (e) {
        // If base64 decode fails, might be an old unencoded file
        if (kDebugMode) {
          debugPrint('Base64 decode failed, trying direct parse: $e');
        }
        encryptedData = encodedData;
      }
      
      // Try to parse as encryption envelope
      Map<String, dynamic>? envelope;
      try {
        envelope = json.decode(encryptedData) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('JSON parse failed: $e');
          debugPrint('First 100 chars: ${encryptedData.substring(0, encryptedData.length > 100 ? 100 : encryptedData.length)}');
        }
        throw EncryptionException('Invalid backup file format');
      }
      
      // Check if this is an encryption envelope or raw backup data
      final isEncryptionEnvelope = envelope.containsKey('v') && envelope.containsKey('ct');
      
      if (!isEncryptionEnvelope) {
        // This is an old-format backup (raw JSON, not encrypted)
        if (kDebugMode) {
          debugPrint('Warning: Old format backup detected (not encrypted)');
        }
        throw EncryptionException('This backup file uses an old format and cannot be read. Please create a new backup.');
      }
      
      final fileSize = await file.length();
      final createdAt = await file.lastModified();
      
      return BackupInfo(
        filePath: filePath,
        fileSize: fileSize,
        createdAt: createdAt,
        version: envelope['v'] as int? ?? 1,
        kdf: envelope['kdf'] as String? ?? 'argon2id',
        cipher: envelope['alg'] as String? ?? 'XChaCha20-Poly1305',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading backup info: $e');
      }
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Failed to read backup file: $e');
    }
  }

  /// Validate backup data structure
  void _validateBackupData(Map<String, dynamic> data) {
    if (!data.containsKey('app_version')) {
      throw EncryptionException('Invalid backup: missing app_version');
    }
    if (!data.containsKey('accounts')) {
      throw EncryptionException('Invalid backup: missing accounts');
    }
    if (!data.containsKey('backup_timestamp')) {
      throw EncryptionException('Invalid backup: missing timestamp');
    }
  }

  /// Validate backup file format
  String? _validateBackupFile(String encryptedData) {
    try {
      final envelope = json.decode(encryptedData) as Map<String, dynamic>;
      if (!envelope.containsKey('v')) return 'Missing version information';
      if (!envelope.containsKey('ct')) return 'Missing encrypted content';
      return null;
    } catch (e) {
      return 'Invalid file format';
    }
  }

  /// Restore accounts with merge strategy
  Future<BackupRestoreResult> _restoreAccounts(
    List<Account> accounts,
    MergeStrategy strategy,
  ) async {
    int imported = 0;
    int skipped = 0;
    int replaced = 0;
    final importedIds = <String>[];
    
    for (final account in accounts) {
      final exists = await _accountService.accountExists(account);
      
      if (!exists) {
        // New account - always import
        await _accountService.addAccount(account);
        imported++;
        importedIds.add(account.id);
      } else {
        // Duplicate - apply strategy
        switch (strategy) {
          case MergeStrategy.skip:
            skipped++;
            break;
          case MergeStrategy.replace:
            await _accountService.updateAccount(account);
            replaced++;
            importedIds.add(account.id);
            break;
          case MergeStrategy.keepBoth:
            // Create new account with modified name
            final newAccount = Account(
              issuer: account.issuer,
              accountName: '${account.accountName} (imported)',
              secretKey: account.secretKey,
            );
            await _accountService.addAccount(newAccount);
            imported++;
            importedIds.add(newAccount.id);
            break;
        }
      }
    }
    
    return BackupRestoreResult(
      imported: imported,
      skipped: skipped,
      replaced: replaced,
      importedIds: importedIds,
    );
  }

  /// Restore favorites (only for successfully imported accounts)
  Future<void> _restoreFavorites(List<String> favoriteIds, List<String> importedIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentFavorites = prefs.getStringList(_favoriteAccountsKey) ?? [];
      
      // Only restore favorites for accounts that were imported
      final validFavorites = favoriteIds.where((id) => importedIds.contains(id)).toList();
      
      // Merge with existing favorites
      final mergedFavorites = {...currentFavorites, ...validFavorites}.toList();
      
      await prefs.setStringList(_favoriteAccountsKey, mergedFavorites);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring favorites: $e');
      }
      // Non-critical error, continue
    }
  }

  /// Restore settings (optional)
  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only restore non-security settings
      if (settings.containsKey('theme')) {
        await prefs.setString('theme_mode', settings['theme'] as String);
      }
      
      // Don't restore PIN, biometric, or other security settings
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring settings: $e');
      }
      // Non-critical error, continue
    }
  }

  /// Save backup to file
  Future<String> _saveBackupFile(String encryptedData) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    
    // Format: auth_2024-12-01_14-30.authvault
    // Short, readable, sortable by date
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'auth_${dateStr}_$timeStr$_backupFileExtension';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsString(encryptedData);
    
    return filePath;
  }

  /// Get default backup directory
  Future<String> getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// List all backup files in default directory
  Future<List<String>> listBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      
      final files = await dir
          .list()
          .where((entity) {
            if (entity is! File) return false;
            if (!entity.path.endsWith(_backupFileExtension)) return false;
            
            // Exclude local auto backup file (it's managed separately)
            final fileName = entity.path.split('/').last;
            if (fileName == 'encrypted_backup$_backupFileExtension') return false;
            
            return true;
          })
          .map((entity) => entity.path)
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aFile = File(a);
        final bFile = File(b);
        return bFile.lastModifiedSync().compareTo(aFile.lastModifiedSync());
      });
      
      return files;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error listing backup files: $e');
      }
      return [];
    }
  }

  /// Delete backup file
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting backup: $e');
      }
      throw EncryptionException('Failed to delete backup: $e');
    }
  }
}

/// Merge strategy for duplicate accounts
enum MergeStrategy {
  skip,      // Skip duplicates (keep existing)
  replace,   // Replace existing with backup
  keepBoth,  // Keep both (rename imported)
}

/// Result of backup restore operation
class BackupRestoreResult {
  final int imported;
  final int skipped;
  final int replaced;
  final List<String> importedIds;

  BackupRestoreResult({
    required this.imported,
    required this.skipped,
    required this.replaced,
    required this.importedIds,
  });

  int get total => imported + skipped + replaced;
}

/// Backup file information
class BackupInfo {
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final int version;
  final String kdf;
  final String cipher;

  BackupInfo({
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.version,
    required this.kdf,
    required this.cipher,
  });

  String get fileName => filePath.split('/').last;
  
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
