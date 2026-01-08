import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../services/cloud_sync_service.dart';
import 'backup_password_setup_dialog.dart';
import 'custom_snackbar.dart';

/// Smart backup setup prompt
/// 
/// Shows at strategic moments:
/// - After first account added
/// - After 3 accounts added (if skipped)
/// - After 7 days of use (if skipped)
/// 
/// Features:
/// - Clear explanation of benefits
/// - Password strength indicator
/// - Generate strong password
/// - Skip with reminder
class BackupSetupPrompt extends StatelessWidget {
  final CloudSyncService cloudSyncService;
  final VoidCallback? onSetupComplete;

  const BackupSetupPrompt({
    super.key,
    required this.cloudSyncService,
    this.onSetupComplete,
  });

  /// Check if we should show the prompt
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if already enabled
    final enabled = prefs.getBool('cloud_sync_enabled') ?? false;
    if (enabled) return false;
    
    // Don't show if permanently dismissed
    final dismissed = prefs.getBool('backup_setup_dismissed_forever') ?? false;
    if (dismissed) return false;
    
    // Check if we should remind
    final lastShown = prefs.getInt('backup_setup_last_shown') ?? 0;
    final daysSinceLastShown = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastShown))
        .inDays;
    
    // Show after 7 days if skipped
    if (lastShown > 0 && daysSinceLastShown < 7) return false;
    
    return true;
  }

  /// Mark as shown
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backup_setup_last_shown', DateTime.now().millisecondsSinceEpoch);
  }

  /// Show the prompt dialog
  static Future<void> show(
    BuildContext context,
    CloudSyncService cloudSyncService, {
    VoidCallback? onSetupComplete,
  }) async {
    final shouldShowPrompt = await shouldShow();
    if (!shouldShowPrompt) return;
    
    await markAsShown();
    
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackupSetupPrompt(
        cloudSyncService: cloudSyncService,
        onSetupComplete: onSetupComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_done,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Protect Your Accounts',
              style: AppTheme.headlineMedium(colorScheme.onSurface).copyWith(
                fontWeight: AppTheme.weightBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Set a backup password to enable:',
              style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Benefits
            _BenefitItem(
              icon: Icons.cloud_sync,
              title: 'Cloud Backup',
              description: 'May backup to cloud when conditions allow',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.phone_android,
              title: 'Device Restore',
              description: 'Restore on new device with your password',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.file_download,
              title: 'Manual Export',
              description: 'Create backup files you can save anywhere',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Without a password, you can only use manual backups on this device. Cloud backup requires a password.',
                      style: AppTheme.caption(colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleSkip(context),
                    child: const Text('Skip for Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _handleSetup(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Set Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dismiss forever
            TextButton(
              onPressed: () => _handleDismissForever(context),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              child: const Text(
                'Don\'t show this again',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSetup(BuildContext context) async {
    Navigator.of(context).pop();
    
    if (!context.mounted) return;
    
    // Show password setup dialog
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const BackupPasswordSetupDialog(),
    );
    
    if (password == null) return;
    
    // Show progress
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Enabling cloud sync...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Enable cloud sync
      await cloudSyncService.enableCloudSync(password);
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      // Show success
      CustomSnackbar.show(
        context,
        title: 'Cloud Sync Enabled',
        message: 'Your accounts are now protected and synced across devices',
        type: SnackbarType.success,
      );
      
      onSetupComplete?.call();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      CustomSnackbar.show(
        context,
        title: 'Setup Failed',
        message: e.toString().replaceFirst('CloudSyncException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _handleSkip(BuildContext context) async {
    await markAsShown();
    Navigator.of(context).pop();
  }

  Future<void> _handleDismissForever(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Backup Reminders?'),
        content: const Text(
          'You won\'t be reminded to set up backup protection. '
          'You can still enable it manually in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backup_setup_dismissed_forever', true);
      
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.tertiary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium(colorScheme.onSurface).copyWith(
                  fontWeight: AppTheme.weightSemiBold,
                ),
              ),
              Text(
                description,
                style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
