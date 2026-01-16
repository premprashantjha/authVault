import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import 'account_service.dart';
import 'encryption_service.dart';
import 'backup_preferences_service.dart';

/// Service for automatic local encrypted backup
/// 
/// Features:
/// - Password-based encryption
/// - Automatic backup on account changes
/// - Stored locally on device
/// - Zero-knowledge architecture
class LocalBackupService {
  final AccountService _accountService;
  final EncryptionService _encryptionService;
  final BackupPreferencesService _preferencesService;
  
  static const String _backupFileName = 'encrypted_backup.cdac';
  static const String _favoriteAccountsKey = 'favorite_account_ids';
  static const String _backupPasswordKey = 'local_backup_password_secure';

  LocalBackupService({
    required AccountService accountService,
    EncryptionService? encryptionService,
    BackupPreferencesService? preferencesService,
  })  : _accountService = accountService,
        _encryptionService = encryptionService ?? EncryptionService(),
        _preferencesService = preferencesService ?? BackupPreferencesService();

  /// Create automatic backup (called on account changes)
  Future<void> createAutoBackup() async {
    try {
      final isEnabled = await _preferencesService.isBackupEnabled();
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('Auto backup skipped: not enabled');
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final password = prefs.getString(_backupPasswordKey);
      if (password == null) {
        if (kDebugMode) {
          debugPrint('Auto backup skipped: no password stored');
        }
        return;
      }

      final accountId = await _preferencesService.getBackupAccountId();
      if (accountId == null) {
        if (kDebugMode) {
          debugPrint('Auto backup skipped: no account ID stored');
        }
        return;
      }
      
      final accounts = await _accountService.getAllAccounts();
      
      if (kDebugMode) {
        debugPrint('=== Creating Local Backup ===');
        debugPrint('Number of accounts to backup: ${accounts.length}');
      }
      
      if (accounts.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Skipping backup creation: No accounts to backup');
        }
        return;
      }
      
      final favoriteIds = prefs.getStringList(_favoriteAccountsKey) ?? [];
      
      final backupData = {
        'app_version': '1.0.0',
        'backup_timestamp': DateTime.now().millisecondsSinceEpoch,
        'backup_account_id': accountId,
        'accounts': accounts.map((account) => account.toMap()).toList(),
        'favorites': favoriteIds,
        'settings': {
          'theme': prefs.getString('theme_mode') ?? 'system',
        },
      };
      
      final jsonData = json.encode(backupData);
      final encryptedData = await _encryptionService.encryptWithPassword(jsonData, password);
      
      await _saveToBackupLocation(encryptedData);
      await _preferencesService.updateLastBackupTime(DateTime.now());
      
      if (kDebugMode) {
        debugPrint('✅ Local backup created: ${accounts.length} accounts');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Local backup failed: $e');
      }
    }
  }

  /// Create backup with password (for initial setup)
  Future<void> createAutoBackupWithPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupPasswordKey, password);
      await createAutoBackup();
      
      if (kDebugMode) {
        debugPrint('Local backup with password created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Local backup with password failed: $e');
      }
      rethrow;
    }
  }

  /// Restore from local backup
  Future<bool> restoreAutoBackup(String password) async {
    try {
      final backupFile = await _getBackupFile();
      if (!await backupFile.exists()) {
        if (kDebugMode) {
          debugPrint('No backup file found');
        }
        return false;
      }
      
      final encryptedData = await backupFile.readAsString();
      
      String jsonData;
      try {
        jsonData = await _encryptionService.decryptWithPassword(encryptedData, password);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Backup decryption failed: $e');
        }
        rethrow;
      }
      
      final backupData = json.decode(jsonData) as Map<String, dynamic>;
      
      if (backupData.containsKey('backup_account_id')) {
        final backupAccountId = backupData['backup_account_id'] as String?;
        if (kDebugMode) {
          debugPrint('Backup was created with account: $backupAccountId');
        }
      }
      
      final accountMaps = (backupData['accounts'] as List).cast<Map<String, dynamic>>();
      final accounts = accountMaps.map((map) => Account.fromMap(map)).toList();
      final favoriteIds = (backupData['favorites'] as List).cast<String>();
      
      for (final account in accounts) {
        final exists = await _accountService.accountExists(account);
        if (!exists) {
          await _accountService.addAccount(account);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoriteAccountsKey, favoriteIds);
      
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        if (settings.containsKey('theme')) {
          await prefs.setString('theme_mode', settings['theme'] as String);
        }
      }
      
      await prefs.setString(_backupPasswordKey, password);
      
      if (kDebugMode) {
        debugPrint('✅ Local backup restored: ${accounts.length} accounts');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Local backup restore failed: $e');
      }
      rethrow;
    }
  }

  /// Check if backup exists
  Future<bool> hasBackup() async {
    try {
      final backupFile = await _getBackupFile();
      return await backupFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get backup metadata without full restore
  /// 
  /// Note: Cannot decrypt without password, so returns basic file info only
  Future<Map<String, dynamic>?> getBackupMetadata() async {
    if (kDebugMode) {
      debugPrint('=== GET BACKUP METADATA ===');
    }
    
    try {
      final backupFile = await _getBackupFile();
      if (kDebugMode) {
        debugPrint('Backup file path: ${backupFile.path}');
      }
      
      if (!await backupFile.exists()) {
        if (kDebugMode) {
          debugPrint('❌ Backup file does NOT exist');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('✓ Backup file exists');
      }
      
      final stat = await backupFile.stat();
      final lastModified = stat.modified;
      
      if (kDebugMode) {
        debugPrint('File size: ${stat.size} bytes');
        debugPrint('Last modified: $lastModified');
      }
      
      // Return basic metadata without decryption
      // Account count will be shown after successful restore
      return {
        'file_exists': true,
        'file_size': stat.size,
        'last_modified': lastModified,
        'account_count': null, // Cannot know without password
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get backup metadata: $e');
      }
      return null;
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    return await _preferencesService.getLastBackupTime();
  }

  Future<bool> isBackupEnabled() async {
    return await _preferencesService.isBackupEnabled();
  }

  /// Enable automatic local backup
  Future<void> enableBackup(String accountId, String password) async {
    await _preferencesService.enableBackup(accountId);
    
    final accounts = await _accountService.getAllAccounts();
    
    if (kDebugMode) {
      debugPrint('Local backup enabled for account: $accountId');
      debugPrint('Found ${accounts.length} existing accounts');
    }
    
    if (accounts.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('Creating initial backup with ${accounts.length} accounts');
      }
      await createAutoBackupWithPassword(password);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupPasswordKey, password);
      
      if (kDebugMode) {
        debugPrint('No accounts yet, password stored for future backups');
      }
    }
  }

  Future<void> disableBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupPasswordKey);
    await _preferencesService.disableBackup();
  }

  Future<String?> getBackupAccountId() async {
    return await _preferencesService.getBackupAccountId();
  }

  Future<void> deleteBackup() async {
    try {
      final backupFile = await _getBackupFile();
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      await _preferencesService.clearPreferences();
      
      if (kDebugMode) {
        debugPrint('Local backup deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete backup: $e');
      }
    }
  }

  Future<void> _saveToBackupLocation(String encryptedData) async {
    final backupFile = await _getBackupFile();
    await backupFile.writeAsString(encryptedData);
  }

  /// Get backup file location (stored locally on device)
  Future<File> _getBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_backupFileName');
  }
}
