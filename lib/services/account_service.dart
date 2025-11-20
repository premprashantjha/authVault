import 'package:flutter/foundation.dart';
import '../models/account.dart';
import 'database_service.dart';

/// Service for managing accounts using encrypted database storage
class AccountService {
  final DatabaseService databaseService;

  AccountService({required this.databaseService});

  Future<List<Account>> getAllAccounts() async {
    try {
      final accounts = await databaseService.getAllAccounts();
      return accounts;
    } catch (e) {
      debugPrint('Error loading accounts: $e');
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
      debugPrint('Account added successfully');
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await databaseService.deleteAccount(accountId);
    } catch (e) {
      debugPrint('AccountService: Error deleting account: $e');
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
      debugPrint('AccountService: Error checking account existence: $e');
      return false;
    }
  }

  Future<void> updateAccount(Account updatedAccount) async {
    try {
      await databaseService.updateAccount(updatedAccount);
    } catch (e) {
      debugPrint('AccountService: Error updating account: $e');
      throw Exception('Failed to update account');
    }
  }
}