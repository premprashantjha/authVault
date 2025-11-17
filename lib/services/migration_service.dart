import 'dart:convert';
import 'dart:developer' as developer;
import '../models/account.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

/// Service to migrate data from old JSON storage to new database
class MigrationService {
  final SecureStorageService secureStorage;
  final DatabaseService databaseService;
  static const String _accountsKey = 'authenticator_accounts';
  static const String _migrationKey = 'authenticator_migrated';

  MigrationService({
    required this.secureStorage,
    required this.databaseService,
  });

  /// Check if migration has been completed
  Future<bool> isMigrated() async {
    try {
      final migrated = await secureStorage.getSecret(_migrationKey);
      return migrated == 'true';
    } catch (e) {
      developer.log('Error checking migration status', error: e, level: 1000);
      return false;
    }
  }

  /// Migrate accounts from JSON storage to database
  Future<bool> migrateAccounts() async {
    try {
      developer.log('Starting migration check...', name: 'Migration');
      
      // Check if already migrated
      if (await isMigrated()) {
        developer.log('Migration already completed', name: 'Migration');
        return true;
      }

      developer.log('Checking for old data in secure storage...', name: 'Migration');
      // Check if old data exists
      final accountsJson = await secureStorage.getSecret(_accountsKey);
      if (accountsJson == null || accountsJson.isEmpty) {
        // No old data to migrate, mark as migrated
        developer.log('No old data found, marking as migrated', name: 'Migration');
        await secureStorage.saveSecret(_migrationKey, 'true');
        return true;
      }

      developer.log('Found old data, parsing...', name: 'Migration');
      // Parse old JSON data
      final List<dynamic> jsonList = json.decode(accountsJson);
      final accounts = jsonList.map((json) => Account.fromMap(json)).toList();

      developer.log('Migrating ${accounts.length} accounts to database...', name: 'Migration');
      // Migrate to database
      int migrated = 0;
      for (final account in accounts) {
        try {
          await databaseService.addAccount(account);
          migrated++;
          developer.log('Migrated: ${account.issuer} - ${account.accountName}', name: 'Migration');
        } catch (e) {
          // Account might already exist, skip
          developer.log('Skipping duplicate account during migration: ${account.issuer}', name: 'Migration');
        }
      }

      // Mark as migrated
      await secureStorage.saveSecret(_migrationKey, 'true');

      developer.log('Migration completed: $migrated/${accounts.length} accounts migrated', name: 'Migration');
      return true;
    } catch (e) {
      developer.log('Error during migration', error: e, level: 1000, name: 'Migration');
      return false;
    }
  }
}

