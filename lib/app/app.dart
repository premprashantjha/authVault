import 'package:authenticator/view/auth_wrapper.dart';
import 'package:authenticator/view/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_constants.dart';

class AuthenticatorApp extends StatelessWidget {
  final bool showOnboarding;
  final VoidCallback onOnboardingFinished;
  final bool hasBackupAvailable;

  const AuthenticatorApp({
    super.key,
    required this.showOnboarding,
    required this.onOnboardingFinished,
    this.hasBackupAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authenticator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: showOnboarding
          ? OnboardingScreen(
              onFinished: onOnboardingFinished,
              allowSkip: true,
              hasBackupAvailable: hasBackupAvailable,
            )
          : const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply responsive scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              AppConstants.isSmallScreen(context) ? 0.9 : 1.0,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

class AuthenticatorAppWithDialog extends StatefulWidget {
  final bool showOnboarding;
  final VoidCallback onOnboardingFinished;
  final bool hasSecurityWarning;
  final String securityMessage;
  final VoidCallback onSecurityWarningDismissed;
  final bool hasBackupAvailable;
  final bool hasCloudBackup;

  const AuthenticatorAppWithDialog({
    super.key,
    required this.showOnboarding,
    required this.onOnboardingFinished,
    required this.hasSecurityWarning,
    required this.securityMessage,
    required this.onSecurityWarningDismissed,
    this.hasBackupAvailable = false,
    this.hasCloudBackup = false,
  });

  @override
  State<AuthenticatorAppWithDialog> createState() => _AuthenticatorAppWithDialogState();
}

class _AuthenticatorAppWithDialogState extends State<AuthenticatorAppWithDialog> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authenticator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply responsive scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              AppConstants.isSmallScreen(context) ? 0.9 : 1.0,
            ),
          ),
          child: child!,
        );
      },
      home: Builder(
        builder: (context) {
          // Show security warning dialog after first frame
          if (widget.hasSecurityWarning && !_dialogShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_dialogShown) {
                _dialogShown = true;
                _showSecurityWarningDialog(context);
              }
            });
          }

          return widget.showOnboarding
              ? OnboardingScreen(
                  onFinished: widget.onOnboardingFinished,
                  allowSkip: true,
                  hasBackupAvailable: widget.hasBackupAvailable,
                  hasCloudBackup: widget.hasCloudBackup,
                )
              : const AuthWrapper();
        },
      ),
    );
  }

  void _showSecurityWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            SizedBox(width: AppConstants.spaceSm),
            const Text('Security Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.securityMessage),
            SizedBox(height: AppConstants.spaceMd),
            const Text(
              'Running this app on a compromised device may expose your authentication codes. '
              'We recommend using a secure device for 2FA.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onSecurityWarningDismissed();
            },
            child: const Text('I Understand the Risks'),
          ),
        ],
      ),
    );
  }
}
