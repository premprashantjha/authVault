import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/account.dart';

class OTPCard extends StatelessWidget {
  final AccountWithOTP account;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const OTPCard({
    super.key,
    required this.account,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with issuer and menu
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.account.issuer,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.account.accountName,
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                            const SizedBox(width: 8),
                            Text('Delete', style: AppTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // OTP Code
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Code',
                          style: AppTheme.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatOTP(account.otp),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Monospace',
                            letterSpacing: 4,
                            color: AppTheme.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Column(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: account.progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withValues(alpha:0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                account.secondsRemaining > 10 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.errorColor,
                              ),
                            ),
                            Center(
                              child: Text(
                                '${account.secondsRemaining}',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: account.secondsRemaining > 10 
                                      ? AppTheme.primaryColor 
                                      : AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'seconds',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              LinearProgressIndicator(
                value: account.progress,
                backgroundColor: Colors.white.withValues(alpha:0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  account.secondsRemaining > 10 
                      ? AppTheme.primaryColor 
                      : AppTheme.errorColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatOTP(String otp) {
    // Format as XXX XXX for better readability
    if (otp.length == 6) {
      return '${otp.substring(0, 3)} ${otp.substring(3)}';
    }
    return otp;
  }
}