import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../app/app_constants.dart';
import '../../models/account.dart';
import '../../services/icon_service.dart';

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
  Timer? _displayTimer;
  late int _displaySecondsRemaining;
  late double _displayProgress;

  @override
  void initState() {
    super.initState();
    _displaySecondsRemaining = widget.account.secondsRemaining;
    _displayProgress = widget.account.progress;
    _startDisplayTimer();
  }

  @override
  void didUpdateWidget(OTPCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update display values when widget updates (e.g., new OTP code)
    if (oldWidget.account.otp != widget.account.otp) {
      _displaySecondsRemaining = widget.account.secondsRemaining;
      _displayProgress = widget.account.progress;
    }
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _displaySecondsRemaining = _displaySecondsRemaining > 0 ? _displaySecondsRemaining - 1 : 30;
          _displayProgress = _displaySecondsRemaining / 30.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serviceIcon = IconService.getIconForService(widget.account.account.issuer);
    final serviceColor = IconService.getColorForService(widget.account.account.issuer);
    
    return Card(
      elevation: AppConstants.elevationMedium,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.otpCardRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppConstants.otpCardRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.otpCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with issuer and menu
              Row(
                children: [
                  Container(
                    width: AppConstants.otpAvatarSize,
                    height: AppConstants.otpAvatarSize,
                    decoration: BoxDecoration(
                      color: serviceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(
                      serviceIcon,
                      color: Colors.white,
                      size: AppConstants.iconSizeSm + 2,
                    ),
                  ),
                  SizedBox(width: AppConstants.spaceSm + 2),
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
                        SizedBox(height: AppConstants.spaceXs / 2),
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
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        widget.account.isFavorite ? Icons.star : Icons.star_border,
                        key: ValueKey(widget.account.isFavorite),
                        color: widget.account.isFavorite
                            ? AppTheme.primaryColor
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
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
              SizedBox(height: AppConstants.spaceMd),
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
                              SizedBox(width: AppConstants.spaceXs + 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _copied
                                    ? Icon(Icons.check_circle,
                                      key: const ValueKey('copied_icon'),
                                      size: AppConstants.iconSizeSm,
                                      color: colorScheme.tertiary)
                                    : Icon(Icons.copy,
                                        key: const ValueKey('copy_icon'),
                                        size: AppConstants.iconSizeSm - 2,
                                        color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium)),
                              ),
                            ],
                          ),
                          SizedBox(height: AppConstants.spaceXs),
                          Text(
                            _formatOTP(widget.account.otp),
                            style: TextStyle(
                              fontSize: AppConstants.otpFontSize,
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
                        width: AppConstants.otpTimerSize,
                        height: AppConstants.otpTimerSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _displayProgress,
                              strokeWidth: 3.5,
                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _displaySecondsRemaining > 10 
                                    ? colorScheme.primary 
                                    : colorScheme.error,
                              ),
                            ),
                            Center(
                              child: Text(
                                '$_displaySecondsRemaining',
                                textAlign: AppTheme.textAlignCenter,
                                style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _displaySecondsRemaining > 10 
                                      ? colorScheme.primary 
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppConstants.spaceXs / 2),
                      Text(
                        'seconds',
                        style: AppTheme.caption(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spaceXs + 2),
              // Progress bar
              LinearProgressIndicator(
                value: _displayProgress,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    _displaySecondsRemaining > 10 
                      ? colorScheme.primary 
                      : colorScheme.error,
                ),
                borderRadius: BorderRadius.circular(AppConstants.spaceXs - 1),
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
    Future.delayed(AppConstants.clipboardClearDuration, () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }
  void _showDeleteConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppConstants.fabSize,
                  height: AppConstants.fabSize,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                    size: AppConstants.iconSizeLg + 4,
                  ),
                ),
                SizedBox(height: AppConstants.spaceMd),
                Text(
                  'Delete ${widget.account.account.issuer}?',
                  style: AppTheme.headlineMedium(colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.spaceSm),
                Text(
                  'This will permanently remove this account and you won\'t be able to generate codes.',
                  style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.spaceLg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.radiusMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          ),
                        ),
                        child: Text('Cancel', style: AppTheme.bodyMedium(colorScheme.onSurface)),
                      ),
                    ),
                    SizedBox(width: AppConstants.otpCardSpacing),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          padding: EdgeInsets.symmetric(vertical: AppConstants.radiusMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          ),
                        ),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
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