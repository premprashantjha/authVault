import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/backup_setup_prompt.dart';

/// Helper for showing backup setup prompts at strategic moments
class BackupPromptHelper {
  static const String _accountCountKey = 'account_count_for_prompt';
  static const String _firstAccountDateKey = 'first_account_date';
  
  /// Call this after adding an account
  static Future<void> onAccountAdded(
    BuildContext context,
    CloudSyncService cloudSyncService,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if cloud sync is already enabled
    final enabled = await cloudSyncService.isCloudSyncEnabled();
    if (enabled) return;
    
    // Increment account count
    final currentCount = prefs.getInt(_accountCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_accountCountKey, newCount);
    
    // Store first account date
    if (currentCount == 0) {
      await prefs.setInt(_firstAccountDateKey, DateTime.now().millisecondsSinceEpoch);
    }
    
    // Show prompt at strategic moments
    if (!context.mounted) return;
    
    if (newCount == 1) {
      // First account - show immediately
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;
      await BackupSetupPrompt.show(context, cloudSyncService);
    } else if (newCount == 3) {
      // Third account - remind if skipped
      await Future.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;
      await BackupSetupPrompt.show(context, cloudSyncService);
    }
  }
  
  /// Call this on app startup to check if we should show reminder
  static Future<void> checkStartupReminder(
    BuildContext context,
    CloudSyncService cloudSyncService,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if cloud sync is already enabled
    final enabled = await cloudSyncService.isCloudSyncEnabled();
    if (enabled) return;
    
    // Check if user has accounts
    final accountCount = prefs.getInt(_accountCountKey) ?? 0;
    if (accountCount == 0) return;
    
    // Check if 7 days have passed since first account
    final firstAccountTimestamp = prefs.getInt(_firstAccountDateKey);
    if (firstAccountTimestamp == null) return;
    
    final firstAccountDate = DateTime.fromMillisecondsSinceEpoch(firstAccountTimestamp);
    final daysSinceFirst = DateTime.now().difference(firstAccountDate).inDays;
    
    if (daysSinceFirst >= 7) {
      // Show reminder after 7 days
      if (!context.mounted) return;
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      await BackupSetupPrompt.show(context, cloudSyncService);
    }
  }
  
  /// Reset prompt state (for testing)
  static Future<void> resetPromptState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountCountKey);
    await prefs.remove(_firstAccountDateKey);
    await prefs.remove('backup_setup_last_shown');
    await prefs.remove('backup_setup_dismissed_forever');
  }
}
