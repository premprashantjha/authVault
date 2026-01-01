import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../app/theme.dart';
import '../services/backup_service.dart';
import '../services/encryption_service.dart';
import '../services/integrity_service.dart';
import '../services/database_service.dart';
import '../services/account_service.dart';
import '../widgets/animated_button.dart';
import '../widgets/skeleton.dart';
import '../widgets/custom_snackbar.dart';
import 'onboarding_screen.dart';
import 'backup_screen.dart';
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
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 4),
        Skeleton(height: 64),
        SizedBox(height: 12),
        Skeleton(height: 64),
        SizedBox(height: 24),
        Skeleton(height: 64),
      ],
    );
  }

  void _navigateToBackup(BuildContext context) {
    // Create backup service with dependencies
    final encryptionService = EncryptionService();
    final integrityService = IntegrityService();
    final databaseService = DatabaseService(
      encryptionService: encryptionService,
      integrityService: integrityService,
    );
    final accountService = AccountService(databaseService: databaseService);
    final backupService = BackupService(accountService: accountService);
    
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
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
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
                // Backup & Recovery Section
                _buildSectionHeader('Data Management', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Encrypted backups of your accounts',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToBackup(context),
                ),
                const SizedBox(height: 24),

                // Guides & Reference Section
                _buildSectionHeader('Guides & Reference', theme),
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
                const SizedBox(height: 24),

                // Legal Section
                _buildSectionHeader('Legal', theme),
                const SizedBox(height: 8),
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
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader('About', theme),
                const SizedBox(height: 8),
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
