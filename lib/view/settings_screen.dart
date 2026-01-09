import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';
import '../services/backup_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/platform_backup_service.dart';
import '../services/encryption_service.dart';
import '../services/integrity_service.dart';
import '../services/database_service.dart';
import '../services/account_service.dart';
import '../services/auto_backup_service.dart';
import '../services/platform_account_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/skeleton.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/restore_prompt_dialog.dart';
import '../widgets/backup_status_card.dart';
import 'onboarding_screen.dart';
import 'backup_screen.dart';
import 'auto_backup_settings_screen.dart';
import 'recovery_codes_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() => _isLoading = false);
  }

  void _openSecurityGuide({int initialPage = 0}) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          allowSkip: false,
          isReviewMode: true,
          initialPageIndex: initialPage,
          onFinished: () {
            navigator.pop();
          },
        ),
      ),
    );
  }

  // Lightweight skeletons for settings loading state
  Widget _buildLoadingSkeletons() {
    return ListView(
      padding: AppConstants.getResponsivePadding(context),
      children: [
        SizedBox(height: AppConstants.getResponsiveSpacing(context, xs: 2.0, sm: 4.0)),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
        SizedBox(height: AppConstants.getResponsiveSpacing(context)),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
        SizedBox(height: AppConstants.getResponsiveSpacing(context, lg: 24.0)),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
      ],
    );
  }

  void _navigateToAutoBackup(BuildContext context) {
    // Get the existing AccountService from Provider (same instance used by home screen)
    final accountViewModel = Provider.of<AccountViewModel>(context, listen: false);
    final autoBackupService = AutoBackupService(
      accountService: accountViewModel.accountService,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoBackupSettingsScreen(backupService: autoBackupService),
      ),
    );
  }

  void _navigateToBackup(BuildContext context) {
    // Get the existing AccountService from Provider (same instance used by home screen)
    final accountViewModel = Provider.of<AccountViewModel>(context, listen: false);
    final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
    final backupService = BackupService(
      accountService: accountViewModel.accountService,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupScreen(
          backupService: backupService,
          cloudSyncService: cloudSyncService,
        ),
      ),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  /// Check for backup and restore if available
  Future<void> _checkAndRestoreBackup(BuildContext context) async {
    try {
      // First, let user select which Google account to check
      final platformAccountService = PlatformAccountService();
      String? accountId;
      
      try {
        accountId = await platformAccountService.getAccountId();
      } catch (e) {
        // User cancelled account selection or no account available
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: PlatformBackupService.accountSelectionMessage,
            type: SnackbarType.info,
          );
        }
        return;
      }
      
      if (accountId == null || accountId.isEmpty) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: PlatformBackupService.noAccountMessage,
            type: SnackbarType.error,
          );
        }
        return;
      }
      
      // Show checking dialog with account info
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Checking for backup...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account: $accountId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      print('=== CHECK FOR BACKUP (Settings Screen) ===');
      print('Selected account: $accountId');

      // Create backup service using existing AccountService from Provider
      final accountViewModel = Provider.of<AccountViewModel>(context, listen: false);
      print('CHECK → AccountService: ${accountViewModel.accountService.hashCode}');
      print('CHECK → DatabaseService: ${accountViewModel.accountService.databaseService.hashCode}');
      
      final autoBackupService = AutoBackupService(
        accountService: accountViewModel.accountService,
      );
      
      // Check if backup exists
      print('Checking if backup file exists...');
      final hasBackup = await autoBackupService.hasBackup();
      print('hasBackup result: $hasBackup');
      
      // Close checking dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (!hasBackup) {
        print('No backup file found - showing no backup dialog');
        // No backup found - show helpful message with account info
        if (mounted) {
          _showNoBackupDialog(context, accountId);
        }
        return;
      }
      
      // Backup exists - get metadata and show restore prompt
      print('Backup file exists - getting metadata...');
      final metadata = await autoBackupService.getBackupMetadata();
      print('Metadata result: $metadata');
      
      final accountCount = metadata?['account_count'] ?? 0;
      print('Account count from metadata: $accountCount');
      
      if (accountCount == 0) {
        // Empty backup - no accounts to restore
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Backup is Empty',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your backup exists but contains no accounts yet.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'To backup your accounts:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStepItem(context, '1. Add accounts to the app'),
                        _buildStepItem(context, '2. Backup updates automatically'),
                        _buildStepItem(context, '3. Wait 30 minutes for cloud sync'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Show restore prompt
      if (mounted) {
        final shouldRestore = await showRestorePromptDialog(
          context,
          accountCount: accountCount,
        );
        
        if (shouldRestore != true) {
          return;
        }
        
        // Perform restore
        await _performRestore(context, autoBackupService);
      }
    } catch (e) {
      // Close checking dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Failed to check for backup: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  /// Show dialog when no backup is found
  void _showNoBackupDialog(BuildContext context, String accountId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No Backup Found',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PlatformBackupService.noBackupMessage,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      PlatformBackupService.accountIcon,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        accountId,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Possible reasons:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReasonItem(context, 'This is a new installation'),
                    _buildReasonItem(context, 'Backup was not enabled with this account'),
                    _buildReasonItem(context, 'Backup hasn\'t uploaded yet (takes 30 min)'),
                    _buildReasonItem(context, 'Backup was created with a different account'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to create a backup:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStepItem(context, '1. Enable Automatic Backup below'),
                    _buildStepItem(context, '2. Add your accounts'),
                    _buildStepItem(context, '3. Keep device charging + WiFi'),
                    _buildStepItem(context, '4. Wait 30 minutes for upload'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Each Google account has its own backup. Make sure you\'re checking the same account you used to create the backup.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAutoBackup(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Backup'),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform backup restore with loading indicator
  Future<void> _performRestore(BuildContext context, AutoBackupService autoBackupService) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Restoring your accounts...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    try {
      // Perform restore
      final restored = await autoBackupService.restoreAutoBackup();
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show result
      if (mounted) {
        if (restored) {
          CustomSnackbar.show(
            context,
            message: 'Accounts restored successfully!',
            type: SnackbarType.success,
          );
        } else {
          CustomSnackbar.show(
            context,
            message: 'Restore failed. Please try again.',
            type: SnackbarType.error,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Restore failed: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  /// Show restore dialog and perform restore (legacy - kept for compatibility)
  Future<void> _showRestoreDialog(BuildContext context) async {
    await _checkAndRestoreBackup(context);
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
          'Settings',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeletons()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Backup Section
                _buildSectionHeader('Backup', theme),
                const SizedBox(height: 8),
                // Cloud Backup Status Indicator
                Consumer<CloudSyncService>(
                  builder: (context, cloudSyncService, _) {
                    return StreamBuilder<CloudSyncStatus>(
                      stream: cloudSyncService.syncStatusStream,
                      builder: (context, snapshot) {
                        final enabled = snapshot.data == CloudSyncStatus.enabled || 
                                       snapshot.data == CloudSyncStatus.synced;
                        
                        if (enabled) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_done, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cloud Backup Available',
                                        style: AppTheme.bodyMedium(Colors.blue).copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your accounts are synced to cloud',
                                        style: AppTheme.caption(Colors.blue.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
                _buildSettingCard(
                  context,
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                  subtitle: 'Manage your account backups',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToBackup(context),
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader('About', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Review Security Guide',
                  subtitle: 'Walk through onboarding tips again',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _openSecurityGuide(),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToPrivacyPolicy(context),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title.toUpperCase(),
      style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: AppTheme.caption(theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
