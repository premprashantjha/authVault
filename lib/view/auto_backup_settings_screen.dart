import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../services/auto_backup_service.dart';
import '../services/platform_account_service.dart';
import '../widgets/backup_password_setup_dialog.dart';
import '../widgets/custom_snackbar.dart';

class AutoBackupSettingsScreen extends StatefulWidget {
  final AutoBackupService backupService;

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
  String? _backupAccountId;
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
      final accountId = await widget.backupService.getBackupAccountId();
      final lastBackup = await widget.backupService.getLastBackupTime();
      
      setState(() {
        _isBackupEnabled = isEnabled;
        _backupAccountId = accountId;
        _lastBackupTime = lastBackup;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBackup(bool value) async {
    if (value) {
      // Enable backup - verify account first
      await _enableBackup();
    } else {
      // Disable backup
      await _disableBackup();
    }
  }

  Future<void> _enableBackup() async {
    try {
      // Get platform account (shows system account picker ONCE)
      final platformService = PlatformAccountService();
      final accountId = await platformService.getAccountId();

      // Show password setup dialog
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const BackupPasswordSetupDialog(
          title: 'Enable Auto Backup',
          description: 'Set a password to protect your automatic backups',
        ),
      );

      if (password == null) return; // User cancelled

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _buildEnableBackupDialog(accountId),
      );

      if (confirmed == true) {
        // Show loading while enabling
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Enable backup with the account ID and password
        await widget.backupService.enableBackupWithAccount(accountId, password);
        
        // Close loading
        if (!mounted) return;
        Navigator.pop(context);
        
        // Reload status
        await _loadBackupStatus();
        
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          message: '✓ Automatic backup enabled',
          type: SnackbarType.success,
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      
      if (e.code == 'CANCELLED') {
        // User cancelled account selection - just return, no error
        return;
      } else if (e.code == 'NO_ACCOUNT_SELECTED') {
        // No account was selected
        CustomSnackbar.show(
          context,
          message: 'Please select a Google account to continue',
          type: SnackbarType.error,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: e.message ?? 'Failed to enable backup',
          type: SnackbarType.error,
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
          message: 'Automatic backup disabled',
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

  Widget _buildEnableBackupDialog(String accountId) {
    return AlertDialog(
      title: const Text('Enable Automatic Backup?'),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accountId,
                    style: const TextStyle(
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
            '• Backups are encrypted with your account\n'
            '• Works across all your devices\n'
            '• Automatic restore on new devices',
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
      title: const Text('Disable Automatic Backup?'),
      content: const Text(
        'Your existing backup will remain, but new changes won\'t be backed up automatically.\n\n'
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
            backgroundColor: Colors.orange,
          ),
          child: const Text('Disable'),
        ),
      ],
    );
  }

  Future<void> _openDeviceSettings() async {
    try {
      // Try to open Android settings
      const platform = MethodChannel('authenticator/settings');
      await platform.invokeMethod('openSettings');
    } catch (e) {
      // If it fails, show a message
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Please open Settings manually from your device',
        type: SnackbarType.info,
      );
    }
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
          'Automatic Backup',
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
                // Enable/Disable Toggle
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isBackupEnabled ? Icons.cloud_done : Icons.cloud_off,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Automatic Backup',
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
                          activeColor: Colors.white,
                          activeTrackColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isBackupEnabled) ...[
                  const SizedBox(height: 24),

                  // Backup Account Info
                  Text(
                    'BACKUP ACCOUNT',
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
                            Icons.account_circle,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _backupAccountId ?? 'Unknown',
                              style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Last Backup Time
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

                // Info Section
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
                          'Account-Bound Encryption',
                          'Backups are encrypted with your Google/Apple account',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.devices,
                          'Multi-Device Sync',
                          'Same account works across all your devices',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.cloud_upload,
                          'Automatic Backup',
                          'Changes are backed up automatically every 5 seconds',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.restore,
                          'Automatic Restore',
                          'Accounts restore automatically on new devices',
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
          color: AppTheme.primaryColor,
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
