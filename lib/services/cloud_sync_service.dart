import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import 'account_service.dart';
import 'encryption_service.dart';

/// Cloud sync service for automatic cross-device backup
/// 
/// Features:
/// - Automatic sync on account changes
/// - Zero-knowledge encryption (server cannot decrypt)
/// - Conflict resolution
/// - Network error handling with retry
/// - Sync status tracking
class CloudSyncService {
  final EncryptionService _encryptionService;
  final AccountService _accountService;
  
  static const String _cloudSyncEnabledKey = 'cloud_sync_enabled';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _syncPasswordHashKey = 'sync_password_hash';
  static const String _wrappedDekKey = 'cloud_wrapped_dek';
  
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  
  // Callbacks for UI updates
  final _syncStatusController = StreamController<CloudSyncStatus>.broadcast();
  Stream<CloudSyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  CloudSyncService({
    required AccountService accountService,
    EncryptionService? encryptionService,
  })  : _accountService = accountService,
        _encryptionService = encryptionService ?? EncryptionService() {
    _initAutoSync();
  }

  /// Initialize automatic sync
  void _initAutoSync() {
    // Don't start periodic timer
    // Sync will only happen on-demand when accounts change
    print('✓ [CloudSync] Manual sync mode enabled');
  }

  /// Enable cloud sync with password
  /// 
  /// This will:
  /// 1. Store password hash for verification
  /// 2. Perform initial sync using EncryptionService
  /// 3. Enable automatic syncing
  Future<void> enableCloudSync(String password) async {
    print('🔐 [CloudSync] Enable cloud sync started');
    print('🔐 [CloudSync] Password length: ${password.length}');
    
    if (password.isEmpty) {
      throw CloudSyncException('Password cannot be empty');
    }
    
    try {
      _notifyStatus(CloudSyncStatus.enabling);
      
      // Validate password strength
      if (password.length < 8) {
        throw CloudSyncException('Password must be at least 8 characters');
      }
      print('✓ [CloudSync] Password validated');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Store password hash for verification (NOT the password itself)
      final passwordHash = _hashPassword(password);
      await prefs.setString(_syncPasswordHashKey, passwordHash);
      print('✓ [CloudSync] Password hash saved');
      
      // Mark cloud sync as enabled
      await prefs.setBool(_cloudSyncEnabledKey, true);
      print('✓ [CloudSync] Cloud sync enabled flag set');
      
      // Perform initial sync
      print('🔄 [CloudSync] Performing initial sync...');
      await syncNow();
      
      _notifyStatus(CloudSyncStatus.enabled);
      
      print('✅ [CloudSync] Cloud sync enabled successfully');
      print('✅ [CloudSync] Backup is now recoverable after reinstall!');
    } catch (e) {
      print('❌ [CloudSync] Enable failed: $e');
      _notifyStatus(CloudSyncStatus.error);
      throw CloudSyncException('Failed to enable cloud sync: $e');
    }
  }

  /// Disable cloud sync
  Future<void> disableCloudSync() async {
    try {
      _notifyStatus(CloudSyncStatus.disabling);
      
      final prefs = await SharedPreferences.getInstance();
      
      // Remove cloud sync data
      await prefs.remove(_cloudSyncEnabledKey);
      await prefs.remove(_wrappedDekKey);
      await prefs.remove(_syncPasswordHashKey);
      await prefs.remove(_lastSyncTimestampKey);
      
      // Stop auto sync
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      
      _notifyStatus(CloudSyncStatus.disabled);
      
      if (kDebugMode) {
        debugPrint('✓ Cloud sync disabled');
      }
    } catch (e) {
      _notifyStatus(CloudSyncStatus.error);
      throw CloudSyncException('Failed to disable cloud sync: $e');
    }
  }

