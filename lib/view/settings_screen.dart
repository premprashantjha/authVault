import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_constants.dart';
import '../app/theme.dart';
import '../services/backup_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/skeleton.dart';
import 'backup_screen.dart';
import 'export_accounts_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import 'qr_import_screen.dart';
import 'terms_of_service_screen.dart';

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
        SizedBox(
          height: AppConstants.getResponsiveSpacing(context, xs: 2.0, sm: 4.0),
        ),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
        SizedBox(height: AppConstants.getResponsiveSpacing(context)),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
        SizedBox(height: AppConstants.getResponsiveSpacing(context, lg: 24.0)),
        Skeleton(height: AppConstants.getResponsiveButtonHeight(context) + 16),
      ],
    );
  }

  void _navigateToBackup(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final backupService = BackupService(
      accountService: accountViewModel.accountService,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupScreen(backupService: backupService),
      ),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _navigateToTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  void _navigateToImport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrImportScreen()),
    );
  }

  void _navigateToExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportAccountsScreen()),
    );
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
                // Transfer & Share Section
                _buildSectionHeader('Transfer & Share', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.qr_code_2,
                  title: 'Export to QR Code',
                  subtitle: 'Share accounts with another device',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToExport(context),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  context,
                  icon: Icons.download_rounded,
                  title: 'Import from Other Apps',
                  subtitle:
                      'Transfer from Google Authenticator, Authy, and more',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToImport(context),
                ),
                const SizedBox(height: 24),

                // Backup Section
                _buildSectionHeader('Backup', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                  subtitle: 'Create and manage encrypted backups',
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
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'App usage terms and conditions',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToTermsOfService(context),
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
      style: AppTheme.caption(
        theme.colorScheme.onSurface,
      ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge(
                        theme.colorScheme.onSurface,
                      ).copyWith(fontWeight: FontWeight.w600),
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
