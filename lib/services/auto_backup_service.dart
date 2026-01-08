import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import 'account_service.dart';
import 'backup_encryption_service.dart';
import 'platform_account_service.dart';
import 'backup_preferences_service.dart';

/// Service for automatic backup using platform-native backup systems
/// 
/// Android: Auto Backup to Google Drive
/// iOS: iCloud Backup
/// 
/// Features:
/// - Automatic backup on account changes
/// - Account-bound encryption (Google/Apple account)
/// - Zero-knowledge architecture
/// - Seamless restore on new device
class AutoBackupService {
  final AccountService _accountService;
  final BackupEncryptionService _encryptionService;
  final PlatformAccountService _platformAccountService;
  final BackupPreferencesService _preferencesService;
  
  static const String _backupFileName = 'encrypted_backup.cdac';
  static const String _favoriteAccountsKey = 'favorite_account_ids';

  AutoBackupService({
    required AccountService accountService,
    BackupEncryptionService? encryptionService,
    PlatformAccountService? platformAccountService,
    BackupPreferencesService? preferencesService,
  })  : _accountService = accountService,
        _encryptionService = encryptionService ?? BackupEncryptionService(),
        _platformAccountService = platformAccountService ?? PlatformAccountService(),
        _preferencesService = preferencesService ?? BackupPreferencesService();

  /// Create automatic backup
  /// 
  /// Called automatically when accounts change (only if backup is enabled)
  /// Encrypts with hardware-backed DEK and saves to platform backup location
  /// Cloud account only controls ACCESS, not encryption
  Future<void> createAutoBackup() async {
    try {
      // Check if backup is enabled
      final isEnabled = await _preferencesService.isBackupEnabled();
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('Auto backup skipped: not enabled');
        }
        return;
      }

      // Get stored account ID (no need to show picker again!)
      final accountId = await _preferencesService.getBackupAccountId();
      if (accountId == null) {
        if (kDebugMode) {
          debugPrint('Auto backup skipped: no account ID stored');
        }
        return;
      }
      
      // Gather data to backup
      final accounts = await _accountService.getAllAccounts();
      
      print('=== Creating Auto Backup ===');
      print('BACKUP → AccountService: ${_accountService.hashCode}');
      print('BACKUP → DatabaseService: ${_accountService.databaseService.hashCode}');
      print('Backup enabled: $isEnabled');
      print('Account ID: $accountId');
      print('Number of accounts to backup: ${accounts.length}');
      
