import 'package:flutter/material.dart';
import '../app/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
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
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last Updated: December 1, 2025',
                      style: AppTheme.bodyMedium(colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              title: 'Introduction',
              content:
                  'Welcome to Authenticator. We are committed to protecting your privacy and ensuring the security of your data. This Privacy Policy explains how we handle your information when you use our app.',
            ),

            // Data Collection
            _buildSection(
              context,
              title: 'Data Collection',
              content:
                  'Authenticator is designed with privacy as a core principle. We do NOT collect, transmit, or store any of your personal data on external servers.',
            ),

            _buildBulletPoint(
              context,
              'Account Information: All your 2FA accounts and secrets are stored locally on your device only.',
            ),
            _buildBulletPoint(
              context,
              'Backup Files: When you create a backup, it is encrypted and stored locally. We never access or transmit your backup files.',
            ),
            _buildBulletPoint(
              context,
              'Usage Data: We do not collect any analytics, usage statistics, or telemetry data.',
            ),
            _buildBulletPoint(
              context,
              'Personal Information: We do not collect names, email addresses, phone numbers, or any other personal information.',
            ),

            const SizedBox(height: 16),

            // Data Storage
            _buildSection(
              context,
              title: 'Data Storage',
              content:
                  'All data is stored locally on your device using industry-standard encryption:',
            ),

            _buildBulletPoint(
              context,
              'Local Database: Your accounts are stored in an encrypted database on your device.',
            ),
            _buildBulletPoint(
              context,
              'Secure Storage: Sensitive data uses secure storage with hardware-backed encryption when available.',
            ),
            _buildBulletPoint(
              context,
              'Backup Encryption: Backups are encrypted with your chosen password using strong encryption.',
            ),

            const SizedBox(height: 16),

            // Permissions
            _buildSection(
              context,
              title: 'Permissions',
              content: 'The app requests the following permissions:',
            ),

            _buildPermissionItem(
              context,
              icon: Icons.camera_alt,
              title: 'Camera',
              description: 'Used only to scan QR codes when adding new accounts. Never used for any other purpose.',
            ),
            _buildPermissionItem(
              context,
              icon: Icons.fingerprint,
              title: 'Device Security',
              description: 'Uses your device\'s built-in lock (PIN, pattern, or biometric) to protect app access.',
            ),
            _buildPermissionItem(
              context,
              icon: Icons.folder,
              title: 'Storage',
              description: 'Used to save and restore encrypted backup files. All files remain on your device.',
            ),

            const SizedBox(height: 16),

            // Data Security
            _buildSection(
              context,
              title: 'Data Security',
              content: 'We implement multiple layers of security to protect your data:',
            ),

            _buildBulletPoint(
              context,
              'Encryption at Rest: All secrets are encrypted in the local database.',
            ),
            _buildBulletPoint(
              context,
              'Device Lock Protection: Uses your device security (PIN/pattern/biometric) to protect app access.',
            ),
            _buildBulletPoint(
              context,
              'Clipboard Security: Copied OTP codes are automatically cleared after 30 seconds.',
            ),
            _buildBulletPoint(
              context,
              'No Cloud Backup: System backups are disabled to prevent unencrypted data from being backed up to cloud services.',
            ),

            const SizedBox(height: 16),

            // Third-Party Services
            _buildSection(
              context,
              title: 'Third-Party Services',
              content:
                  'Authenticator does NOT use any third-party services, analytics, or advertising networks. The app functions completely offline and does not require an internet connection.',
            ),

            // Data Sharing
            _buildSection(
              context,
              title: 'Data Sharing',
              content:
                  'We do NOT share, sell, rent, or trade your data with anyone. Your data never leaves your device unless you explicitly export a backup file and share it yourself.',
            ),

            // Your Rights
            _buildSection(
              context,
              title: 'Your Rights',
              content: 'You have complete control over your data:',
            ),

            _buildBulletPoint(
              context,
              'Access: All your data is accessible within the app at any time.',
            ),
            _buildBulletPoint(
              context,
              'Export: You can create encrypted backups of your data at any time.',
            ),
            _buildBulletPoint(
              context,
              'Delete: You can delete individual accounts or uninstall the app to remove all data.',
            ),
            _buildBulletPoint(
              context,
              'Portability: Backup files can be restored on any device with the app installed.',
            ),

            const SizedBox(height: 16),

            // Children's Privacy
            _buildSection(
              context,
              title: "Children's Privacy",
              content:
                  'Our app does not collect any personal information from anyone, including children under 13. The app is suitable for all ages.',
            ),

            // Changes to Privacy Policy
            _buildSection(
              context,
              title: 'Changes to This Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time. Any changes will be reflected in the app with an updated "Last Updated" date. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),

            // Open Source
            _buildSection(
              context,
              title: 'Transparency',
              content:
                  'We are committed to transparency in how we handle your data. The app\'s security features can be verified through code review.',
            ),

            // Contact
            _buildSection(
              context,
              title: 'Contact Us',
              content:
                  'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:',
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'support@cdac.in',
                          style: AppTheme.bodyMedium(colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.business_outlined, color: colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Centre for Development of Advanced Computing (C-DAC)',
                          style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: colorScheme.tertiary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Privacy Summary',
                        style: AppTheme.bodyLarge(colorScheme.onSurface).copyWith(
                          fontWeight: AppTheme.weightBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(context, '✓ No data collection'),
                  _buildSummaryItem(context, '✓ No internet required'),
                  _buildSummaryItem(context, '✓ No third-party services'),
                  _buildSummaryItem(context, '✓ Strong encryption'),
                  _buildSummaryItem(context, '✓ Transparent & secure'),
                  _buildSummaryItem(context, '✓ Your data stays on your device'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge(colorScheme.onSurface).copyWith(
              fontWeight: AppTheme.weightBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
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
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.9)),
      ),
    );
  }
}
