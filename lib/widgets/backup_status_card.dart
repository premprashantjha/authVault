import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/cloud_sync_service.dart';
import '../services/google_account_service.dart';
import 'backup_password_setup_dialog.dart';
import 'backup_password_dialog.dart';
import 'custom_snackbar.dart';

/// Smart backup status card
/// 
/// Shows different states:
/// - Not protected (no password set)
/// - Protected (password set, cloud sync enabled)
/// - Syncing (sync in progress)
/// - Error (sync failed)
class BackupStatusCard extends StatefulWidget {
  final CloudSyncService cloudSyncService;
  final VoidCallback? onStatusChanged;

  const BackupStatusCard({
    super.key,
    required this.cloudSyncService,
    this.onStatusChanged,
  });

  @override
  State<BackupStatusCard> createState() => _BackupStatusCardState();
}

class _BackupStatusCardState extends State<BackupStatusCard> {
  CloudSyncStatusInfo? _status;
  bool _isLoading = true;
  String? _googleAccount; // Cache Google account
  bool _isLoadingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadGoogleAccount(); // Load once on init
    
    // Listen to sync status changes
    widget.cloudSyncService.syncStatusStream.listen((status) {
      if (mounted) {
        _loadStatus();
      }
    });
  }

  Future<void> _loadStatus() async {
    final status = await widget.cloudSyncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadGoogleAccount() async {
    setState(() => _isLoadingAccount = true);
    try {
      final account = await GoogleAccountService.getPrimaryGoogleAccount();
      if (mounted) {
        setState(() {
          _googleAccount = account;
          _isLoadingAccount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _googleAccount = null;
          _isLoadingAccount = false;
        });
      }
    }
  }

  Future<void> _handleEnableCloudSync() async {
    // Step 1: Show account picker
    final selectedAccount = await _showAccountPicker();
    if (selectedAccount == null) return;

    // Step 2: Show password setup dialog
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const BackupPasswordSetupDialog(
        title: 'Enable Cloud Sync',
        description: 'Set a password to protect and sync your accounts',
      ),
    );
    
    if (password == null) return;
    
    // Show progress
    if (!mounted) return;
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
      await widget.cloudSyncService.enableCloudSync(password);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      CustomSnackbar.show(
        context,
        title: 'Cloud Sync Enabled',
        message: 'Your accounts are now protected and synced',
        type: SnackbarType.success,
      );
      
      await _loadStatus();
      widget.onStatusChanged?.call();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      CustomSnackbar.show(
        context,
        title: 'Failed to Enable',
        message: e.toString().replaceFirst('CloudSyncException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  /// Show account picker dialog
  Future<String?> _showAccountPicker() async {
    // Get all available Google accounts
    final accounts = await GoogleAccountService.getAllGoogleAccounts();
    
    if (!mounted) return null;
    
    if (accounts.isEmpty) {
      // No accounts found
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No Google Accounts'),
          content: const Text(
            'Please sign in with a Google account on your device to enable cloud sync.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }
    
    if (accounts.length == 1) {
      // Only one account, use it directly
      return accounts[0];
    }
    
    // Multiple accounts, show picker
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Google Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Choose which Google account to use for cloud backup:',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              ...accounts.map((account) => ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(account),
                onTap: () => Navigator.pop(context, account),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSyncNow() async {
    try {
      await widget.cloudSyncService.syncNow();
      
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Synced',
        message: 'Your accounts have been synced',
        type: SnackbarType.success,
      );
      
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Sync Failed',
        message: e.toString(),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _handleDisableCloudSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disable Backup?'),
        content: const Text(
          'Your accounts will no longer be backed up automatically. '
          'You can re-enable backup anytime.\n\n'
          'This action is reversible.',
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
    
    if (confirmed != true) return;
    
    try {
      await widget.cloudSyncService.disableCloudSync();
      
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Backup Disabled',
        message: 'Automatic backup has been turned off',
        type: SnackbarType.info,
      );
      
      await _loadStatus();
      widget.onStatusChanged?.call();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Failed to Disable',
        message: e.toString(),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _handleRestoreFromCloud() async {
    // Import the dialog
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const BackupPasswordDialog(
        title: 'Restore from Cloud',
        description: 'Enter your backup password',
        isCreating: false,
      ),
    );
    
    if (password == null) return;
    
    // Show progress
    if (!mounted) return;
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
                Text('Restoring from cloud...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final restored = await widget.cloudSyncService.restoreFromCloud(password);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      CustomSnackbar.show(
        context,
        title: 'Restore Complete',
        message: '$restored accounts restored successfully',
        type: SnackbarType.success,
      );
      
      await _loadStatus();
      widget.onStatusChanged?.call();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress
      
      CustomSnackbar.show(
        context,
        title: 'Restore Failed',
        message: e.toString().replaceFirst('CloudSyncException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ),
      );
    }
    
    final enabled = _status?.enabled ?? false;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enabled
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    enabled ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: enabled ? colorScheme.primary : colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            enabled ? 'Backup Enabled' : 'Backup Disabled',
                            style: AppTheme.title(colorScheme.onSurface).copyWith(
                              fontWeight: AppTheme.weightBold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showBackupInfoDialog(context),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled 
                            ? 'Your accounts are protected' 
                            : 'Set a password to protect your accounts',
                        style: AppTheme.caption(
                          enabled ? colorScheme.primary : colorScheme.error,
                        ).copyWith(fontWeight: AppTheme.weightMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (enabled) ...[
              const SizedBox(height: 16),
              // Google Account Info (cached)
              if (_isLoadingAccount)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Loading account...',
                          style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_googleAccount != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup Account',
                              style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _googleAccount!,
                              style: AppTheme.bodyMedium(colorScheme.onSurface).copyWith(
                                fontWeight: AppTheme.weightMedium,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Last sync info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Last backup: ${_status?.statusText ?? "Never"}',
                        style: AppTheme.bodyMedium(colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action button
            if (enabled) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleSyncNow,
                      icon: const Icon(Icons.sync_rounded, size: 20),
                      label: const Text('Sync Now'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleDisableCloudSync,
                      icon: const Icon(Icons.cloud_off_rounded, size: 20),
                      label: const Text('Disable'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Check if cloud backup exists
              FutureBuilder<bool>(
                future: widget.cloudSyncService.hasCloudBackup(),
                builder: (context, snapshot) {
                  final hasBackup = snapshot.data ?? false;
                  
                  if (hasBackup) {
                    // Show restore option
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_download_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Cloud backup found. Restore your accounts with your password.',
                                  style: AppTheme.caption(colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _handleRestoreFromCloud,
                          icon: const Icon(Icons.restore, size: 22),
                          label: const Text('Restore from Cloud'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Show enable backup option
                    return ElevatedButton.icon(
                      onPressed: _handleEnableCloudSync,
                      icon: const Icon(Icons.shield_rounded, size: 22),
                      label: const Text('Enable Backup'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showBackupInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'About Backup',
                        style: AppTheme.headlineMedium(colorScheme.onSurface).copyWith(
                          fontWeight: AppTheme.weightBold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _InfoSection(
                  icon: Icons.lock_rounded,
                  title: 'Why Password?',
                  description: 'Your password encrypts your accounts so only you can access them. Even if someone gets your backup file, they cannot decrypt it without your password.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _InfoSection(
                  icon: Icons.cloud_sync_rounded,
                  title: 'Cloud Backup',
                  description: 'When enabled, your accounts may be backed up to cloud storage. Backup timing depends on your device and network conditions.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _InfoSection(
                  icon: Icons.phone_android_rounded,
                  title: 'Device Restore',
                  description: 'You can restore your accounts on a new device by entering your password, if the backup was successfully synced.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _InfoSection(
                  icon: Icons.security_rounded,
                  title: 'Secure & Private',
                  description: 'Your accounts are encrypted with strong encryption. Your password never leaves your device and cannot be recovered if lost.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),
                
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important',
                              style: AppTheme.bodyMedium(colorScheme.error).copyWith(
                                fontWeight: AppTheme.weightBold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cloud backup depends on your device settings and may not work in all cases. For guaranteed backup, use manual export. Store your password safely - it cannot be recovered.',
                              style: AppTheme.caption(colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Got It'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool enabled;
  final ColorScheme colorScheme;

  const _StatusItem({
    required this.icon,
    required this.text,
    required this.enabled,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled ? Colors.green : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium(
                enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
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
              const SizedBox(height: 4),
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
