import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'view_models/account_view_model.dart';
import 'services/account_service.dart';
import 'services/totp_service.dart';
import 'services/theme_service.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final secureStorage = SecureStorageService();
  final databaseService = DatabaseService();
  
  // CRITICAL: Ensure database is initialized before anything else
  await databaseService.database;
  debugPrint('Database initialized');
  
  // Run migration from old JSON storage to new database
  final migrationService = MigrationService(
    secureStorage: secureStorage,
    databaseService: databaseService,
  );
  await migrationService.migrateAccounts();
  debugPrint('Migration completed');
  
  // Now create services that depend on the database
  final accountService = AccountService(databaseService: databaseService);
  final totpService = TOTPService();
  final themeService = ThemeService();
  
  // Create the AccountViewModel after all dependencies are ready
  debugPrint('Creating AccountViewModel with all dependencies ready');
  debugPrint('About to call AccountViewModel constructor...');
  try {
    final accountViewModel = AccountViewModel(
      accountService: accountService,
      totpService: totpService,
    );
    debugPrint('AccountViewModel constructor completed');
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => themeService),
          ChangeNotifierProvider.value(value: accountViewModel),
        ],
        child: const AuthenticatorApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error creating AccountViewModel: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}