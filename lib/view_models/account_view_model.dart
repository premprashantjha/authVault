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
    if (autoInit) {
      _loadAccounts();
      _startOTPTimer();
    }
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
      debugPrint('Error loading accounts: $e');
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
      debugPrint('Error adding account: $e');
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
    _timer?.cancel();
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

  Future<void> reloadAfterUnlock() async {
    if (_timer == null) {
      _startOTPTimer();
    }
    await _loadAccounts();
  }

  void purgeSensitiveData() {
    _timer?.cancel();
    _timer = null;
    _accounts = [];
    _accountsWithOTP = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}