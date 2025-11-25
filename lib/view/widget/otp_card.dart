import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/account.dart';
import '../../services/icon_service.dart';
import '../../widgets/animated/animated_button.dart';

class OTPCard extends StatefulWidget {
  final AccountWithOTP account;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const OTPCard({
    super.key,
    required this.account,
    required this.onDelete,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<OTPCard> createState() => _OTPCardState();
}

class _OTPCardState extends State<OTPCard> {
  bool _copied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serviceIcon = IconService.getIconForService(widget.account.account.issuer);
    final serviceColor = IconService.getColorForService(widget.account.account.issuer);
    const cardPadding = EdgeInsets.all(16);
    const headerSpacing = 16.0;
    const labelGap = 6.0;
    const otpFontSize = 24.0;
    const issuerGap = 10.0;
    const avatarSize = 36.0;
    const avatarIconSize = 18.0;
    const timerSize = 40.0;
    const progressStroke = 3.5;
    
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with issuer and menu
              Row(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      serviceIcon,
                      color: Colors.white,
                      size: avatarIconSize,
                    ),
                  ),
                  SizedBox(width: issuerGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.account.issuer,
                          style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.account.account.accountName,
                          style: AppTheme.caption(theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.account.isFavorite ? Icons.star : Icons.star_border,
                      color: widget.account.isFavorite
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    tooltip: widget.account.isFavorite ? 'Remove from favorites' : 'Mark as favorite',
                    onPressed: widget.onFavoriteToggle,
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
              SizedBox(height: headerSpacing),
              // OTP Code
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, widget.account.otp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Verification Code',
                                style: AppTheme.caption(theme.colorScheme.onSurface),
                              ),
                              SizedBox(width: labelGap),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _copied
                                    ? Icon(Icons.check_circle,
                                      key: const ValueKey('copied_icon'),
                                      size: 16,
                                      color: colorScheme.tertiary)
                                    : Icon(Icons.copy,
                                        key: const ValueKey('copy_icon'),
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatOTP(widget.account.otp),
                            style: TextStyle(
                              fontSize: otpFontSize,
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
                        width: timerSize,
                        height: timerSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: widget.account.progress,
                              strokeWidth: progressStroke,
                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.account.secondsRemaining > 10 
                                    ? colorScheme.primary 
                                    : colorScheme.error,
                              ),
                            ),
                            Center(
                              child: Text(
                                '${widget.account.secondsRemaining}',
                                textAlign: AppTheme.textAlignCenter,
                                style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.account.secondsRemaining > 10 
                                      ? colorScheme.primary 
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'seconds',
                        style: AppTheme.caption(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              LinearProgressIndicator(
                value: widget.account.progress,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    widget.account.secondsRemaining > 10 
                      ? colorScheme.primary 
                      : colorScheme.error,
                ),
                borderRadius: BorderRadius.circular(3),
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

    setState(() {
      _copied = true;
    });
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });

    // Auto-clear clipboard after 30 seconds for security
    Future.delayed(const Duration(seconds: 30), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }
  void _showDeleteConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
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
                      color: colorScheme.error.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Account',
                    style: AppTheme.bodyLarge(theme.colorScheme.onSurface)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Message
              Text(
                'This will permanently remove ${widget.account.account.displayName} from your Authenticator. '
                'You will no longer be able to generate OTP codes for this account.',
                style: AppTheme.bodyMedium(theme.colorScheme.onSurface.withValues(alpha:0.7)),
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
                        style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
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