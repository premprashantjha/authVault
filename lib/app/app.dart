import 'package:authvault_poc/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

class AuthVaultApp extends StatelessWidget {
  const AuthVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuthVault',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}