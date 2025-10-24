import 'dart:async';
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/totp_service.dart';

class AccountViewModel with ChangeNotifier {
  final AccountService accountService;
  final TOTPService totpService;
  
  List<Account> _accounts = [];
  List<AccountWithOTP> _accountsWithOTP = [];
  Timer? _timer;
  bool _isLoading = false;

  AccountViewModel({
    required this.accountService,
    required this.totpService,
  }) {
    _loadAccounts();
    _startOTPTimer();
  }

  List<Account> get accounts => _accounts;
  List<AccountWithOTP> get accountsWithOTP => _accountsWithOTP;
  bool get isLoading => _isLoading;
  bool get hasAccounts => _accounts.isNotEmpty;

  Future<void> _loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await accountService.getAllAccounts();
      _generateOTPs();
    } catch (e) {
      print('Error loading accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAccount(Account account) async {
    try {
      await accountService.addAccount(account);
      await _loadAccounts(); // Reload to get updated list
      return true;
    } catch (e) {
      print('Error adding account: $e');
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await accountService.deleteAccount(accountId);
      await _loadAccounts(); // Reload to get updated list
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }

  void _startOTPTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _generateOTPs();
    });
  }

  void _generateOTPs() {
    _accountsWithOTP = _accounts.map((account) {
      final otp = totpService.generateTOTP(account.secretKey);
      final secondsRemaining = totpService.getRemainingSeconds();
      return AccountWithOTP(
        account: account,
        otp: otp,
        secondsRemaining: secondsRemaining,
      );
    }).toList();
    notifyListeners();
  }

  void refreshOTPs() {
    _generateOTPs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}