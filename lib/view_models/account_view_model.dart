import 'dart:async';
import 'dart:developer' as developer;
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

  /// If [autoInit] is true (default) the view model will load accounts
  /// and start the OTP timer immediately. Tests may set autoInit=false to
  /// avoid starting timers or hitting the database during widget tests.
  AccountViewModel({
    required this.accountService,
    required this.totpService,
    bool autoInit = true,
  }) {
    debugPrint('AccountViewModel constructor called, autoInit=$autoInit');
    developer.log('AccountViewModel constructor called, autoInit=$autoInit', level: 800);
    if (autoInit) {
      debugPrint('Calling _loadAccounts from constructor');
      developer.log('Calling _loadAccounts from constructor', level: 800);
      _loadAccounts();
      _startOTPTimer();
    }
  }

  List<Account> get accounts => _accounts;
  List<AccountWithOTP> get accountsWithOTP => _accountsWithOTP;
  bool get isLoading => _isLoading;
  bool get hasAccounts => _accounts.isNotEmpty;

  Future<void> _loadAccounts() async {
    debugPrint('_loadAccounts() called');
    developer.log('_loadAccounts() called', level: 800);
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Calling accountService.getAllAccounts()');
      _accounts = await accountService.getAllAccounts();
      debugPrint('Received ${_accounts.length} accounts from accountService');
      developer.log('Loaded ${_accounts.length} accounts from database', level: 800);
      _generateOTPs();
    } catch (e) {
      debugPrint('Error in _loadAccounts: $e');
      developer.log('Error loading accounts: $e', error: e, level: 1000);
    } finally {
      _isLoading = false;
      developer.log('Finished loading. hasAccounts: $hasAccounts, accountsWithOTP: ${_accountsWithOTP.length}', level: 800);
      notifyListeners();
    }
  }

  Future<bool> addAccount(Account account) async {
    try {
      developer.log('Adding account: ${account.issuer} - ${account.accountName}', level: 800);
      await accountService.addAccount(account);
      developer.log('Account added to DB, reloading...', level: 800);
      await _loadAccounts(); // Reload to get updated list
      developer.log('Reload complete. Total accounts: ${_accounts.length}', level: 800);
      return true;
    } catch (e) {
      developer.log('Error adding account: $e', error: e, level: 1000);
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await accountService.deleteAccount(accountId);
      await _loadAccounts(); // Reload to get updated list
      return true;
    } catch (e) {
      developer.log('Error deleting account', error: e, level: 1000);
      return false;
    }
  }

  void _startOTPTimer() {
    // Only update every second for UI, but regenerate OTPs only when time step changes
    int lastTimeStep = -1;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeStep = (DateTime.now().millisecondsSinceEpoch / 1000).floor() ~/ 30;
      final secondsRemaining = totpService.getRemainingSeconds();
      
      // Only regenerate OTPs when time step changes (every 30 seconds)
      if (currentTimeStep != lastTimeStep) {
        lastTimeStep = currentTimeStep;
        _generateOTPs();
      } else {
        // Just update the seconds remaining for UI
        _updateSecondsRemaining(secondsRemaining);
      }
    });
  }

  void _generateOTPs() {
    developer.log('Generating OTPs for ${_accounts.length} accounts', level: 800);
    _accountsWithOTP = _accounts.map((account) {
      final otp = totpService.generateTOTP(account.secretKey);
      final secondsRemaining = totpService.getRemainingSeconds();
      return AccountWithOTP(
        account: account,
        otp: otp,
        secondsRemaining: secondsRemaining,
      );
    }).toList();
    developer.log('Generated ${_accountsWithOTP.length} OTPs, calling notifyListeners()', level: 800);
    notifyListeners();
  }

  void _updateSecondsRemaining(int secondsRemaining) {
    // Update only the seconds remaining without regenerating OTPs
    _accountsWithOTP = _accountsWithOTP.map((accountWithOTP) {
      return AccountWithOTP(
        account: accountWithOTP.account,
        otp: accountWithOTP.otp, // Keep existing OTP
        secondsRemaining: secondsRemaining,
      );
    }).toList();
    notifyListeners();
  }

  void refreshOTPs() {
    _generateOTPs();
  }

  Future<bool> accountExists(Account account) async {
    return await accountService.accountExists(account);
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await accountService.updateAccount(account);
      await _loadAccounts();
      return true;
    } catch (e) {
      developer.log('Error updating account', error: e, level: 1000);
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}