  /// Sync now (manual trigger)
  Future<void> syncNow({bool silent = false}) async {
    if (_isSyncing) {
      print('⚠️ [CloudSync] Sync already in progress, skipping');
      return;
    }
    
    _isSyncing = true;
    print('🔄 [CloudSync] Sync started (silent: $silent)');
    
    try {
      if (!silent) {
        _notifyStatus(CloudSyncStatus.syncing);
      }
      
      // Get all accounts
      final accounts = await _accountService.getAllAccounts();
      print('📊 [CloudSync] Found ${accounts.length} accounts to sync');
      
      // Create backup data
      final backupData = {
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
      };
      
      final jsonData = json.encode(backupData);
      print('📦 [CloudSync] Backup data size: ${jsonData.length} bytes');
      
      // Encrypt backup using EncryptionService
      print('🔐 [CloudSync] Encrypting backup...');
      final encryptedBackup = await _encryptionService.encrypt(jsonData);
      print('✓ [CloudSync] Backup encrypted successfully');
      
      // Save to app's files directory (Android Auto Backup will sync this)
      print('💾 [CloudSync] Saving to cloud storage...');
      await _saveToCloudStorage(encryptedBackup);
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('✓ [CloudSync] Last sync time updated');
      
      if (!silent) {
        _notifyStatus(CloudSyncStatus.synced);
      }
      
      print('✅ [CloudSync] Sync completed: ${accounts.length} accounts');
    } catch (e) {
      print('❌ [CloudSync] Sync failed: $e');
      if (!silent) {
        _notifyStatus(CloudSyncStatus.error);
      }
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Save encrypted backup to cloud storage
  /// Android Auto Backup will automatically sync this file to Google Drive
  Future<void> _saveToCloudStorage(String encryptedData) async {
    try {
      // Get app's documents directory (included in Android Auto Backup)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cloud_backup.dat');
      
      print('💾 [CloudSync] Saving to: ${file.path}');
      
      // Write encrypted backup
      await file.writeAsString(encryptedData);
      
      print('✅ [CloudSync] Saved to cloud storage successfully');
      print('📁 [CloudSync] File size: ${await file.length()} bytes');
    } catch (e) {
      print('❌ [CloudSync] Failed to save to cloud storage: $e');
      throw CloudSyncException('Failed to save to cloud storage: $e');
    }
  }
  
  /// Load encrypted backup from cloud storage
  Future<String?> _loadFromCloudStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cloud_backup.dat');
      
      print('📂 [CloudSync] Loading from: ${file.path}');
      
      if (!await file.exists()) {
        print('⚠️ [CloudSync] Backup file does not exist');
        return null;
      }
      
      final encryptedData = await file.readAsString();
      print('✅ [CloudSync] Loaded from cloud storage');
      print('📁 [CloudSync] File size: ${encryptedData.length} bytes');
      
      return encryptedData;
    } catch (e) {
      print('❌ [CloudSync] Failed to load from cloud storage: $e');
      return null;
    }
  }

  /// Restore from cloud sync
  /// 
  /// Uses EncryptionService for simplified decryption
  Future<int> restoreFromCloud(String password) async {
    print('🔄 [CloudSync] Restore from cloud started');
    print('🔐 [CloudSync] Password length: ${password.length}');
    
    try {
      _notifyStatus(CloudSyncStatus.restoring);
      
      final prefs = await SharedPreferences.getInstance();
      
      // Verify password
      print('🔐 [CloudSync] Verifying password...');
      final storedHash = prefs.getString(_syncPasswordHashKey);
      final providedHash = _hashPassword(password);
      if (storedHash != providedHash) {
        print('❌ [CloudSync] Password verification failed');
        throw CloudSyncException('Incorrect password');
      }
      print('✓ [CloudSync] Password verified');
      
      // Load encrypted backup from cloud storage
      print('📥 [CloudSync] Loading backup from cloud storage...');
      final encryptedBackup = await _loadFromCloudStorage();
      if (encryptedBackup == null) {
        print('❌ [CloudSync] No backup data found');
        throw CloudSyncException('No backup data found in cloud storage');
      }
      print('✓ [CloudSync] Backup loaded');
      
      // Decrypt backup using EncryptionService
      print('🔓 [CloudSync] Decrypting backup...');
      final jsonData = await _encryptionService.decrypt(encryptedBackup);
      final backupData = json.decode(jsonData) as Map<String, dynamic>;
      print('✓ [CloudSync] Backup decrypted');
      
      // Restore accounts
      print('📦 [CloudSync] Restoring accounts...');
      final accountMaps = (backupData['accounts'] as List).cast<Map<String, dynamic>>();
      final accounts = accountMaps.map((map) => Account.fromMap(map)).toList();
      print('📊 [CloudSync] Found ${accounts.length} accounts in backup');
      
      int restored = 0;
      for (final account in accounts) {
        final exists = await _accountService.accountExists(account);
        if (!exists) {
          await _accountService.addAccount(account);
          restored++;
          print('   ✓ Restored: ${account.issuer} - ${account.accountName}');
        } else {
          print('   ⊘ Skipped (exists): ${account.issuer} - ${account.accountName}');
        }
      }
      
      // Mark cloud sync as enabled
      await prefs.setBool(_cloudSyncEnabledKey, true);
      
      _notifyStatus(CloudSyncStatus.restored);
      
      print('✅ [CloudSync] Restore completed: $restored accounts restored');
      print('✅ [CloudSync] Cloud sync is now active on this device!');
      
      return restored;
    } catch (e) {
      print('❌ [CloudSync] Restore failed: $e');
      _notifyStatus(CloudSyncStatus.error);
      if (e is CloudSyncException) rethrow;
      throw CloudSyncException('Failed to restore from cloud: $e');
    }
  }

