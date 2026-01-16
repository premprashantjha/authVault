import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../services/local_backup_service.dart';
import '../services/backup_ui_strings.dart';
import '../view_models/account_view_model.dart';
import '../widgets/backup_password_setup_dialog.dart';
import '../widgets/backup_password_dialog.dart';
import '../widgets/custom_snackbar.dart';

class AutoBackupSettingsScreen extends StatefulWidget {
  final LocalBackupService backupService;

  const AutoBackupSettingsScreen({
    super.key,
    required this.backupService,
  });

  @override
  State<AutoBackupSettingsScreen> createState() => _AutoBackupSettingsScreenState();
}

class _AutoBackupSettingsScreenState extends State<AutoBackupSettingsScreen> {
  bool _isBackupEnabled = false;
  bool _isLoading = true;
  DateTime? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
  }

  Future<void> _loadBackupStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final isEnabled = await widget.backupService.isBackupEnabled();
      final lastBackup = await widget.backupService.getLastBackupTime();
      
      setState(() {
        _isBackupEnabled = isEnabled;
        _lastBackupTime = lastBackup;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBackup(bool value) async {
    if (value) {
      await _enableBackup();
    } else {
      await _disableBackup();
    }
  }

  Future<void> _enableBackup() async {
    try {
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const BackupPasswordSetupDialog(
          title: 'Enable Local Encrypted Backup',
          description: 'Set a password to protect your local backup',
        ),
      );

      if (password == null) return;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _buildEnableBackupDialog(dialogContext),
      );

      if (confirmed == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        const accountId = 'local_device';
        await widget.backupService.enableBackup(accountId, password);
        
        if (!mounted) return;
        Navigator.pop(context);
        
        await _loadBackupStatus();
        
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: BackupUIStrings.backupEnabledMessage,
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      CustomSnackbar.show(
        context,
        message: 'Failed to enable backup: $e',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _disableBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDisableBackupDialog(),
    );

    if (confirmed == true) {
      try {
        await widget.backupService.disableBackup();
        await _loadBackupStatus();
        
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: BackupUIStrings.backupDisabledMessage,
          type: SnackbarType.info,
        );
      } catch (e) {
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: 'Failed to disable backup: $e',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      // Check if backup exists
      final hasBackup = await widget.backupService.hasBackup();
      
      if (!hasBackup) {
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: 'No local backup found. Enable backup and add accounts first.',
          type: SnackbarType.info,
        );
        return;
      }

      // Show confirmation dialog (without account count since we need password to decrypt)
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Local Backup?'),
          content: const Text(
            'This will restore your accounts from the local backup.\n\n'
            'Existing accounts will be kept, and duplicates will be skipped.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Prompt for password
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const BackupPasswordDialog(
          title: 'Restore Backup',
          description: 'Enter your backup password',
          isCreating: false,
        ),
      );

      if (password == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform restore
      final success = await widget.backupService.restoreAutoBackup(password);

      // Close loading
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        // Reload accounts in view model
        final viewModel = Provider.of<AccountViewModel>(context, listen: false);
        await viewModel.reloadAfterUnlock();

        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: BackupUIStrings.restoreSuccessMessage,
          type: SnackbarType.success,
        );

        // Go back to home
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: 'Restore failed. Please try again.',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      // Close loading if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      
      // Check if it's a password error
      final errorMessage = e.toString();
      if (errorMessage.contains('password') || 
          errorMessage.contains('Authentication failed') ||
          errorMessage.contains('decryption')) {
        CustomSnackbar.show(
          context,
          message: 'Incorrect password. Please try again.',
          type: SnackbarType.error,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: 'Restore failed: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  Widget _buildEnableBackupDialog(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Enable Local Encrypted Backup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your accounts will be automatically backed up to:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    BackupUIStrings.backupLocation,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '• Backups are encrypted with your password\n'
            '• Stored securely on this device\n'
            '• Automatic updates when accounts change',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enable'),
        ),
      ],
    );
  }

  Widget _buildDisableBackupDialog() {
    return AlertDialog(
      title: const Text('Disable Local Encrypted Backup?'),
      content: const Text(
        'Your existing backup will remain on this device, but new changes won\'t be backed up automatically.\n\n'
        'You can re-enable backup anytime.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
          ),
          child: const Text('Disable'),
        ),
      ],
    );
  }

  String _formatLastBackupTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          BackupUIStrings.backupFeatureName,
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isBackupEnabled ? Icons.backup : Icons.backup_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BackupUIStrings.backupFeatureName,
                                style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isBackupEnabled ? 'Enabled' : 'Disabled',
                                style: AppTheme.caption(theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isBackupEnabled,
                          onChanged: _toggleBackup,
                          activeTrackColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isBackupEnabled) ...[
                  const SizedBox(height: 24),

                  Text(
                    'LAST BACKUP',
                    style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _lastBackupTime != null
                                  ? _formatLastBackupTime(_lastBackupTime!)
                                  : 'Never',
                              style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Text(
                  'RESTORE',
                  style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: InkWell(
                    onTap: _restoreBackup,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.restore,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restore from Local Backup',
                                  style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Restore your accounts from automatic backup',
                                  style: AppTheme.caption(theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'HOW IT WORKS',
                  style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.lock_outline,
                          'Password Encryption',
                          'Backups are encrypted with your password',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.phone_android,
                          'Local Storage',
                          'Stored securely on this device only',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.cloud_upload,
                          'Automatic Backup',
                          'Updates automatically when accounts change',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.restore,
                          'Easy Restore',
                          'Restore accounts anytime with your password',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.caption(theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
