import 'package:flutter/material.dart';

import '../app/theme.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

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
          'Security & Privacy',
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
            // Hero Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Security Matters',
                          style: AppTheme.bodyLarge(
                            colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zero-knowledge, end-to-end encrypted',
                          style: AppTheme.bodyMedium(
                            colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Features
            _buildSectionHeader(context, 'Security Features'),
            const SizedBox(height: 12),

            _buildFeatureCard(
              context,
              icon: Icons.lock_outline,
              title: 'Device Lock Protection',
              description:
                  'Uses your device\'s built-in security (PIN, pattern, fingerprint, or face unlock) to protect app access.',
              color: colorScheme.primary,
            ),

            _buildFeatureCard(
              context,
              icon: Icons.enhanced_encryption,
              title: 'Strong Encryption',
              description:
                  'All secrets encrypted with XChaCha20-Poly1305 AEAD. Hardware-backed encryption when available.',
              color: colorScheme.tertiary,
            ),

            _buildFeatureCard(
              context,
              icon: Icons.cloud_off,
              title: 'Offline First',
              description:
                  'No internet required. All data stays on your device. No cloud sync, no data collection.',
              color: colorScheme.secondary,
            ),

            _buildFeatureCard(
              context,
              icon: Icons.timer_outlined,
              title: 'Auto-Clear Clipboard',
              description:
                  'Copied OTP codes automatically cleared after 30 seconds for security.',
              color: Colors.orange,
            ),

            _buildFeatureCard(
              context,
              icon: Icons.shield_outlined,
              title: 'Encrypted Backups',
              description:
                  'Password-protected backups with Argon2id key derivation. Your backup, your password.',
              color: Colors.green,
            ),

            _buildFeatureCard(
              context,
              icon: Icons.visibility_off,
              title: 'Privacy Protection',
              description:
                  'Screenshots blocked, screen hidden in app switcher, automatic re-lock on background.',
              color: Colors.purple,
            ),

            const SizedBox(height: 24),

            // Encryption Details
            _buildSectionHeader(context, 'Encryption Architecture'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEncryptionDetail(
                    context,
                    'Algorithm',
                    'XChaCha20-Poly1305 AEAD',
                  ),
                  const Divider(height: 24),
                  _buildEncryptionDetail(
                    context,
                    'Key Storage',
                    'Android Keystore / iOS Keychain',
                  ),
                  const Divider(height: 24),
                  _buildEncryptionDetail(
                    context,
                    'Backup KDF',
                    'Argon2id (memory-hard)',
                  ),
                  const Divider(height: 24),
                  _buildEncryptionDetail(
                    context,
                    'Hardware Backing',
                    'Automatic when available',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Best Practices
            _buildSectionHeader(context, 'Security Best Practices'),
            const SizedBox(height: 12),

            _buildBestPracticeItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Enable Device Lock',
              description:
                  'Use a strong PIN, pattern, or biometric lock on your device.',
            ),

            _buildBestPracticeItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Regular Backups',
              description:
                  'Create encrypted backups regularly and store them securely.',
            ),

            _buildBestPracticeItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Strong Backup Password',
              description:
                  'Use a unique, strong password (12+ characters) for backups.',
            ),

            _buildBestPracticeItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Verify Accounts',
              description:
                  'Test imported accounts before removing from original app.',
            ),

            _buildBestPracticeItem(
              context,
              icon: Icons.check_circle_outline,
              title: 'Keep App Updated',
              description:
                  'Install updates promptly for latest security improvements.',
            ),

            const SizedBox(height: 24),

            // What We Don't Do
            _buildSectionHeader(context, 'What We DON\'T Do'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildDontItem(context, '✗ No data collection'),
                  _buildDontItem(context, '✗ No analytics or tracking'),
                  _buildDontItem(context, '✗ No third-party services'),
                  _buildDontItem(context, '✗ No cloud storage'),
                  _buildDontItem(context, '✗ No ads or monetization'),
                  _buildDontItem(context, '✗ No account required'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Transparency
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.code, color: colorScheme.tertiary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open & Transparent',
                          style: AppTheme.bodyLarge(
                            colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Our security architecture is transparent and can be verified through code review.',
                          style: AppTheme.bodyMedium(
                            colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact
            Center(
              child: Column(
                children: [
                  Text(
                    'Security Concerns?',
                    style: AppTheme.bodyLarge(
                      colorScheme.onSurface,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report vulnerabilities to:',
                    style: AppTheme.bodyMedium(
                      colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'support@cdac.in',
                      style: AppTheme.bodyMedium(
                        colorScheme.primary,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: AppTheme.bodyLarge(
        colorScheme.onSurface,
      ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium(
                    colorScheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.caption(
                    colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionDetail(
    BuildContext context,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium(
            colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium(
            colorScheme.onSurface,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBestPracticeItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium(
                    colorScheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTheme.caption(
                    colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDontItem(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.block, color: colorScheme.error, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium(colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
