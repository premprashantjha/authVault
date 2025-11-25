import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'app/theme.dart';
import 'view_models/account_view_model.dart';
import 'services/account_service.dart';
import 'services/totp_service.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/migration_service.dart';
import 'services/encryption_service.dart';
import 'services/security_service.dart';
import 'services/integrity_service.dart';
import 'view/splash_screen.dart';

// Performance monitoring for startup optimization
class _StartupProfiler {
  static final Stopwatch _stopwatch = Stopwatch();
  static final Map<String, int> _phases = {};
  
  static void start() {
    _stopwatch.start();
    _log('App started');
  }
  
  static void mark(String phase) {
    final elapsed = _stopwatch.elapsedMilliseconds;
    _phases[phase] = elapsed;
    _log('$phase: ${elapsed}ms');
  }
  
  static void _log(String message) {
    // Debug logging disabled for production
    // if (kDebugMode) {
    //   debugPrint('🚀 [STARTUP] $message');
    // }
  }
  
  static void printSummary() {
    // Summary disabled for production
    // if (!kDebugMode) return;
    // _log('\n═══════ STARTUP SUMMARY ═══════');
    // ...
  }
}

void main() {
  _StartupProfiler.start();
  
  // Just ensure Flutter is initialized and run the app immediately
  WidgetsFlutterBinding.ensureInitialized();
  _StartupProfiler.mark('Flutter binding initialized');
  
  runApp(const SplashApp());
  _StartupProfiler.mark('runApp called');
}

class SplashApp extends StatefulWidget {
  const SplashApp({super.key});

  @override
  State<SplashApp> createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> {
  bool _isInitialized = false;
  bool _animationComplete = false;
  bool _hasSecurityWarning = false;
  String _securityMessage = '';
  AccountViewModel? _accountViewModel;
  bool _shouldShowOnboarding = false;
  late SecureStorageService _secureStorage;
  
  // Lazy-loaded services
  SecurityService? _securityService;
  MigrationService? _migrationService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _StartupProfiler.mark('Init started');
    
    // Minimal synchronous initialization - just what's needed to show the app
    _secureStorage = SecureStorageService();
    _StartupProfiler.mark('SecureStorage created');
    
    // Check onboarding status quickly (synchronous read from secure storage)
    final onboardingSeen = await _secureStorage.getSecret('onboarding_seen');
    _shouldShowOnboarding = onboardingSeen != 'true';
    _StartupProfiler.mark('Onboarding status checked');
    
    // Create minimal services to show app immediately
    final encryptionService = EncryptionService(secureStorage: _secureStorage);
    final integrityService = IntegrityService(secureStorage: _secureStorage);
    final databaseService = DatabaseService(
      encryptionService: encryptionService,
      integrityService: integrityService,
    );
    _StartupProfiler.mark('Services created');
    
    // Initialize database (required) - this is the main bottleneck
    await databaseService.database;
    _StartupProfiler.mark('Database initialized');
    
    final accountService = AccountService(databaseService: databaseService);
    final totpService = TOTPService();
    
    _accountViewModel = AccountViewModel(
      accountService: accountService,
      totpService: totpService,
    );
    _StartupProfiler.mark('ViewModels created');
    
    // Mark initialization as complete (but wait for animation to finish before showing main app)
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    _StartupProfiler.mark('Init complete, waiting for animation');
    
    // Defer ALL heavy operations to background (non-blocking)
    _performBackgroundTasks(databaseService);
  }
  
  void _performBackgroundTasks(DatabaseService databaseService) async {
    _StartupProfiler.mark('Background tasks started');
    
    // Run all heavy operations in background after app is showing
    // Use lazy loading to only create services when needed
    
    // Security check (lazy-loaded)
    _securityService ??= SecurityService();
    final isSecure = await _securityService!.isDeviceSecure();
    _StartupProfiler.mark('Security check complete');
    
    if (!isSecure && !kDebugMode) {
      final warning = await _securityService!.getSecurityWarning();
      if (mounted) {
        setState(() {
          _hasSecurityWarning = true;
          _securityMessage = warning;
        });
      }
    }
    
    // Database integrity check
    final isIntact = await databaseService.verifyIntegrity();
    _StartupProfiler.mark('Integrity check complete');
    
    // Integrity check runs silently in production
    if (!isIntact && kDebugMode) {
      debugPrint('Warning: Database integrity check failed');
    }
    
    // One-time cleanup
    final cleanupDone = await _secureStorage.getSecret('encryption_cleanup_done');
    if (cleanupDone == null) {
      try {
        await databaseService.clearAllAccounts();
        await _secureStorage.saveSecret('encryption_cleanup_done', 'true');
        _StartupProfiler.mark('Cleanup complete');
      } catch (e) {
        // Cleanup errors are non-critical
        debugPrint('Error during cleanup: $e');
      }
    }
    
    // Migration from old storage (lazy-loaded)
    _migrationService ??= MigrationService(
      secureStorage: _secureStorage,
      databaseService: databaseService,
    );
    await _migrationService!.migrateAccounts();
    _StartupProfiler.mark('Migration complete');
    
    _StartupProfiler.printSummary();
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
      child: !_isInitialized || !_animationComplete
          ? MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system, // Always follow system theme
              home: SplashScreen(
                onInitializationComplete: () {
                  // Animation complete, now transition to main app
                  if (mounted && _isInitialized) {
                    setState(() {
                      _animationComplete = true;
                    });
                  }
                },
              ),
            )
          : MultiProvider(
              key: const ValueKey('main'),
              providers: [
                ChangeNotifierProvider<AccountViewModel>.value(value: _accountViewModel!),
              ],
              child: AuthenticatorApp(
                showOnboarding: _shouldShowOnboarding,
                onOnboardingFinished: _handleOnboardingComplete,
              ),
            ),
    );
  }

  Future<void> _handleOnboardingComplete() async {
    await _secureStorage.saveSecret('onboarding_seen', 'true');
    if (mounted) {
      setState(() {
        _shouldShowOnboarding = false;
      });
    }
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