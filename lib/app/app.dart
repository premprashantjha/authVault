import 'package:authenticator/view/auth_wrapper.dart';
import 'package:authenticator/view/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

class AuthenticatorApp extends StatelessWidget {
  final bool showOnboarding;
  final VoidCallback onOnboardingFinished;

  const AuthenticatorApp({
    super.key,
    required this.showOnboarding,
    required this.onOnboardingFinished,
  });

  @override
  Widget build(BuildContext context) {
    // Always use system theme for seamless native/Flutter splash transition
    return MaterialApp(
      title: 'Authenticator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Always follow system theme
      home: showOnboarding
          ? OnboardingScreen(
              onFinished: onOnboardingFinished,
              allowSkip: true,
            )
          : const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}