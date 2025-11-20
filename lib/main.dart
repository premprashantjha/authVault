import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'view_models/account_view_model.dart';
import 'services/account_service.dart';
import 'services/totp_service.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/migration_service.dart';
import 'services/encryption_service.dart';
import 'services/security_service.dart';
import 'view/splash_screen.dart';

void main() {
  // Just ensure Flutter is initialized and run the app immediately
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatefulWidget {
  const SplashApp({super.key});

  @override
  State<SplashApp> createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> {
  bool _isInitialized = false;
  bool _hasSecurityWarning = false;
  String _securityMessage = '';
  late AccountViewModel _accountViewModel;
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Perform security checks first
    final securityService = SecurityService();
    final isSecure = await securityService.isDeviceSecure();
    
    if (!isSecure && !kDebugMode) {
      // In production, show warning for insecure devices
      final warning = await securityService.getSecurityWarning();
      if (mounted) {
        setState(() {
          _hasSecurityWarning = true;
          _securityMessage = warning;
        });
      }
      // Still allow app to run, but with warning
    }
    
    // Perform initialization while splash is showing
    await _performInitialization();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _performInitialization() async {
    // Initialize services
    final secureStorage = SecureStorageService();
    final encryptionService = EncryptionService(secureStorage: secureStorage);
    final databaseService = DatabaseService(encryptionService: encryptionService);
    
    // CRITICAL: Ensure database is initialized before anything else
    await databaseService.database;
    
    // One-time cleanup: Check if we need to clear old encrypted data
    final cleanupDone = await secureStorage.getSecret('encryption_cleanup_done');
    if (cleanupDone == null) {
      try {
        await databaseService.clearAllAccounts();
        await secureStorage.saveSecret('encryption_cleanup_done', 'true');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error during cleanup: $e');
        }
      }
    }
    
    // Run migration from old JSON storage to new database
    final migrationService = MigrationService(
      secureStorage: secureStorage,
      databaseService: databaseService,
    );
    await migrationService.migrateAccounts();
    
    // Now create services that depend on the database
    final accountService = AccountService(databaseService: databaseService);
    final totpService = TOTPService();
    _themeService = ThemeService();
    
    // Create the AccountViewModel after all dependencies are ready
    _accountViewModel = AccountViewModel(
      accountService: accountService,
      totpService: totpService,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show security warning dialog if needed
    if (_hasSecurityWarning && _isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSecurityWarningDialog();
      });
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: !_isInitialized
          ? MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              home: SplashScreen(
                onInitializationComplete: () {
                  // Initialization already done, just transition
                },
              ),
            )
          : MultiProvider(
              key: const ValueKey('main'),
              providers: [
                ChangeNotifierProvider<ThemeService>.value(value: _themeService),
                ChangeNotifierProvider<AccountViewModel>.value(value: _accountViewModel),
              ],
              child: const AuthenticatorApp(),
            ),
    );
  }

  void _showSecurityWarningDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Security Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_securityMessage),
            const SizedBox(height: 16),
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
              Navigator.of(context).pop();
              setState(() => _hasSecurityWarning = false);
            },
            child: const Text('I Understand the Risks'),
          ),
        ],
      ),
    );
  }
}