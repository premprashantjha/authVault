import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage backup preferences
/// 
/// Controls whether automatic backup is enabled and stores backup settings
class BackupPreferencesService {
  static const String _backupEnabledKey = 'auto_backup_enabled';
  static const String _backupAccountIdKey = 'backup_account_id';
  static const String _lastBackupTimeKey = 'last_backup_timestamp';

  /// Check if automatic backup is enabled
  Future<bool> isBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? false;
  }

  /// Enable automatic backup
  Future<void> enableBackup(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, true);
    await prefs.setString(_backupAccountIdKey, accountId);
  }

  /// Disable automatic backup
  Future<void> disableBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, false);
    // Keep account ID for potential re-enable
  }

  /// Get stored backup account ID
  Future<String?> getBackupAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupAccountIdKey);
  }

  /// Update last backup timestamp
  Future<void> updateLastBackupTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, time.millisecondsSinceEpoch);
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Clear all backup preferences
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupEnabledKey);
    await prefs.remove(_backupAccountIdKey);
    await prefs.remove(_lastBackupTimeKey);
  }
}
