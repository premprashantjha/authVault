import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../app/theme.dart';
import '../../widgets/animated/animated_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddAccount;

  const EmptyStateWidget({
    super.key,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
            child: Column(
              mainAxisAlignment: AppTheme.mainAxisCenter,
              children: [
                // Lottie animation showing QR scan interaction
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.asset(
                    'assets/images/AuthenticatorWelcomeScreen.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No 2FA Accounts',
                  style: AppTheme.headlineLarge(theme.colorScheme.onSurface).copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: AppTheme.textAlignCenter,
                ),
                const SizedBox(height: 12),
                Text(
                  'Secure your accounts with two-factor authentication',
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: AppTheme.textAlignCenter,
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  onTap: onAddAccount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Your First Account',
                          style: AppTheme.bodyLarge(theme.colorScheme.onPrimary).copyWith(
                            fontWeight: AppTheme.weightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
