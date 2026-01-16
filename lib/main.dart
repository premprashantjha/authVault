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
import 'services/auto_backup_service.dart';

void main() {
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
  AccountViewModel? _accountViewModel;
  bool _shouldShowOnboarding = false;
  bool _hasBackupAvailable = false; // Track if backup is available
  late SecureStorageService _secureStorage;
  
  SecurityService? _securityService;
  MigrationService? _migrationService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _secureStorage = SecureStorageService();
    
    final onboardingSeen = await _secureStorage.getSecret('onboarding_seen');
    _shouldShowOnboarding = onboardingSeen != 'true';
    
    final encryptionService = EncryptionService(secureStorage: _secureStorage);
    final integrityService = IntegrityService(secureStorage: _secureStorage);
    final databaseService = DatabaseService(
      encryptionService: encryptionService,
      integrityService: integrityService,
    );
    
    await databaseService.database;
    
    final accountService = AccountService(databaseService: databaseService);
    final totpService = TOTPService();
    
    _accountViewModel = AccountViewModel(
      accountService: accountService,
      totpService: totpService,
    );
    
    // Show UI immediately - check backups in background
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    
    // Check backups asynchronously (don't block UI)
    _checkBackupsAsync(accountService);
    
    // Perform other background tasks
    _performBackgroundTasks(databaseService);
  }
  
  /// Check backups asynchronously without blocking UI
  Future<void> _checkBackupsAsync(AccountService accountService) async {
    try {
      final hasBackup = await _checkBackupAvailable(accountService);
      
      if (mounted) {
        setState(() {
          _hasBackupAvailable = hasBackup;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking backups: $e');
      }
    }
  }
  
  /// Check if backup is available for restore
  Future<bool> _checkBackupAvailable(AccountService accountService) async {
    try {
      final autoBackupService = AutoBackupService(
        accountService: accountService,
      );
      
      // Check if backup file exists
      final hasBackup = await autoBackupService.hasBackup();
      
      if (hasBackup && kDebugMode) {
        debugPrint('✓ Backup file detected - will prompt user to restore');
      }
      
      return hasBackup;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking backup: $e');
      }
      return false;
    }
  }
  
  void _performBackgroundTasks(DatabaseService databaseService) async {
    // TODO: Enable security check before production release
    // _securityService ??= SecurityService();
    // final isSecure = await _securityService!.isDeviceSecure();
    // if (!isSecure && !kDebugMode) {
    //   final warning = await _securityService!.getSecurityWarning();
    //   if (mounted) {
    //     setState(() {
    //       _hasSecurityWarning = true;
    //       _securityMessage = warning;
    //     });
    //   }
    // }
    
    final isIntact = await databaseService.verifyIntegrity();
    
    if (!isIntact && kDebugMode) {
      debugPrint('Warning: Database integrity check failed');
    }
    
    final cleanupDone = await _secureStorage.getSecret('encryption_cleanup_done');
    if (cleanupDone == null) {
      try {
        await databaseService.clearAllAccounts();
        await _secureStorage.saveSecret('encryption_cleanup_done', 'true');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error during cleanup: $e');
        }
      }
    }
    
    _migrationService ??= MigrationService(
      secureStorage: _secureStorage,
      databaseService: databaseService,
    );
    await _migrationService!.migrateAccounts();
  }

  @override
  Widget build(BuildContext context) {
    // Show authenticating screen while initializing - no blank loading spinner
    if (!_isInitialized) {
      return MaterialApp(
        key: const ValueKey('loading'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _buildAuthenticatingScreen(),
      );
    }

    return MultiProvider(
      key: const ValueKey('main'),
      providers: [
        ChangeNotifierProvider<AccountViewModel>.value(value: _accountViewModel!),
      ],
      child: AuthenticatorAppWithDialog(
        showOnboarding: _shouldShowOnboarding,
        onOnboardingFinished: _handleOnboardingComplete,
        hasSecurityWarning: _hasSecurityWarning,
        securityMessage: _securityMessage,
        onSecurityWarningDismissed: () {
          setState(() => _hasSecurityWarning = false);
        },
        hasBackupAvailable: _hasBackupAvailable,
      ),
    );
  }

  /// Build the authenticating screen shown during initialization
  Widget _buildAuthenticatingScreen() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Watermark logo at bottom
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      'assets/images/CDAC_Logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.primary // Use theme primary color
                            : Colors.transparent,
                        theme.brightness == Brightness.dark
                            ? BlendMode.srcATop
                            : BlendMode.dst,
                      ),
                      child: Image.asset(
                        'assets/images/Logo_cdac.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Authenticating...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
}