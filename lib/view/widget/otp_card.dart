import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/account.dart';
import '../../services/icon_service.dart';

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
    final theme = Theme.of(context);
    final serviceIcon = IconService.getIconForService(account.account.issuer);
    final serviceColor = IconService.getColorForService(account.account.issuer);
    
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
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
                      color: serviceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      serviceIcon,
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
                          style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.account.accountName,
                          style: AppTheme.caption(theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
                            Text('Delete', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
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
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, account.otp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Verification Code',
                                style: AppTheme.caption(theme.colorScheme.onSurface),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatOTP(account.otp),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Monospace',
                              letterSpacing: 4,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
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
                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                                style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
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
                        style: AppTheme.caption(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              LinearProgressIndicator(
                value: account.progress,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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

  void _copyToClipboard(BuildContext context, String otp) {
    Clipboard.setData(ClipboardData(text: otp));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP code copied to clipboard'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}