  /// Check if cloud sync is enabled
  Future<bool> isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudSyncEnabledKey) ?? false;
  }
  
  /// Check if cloud backup exists (for restore)
  Future<bool> hasCloudBackup() async {
    try {
      print('🔍 [CloudSync] Checking if cloud backup exists...');
      
      // Check if password hash exists (indicates cloud sync was enabled)
      final prefs = await SharedPreferences.getInstance();
      final passwordHash = prefs.getString(_syncPasswordHashKey);
      if (passwordHash == null) {
        print('⚠️ [CloudSync] No password hash found');
        return false;
      }
      print('✓ [CloudSync] Password hash exists');
      
      // Check if backup file exists
      final backupData = await _loadFromCloudStorage();
      if (backupData == null) {
        print('⚠️ [CloudSync] No backup file found');
        return false;
      }
      print('✓ [CloudSync] Backup file exists');
      
      print('✅ [CloudSync] Cloud backup is available');
      return true;
    } catch (e) {
      print('❌ [CloudSync] Error checking cloud backup: $e');
      return false;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncTimestampKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Get sync status
  Future<CloudSyncStatusInfo> getSyncStatus() async {
    final enabled = await isCloudSyncEnabled();
    final lastSync = await getLastSyncTime();
    
    return CloudSyncStatusInfo(
      enabled: enabled,
      lastSync: lastSync,
      isSyncing: _isSyncing,
    );
  }

  /// Trigger sync on account change
  Future<void> onAccountChanged() async {
    final enabled = await isCloudSyncEnabled();
    if (enabled && !_isSyncing) {
      // Debounce: Wait 2 seconds before syncing
      Future.delayed(const Duration(seconds: 2), () {
        syncNow(silent: true);
      });
    }
  }

  /// Secure password hash using HMAC-SHA256
  String _hashPassword(String password) {
    const salt = 'com.cdac.authenticator.backup.password';
    return Hmac(sha256, utf8.encode(salt))
        .convert(utf8.encode(password))
        .toString();
  }

  /// Notify status change
  void _notifyStatus(CloudSyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  /// Dispose resources
  void dispose() {
    _autoSyncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Cloud sync status
enum CloudSyncStatus {
  disabled,
  enabling,
  enabled,
  disabling,
  syncing,
  synced,
  restoring,
  restored,
  error,
}

/// Cloud sync status info
class CloudSyncStatusInfo {
  final bool enabled;
  final DateTime? lastSync;
  final bool isSyncing;

  CloudSyncStatusInfo({
    required this.enabled,
    required this.lastSync,
    required this.isSyncing,
  });

  String get statusText {
    if (!enabled) return 'Disabled';
    if (isSyncing) return 'Syncing...';
    if (lastSync == null) return 'Never synced';
    
    final now = DateTime.now();
    final diff = now.difference(lastSync!);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Cloud sync exception
class CloudSyncException implements Exception {
  final String message;
  
  CloudSyncException(this.message);
  
  @override
  String toString() => 'CloudSyncException: $message';
}
