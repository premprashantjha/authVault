import 'package:authenticator/view/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../services/theme_service.dart';

class AuthenticatorApp extends StatelessWidget {
  const AuthenticatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Authenticator',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}