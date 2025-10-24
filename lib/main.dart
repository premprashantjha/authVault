import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'view_models/account_view_model.dart';
import 'services/account_service.dart';
import 'services/totp_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final secureStorage = SecureStorageService();
  final accountService = AccountService(secureStorage: secureStorage);
  final totpService = TOTPService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AccountViewModel(
            accountService: accountService,
            totpService: totpService,
          ),
        ),
      ],
      child: const AuthVaultApp(),
    ),
  );
}