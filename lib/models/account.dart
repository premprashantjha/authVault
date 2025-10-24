import 'package:authvault_poc/services/qr_scanner_service.dart';

class Account {
  final String id;
  final String issuer;
  final String accountName;
  final String secretKey;
  final DateTime createdAt;

  Account({
    String? id,
    required this.issuer,
    required this.accountName,
    required this.secretKey,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory Account.fromOTPAuthURI(OTPAuthURI otpAuth) {
    return Account(
      issuer: otpAuth.issuer,
      accountName: otpAuth.account,
      secretKey: otpAuth.secret,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'issuer': issuer,
      'accountName': accountName,
      'secretKey': secretKey,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      issuer: map['issuer']?.toString() ?? '',
      accountName: map['accountName']?.toString() ?? '',
      secretKey: map['secretKey']?.toString() ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['createdAt'].toString()) ?? 0)
          : DateTime.now(),
    );
  }

  String get displayName {
    if (issuer.isNotEmpty && accountName.isNotEmpty) {
      return '$issuer • $accountName';
    } else if (issuer.isNotEmpty) {
      return issuer;
    } else {
      return accountName;
    }
  }
}

class AccountWithOTP {
  final Account account;
  final String otp;
  final int secondsRemaining;
  final double progress;

  AccountWithOTP({
    required this.account,
    required this.otp,
    required this.secondsRemaining,
  }) : progress = secondsRemaining / 30.0;
}