      // ✓ Safety check: Don't create empty backups
      if (accounts.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Skipping backup creation: No accounts to backup');
          debugPrint('Backup will be created when first account is added');
        }
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoriteAccountsKey) ?? [];
      
      // Create backup payload (no DEK salt - DEK is random, not derived)
      final backupData = {
        'app_version': '1.0.0',
        'backup_timestamp': DateTime.now().millisecondsSinceEpoch,
        'backup_account_id': accountId, // For access control verification only
        'accounts': accounts.map((account) => account.toMap()).toList(),
        'favorites': favoriteIds,
        'settings': {
          'theme': prefs.getString('theme_mode') ?? 'system',
        },
      };
      
      final jsonData = json.encode(backupData);
      
      // Encrypt with hardware-backed DEK (random, stored in keystore)
      final encryptedData = await _encryptionService.encryptBackupWithHardwareDEK(jsonData);
      
      // Check if encryption succeeded
      if (encryptedData == null) {
        throw BackupException('Hardware DEK unavailable. Cannot create automatic backup.');
      }
      
      // Save to platform backup location
      await _saveToBackupLocation(encryptedData);
      
      // Update last backup timestamp
      await _preferencesService.updateLastBackupTime(DateTime.now());
      
      if (kDebugMode) {
        debugPrint('Auto backup created: ${accounts.length} accounts');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auto backup failed: $e');
      }
      // Don't throw - backup failure shouldn't break app
    }
  }

  /// Restore from automatic backup
  /// 
  /// Called on app launch if backup file exists
  /// Works even if backup is not enabled (for fresh installs)
  Future<bool> restoreAutoBackup() async {
    try {
      // Check if backup file exists
      final backupFile = await _getBackupFile();
      if (!await backupFile.exists()) {
        if (kDebugMode) {
          debugPrint('No backup file found');
        }
        return false;
      }
      
      // Read encrypted backup
      final encryptedData = await backupFile.readAsString();
      
      // Try to decrypt with hardware-backed DEK (restored by OS from cloud)
      String jsonData;
      try {
        jsonData = await _encryptionService.decryptBackupWithHardwareDEK(encryptedData);
      } catch (e) {
        // Decryption failed - backup is incompatible (wrong DEK)
        if (kDebugMode) {
          debugPrint('Backup decryption failed (incompatible DEK): $e');
          debugPrint('Deleting incompatible backup file...');
        }
        
        // Delete the incompatible backup file
        try {
          await backupFile.delete();
          if (kDebugMode) {
            debugPrint('Incompatible backup file deleted successfully');
          }
        } catch (deleteError) {
          if (kDebugMode) {
            debugPrint('Failed to delete incompatible backup: $deleteError');
          }
        }
        
        return false;
      }
      
      final backupData = json.decode(jsonData) as Map<String, dynamic>;
      
      // Verify account ID for access control (optional - backup already encrypted)
      if (backupData.containsKey('backup_account_id')) {
        final backupAccountId = backupData['backup_account_id'] as String?;
        if (kDebugMode) {
          debugPrint('Backup was created with account: $backupAccountId');
        }
      }
      
      // Extract data
      final accountMaps = (backupData['accounts'] as List).cast<Map<String, dynamic>>();
      final accounts = accountMaps.map((map) => Account.fromMap(map)).toList();
      final favoriteIds = (backupData['favorites'] as List).cast<String>();
      
      // Restore accounts
      for (final account in accounts) {
        final exists = await _accountService.accountExists(account);
        if (!exists) {
          await _accountService.addAccount(account);
        }
      }
      
      // Restore favorites
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoriteAccountsKey, favoriteIds);
      
      // Restore settings
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        if (settings.containsKey('theme')) {
          await prefs.setString('theme_mode', settings['theme'] as String);
        }
      }
      
      if (kDebugMode) {
        debugPrint('Auto backup restored: ${accounts.length} accounts');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auto backup restore failed: $e');
      }
      return false;
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

  /// Get backup metadata (account count, timestamp) without full restore
  /// 
  /// IMPORTANT: This method NEVER deletes the backup file, even if decryption fails.
  /// Deletion only happens during explicit restore attempts.
  Future<Map<String, dynamic>?> getBackupMetadata() async {
    print('=== GET BACKUP METADATA ===');
    
    try {
      final backupFile = await _getBackupFile();
      print('Backup file path: ${backupFile.path}');
      
      if (!await backupFile.exists()) {
        print('❌ Backup file does NOT exist');
        return null;
      }
      
      print('✓ Backup file exists');
      
      // Read and decrypt backup
      final encryptedData = await backupFile.readAsString();
      print('Encrypted data length: ${encryptedData.length} bytes');
      
      // Try to decrypt - if it fails, return null but DON'T delete
      try {
        print('Attempting to decrypt backup...');
        final jsonData = await _encryptionService.decryptBackupWithHardwareDEK(encryptedData);
        print('✓ Decryption successful');
        
        final backupData = json.decode(jsonData) as Map<String, dynamic>;
        print('✓ JSON parsed successfully');
        
        // Extract metadata
        final accountMaps = (backupData['accounts'] as List).cast<Map<String, dynamic>>();
        final timestamp = backupData['backup_timestamp'] as int?;
        
        print('Account count in backup: ${accountMaps.length}');
        print('Backup timestamp: $timestamp');
        
        return {
          'account_count': accountMaps.length,
          'timestamp': timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null,
          'app_version': backupData['app_version'],
        };
      } catch (e) {
        // Decryption failed - backup is unreadable
        // ✓ DO NOT delete backup here - just return null
        // Deletion only happens during explicit restore attempts
        print('❌ Backup decryption failed: $e');
        print('Backup file preserved - deletion only during restore');
        
        return null;
      }
    } catch (e) {
      print('❌ Failed to get backup metadata: $e');
      return null;
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    return await _preferencesService.getLastBackupTime();
  }

  /// Check if backup is enabled
  Future<bool> isBackupEnabled() async {
    return await _preferencesService.isBackupEnabled();
  }

  /// Enable automatic backup with account verification
  Future<void> enableBackup() async {
    // Get and verify platform account
    final accountId = await _platformAccountService.getAccountId();
    
    // Enable backup with this account
    await enableBackupWithAccount(accountId);
  }

  /// Enable automatic backup with pre-selected account (avoids showing picker again)
  Future<void> enableBackupWithAccount(String accountId) async {
    // Enable backup with this account
    await _preferencesService.enableBackup(accountId);
    
    // Check if accounts exist
    final accounts = await _accountService.getAllAccounts();
    
    if (kDebugMode) {
      debugPrint('Automatic backup enabled for account: $accountId');
      debugPrint('Found ${accounts.length} existing accounts');
    }
    
    if (accounts.isNotEmpty) {
      // Create initial backup if accounts already exist
      // This handles the case where user adds accounts BEFORE enabling backup
      if (kDebugMode) {
        debugPrint('Creating initial backup with ${accounts.length} accounts');
      }
      await createAutoBackup();
    } else {
      // No accounts yet, backup will be created when first account is added
      if (kDebugMode) {
        debugPrint('No accounts yet, backup will be created when first account is added');
      }
    }
  }

  /// Disable automatic backup
  Future<void> disableBackup() async {
    await _preferencesService.disableBackup();
  }

  /// Get backup account info (email/ID)
  Future<String?> getBackupAccountId() async {
    return await _preferencesService.getBackupAccountId();
  }

  /// Delete backup file
  Future<void> deleteBackup() async {
    try {
      final backupFile = await _getBackupFile();
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      
      await _preferencesService.clearPreferences();
      
      if (kDebugMode) {
        debugPrint('Auto backup deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete backup: $e');
      }
    }
  }

  /// Save encrypted data to platform backup location
  Future<void> _saveToBackupLocation(String encryptedData) async {
    final backupFile = await _getBackupFile();
    await backupFile.writeAsString(encryptedData);
  }

  /// Get backup file location
  /// 
  /// Android: app's files directory (backed up by Auto Backup)
  /// iOS: app's documents directory (backed up by iCloud)
  Future<File> _getBackupFile() async {
    if (Platform.isAndroid) {
      // Android: Use getApplicationDocumentsDirectory (backed up automatically)
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_backupFileName');
    } else if (Platform.isIOS) {
      // iOS: Use getApplicationDocumentsDirectory (backed up to iCloud)
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_backupFileName');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}
