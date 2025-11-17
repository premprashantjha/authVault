import 'dart:developer' as developer;
import '../models/account.dart';
import 'database_service.dart';

/// Service for managing accounts using encrypted database storage
class AccountService {
  final DatabaseService databaseService;

  AccountService({required this.databaseService});

  Future<List<Account>> getAllAccounts() async {
    try {
      developer.log('AccountService: Calling databaseService.getAllAccounts()', level: 800);
      final accounts = await databaseService.getAllAccounts();
      developer.log('AccountService: Got ${accounts.length} accounts from database', level: 800);
      return accounts;
    } catch (e) {
      developer.log('Error loading accounts', error: e, level: 1000);
      return [];
    }
  }

  Future<void> addAccount(Account newAccount) async {
    try {
      // Check for duplicates using database query (more efficient)
      final exists = await databaseService.accountExists(
        newAccount.issuer,
        newAccount.accountName,
      );
      
      if (exists) {
        throw Exception('Account already exists');
      }

      await databaseService.addAccount(newAccount);
    } catch (e) {
      developer.log('Error adding account', error: e, level: 1000);
      rethrow;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await databaseService.deleteAccount(accountId);
    } catch (e) {
      developer.log('Error deleting account', error: e, level: 1000);
      throw Exception('Failed to delete account');
    }
  }

  Future<bool> accountExists(Account account) async {
    try {
      return await databaseService.accountExists(
        account.issuer,
        account.accountName,
      );
    } catch (e) {
      developer.log('Error checking account existence', error: e, level: 1000);
      return false;
    }
  }

  Future<void> updateAccount(Account updatedAccount) async {
    try {
      await databaseService.updateAccount(updatedAccount);
    } catch (e) {
      developer.log('Error updating account', error: e, level: 1000);
      throw Exception('Failed to update account');
    }
  }
}