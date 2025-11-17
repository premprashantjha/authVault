import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/account.dart';
import '../../services/icon_service.dart';
import '../../widgets/animated/animated_button.dart';

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
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                    onPressed: () => _showDeleteConfirmationDialog(context),
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

    // Auto-clear clipboard after 60 seconds for security
    Future.delayed(const Duration(seconds: 60), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }
  void _showDeleteConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Account',
                    style: AppTheme.bodyLarge(Theme.of(context).colorScheme.onSurface)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Message
              Text(
                'This will permanently remove ${account.account.displayName} from your Authenticator. '
                'You will no longer be able to generate OTP codes for this account.',
                style: AppTheme.bodyMedium(Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7)),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodyMedium(Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text('Delete', style: AppTheme.bodyMedium(Colors.white))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
}