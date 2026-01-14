import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/app_constants.dart';
import 'animated_button.dart';

class EmptyStateWidget extends StatefulWidget {
  final VoidCallback onAddAccount;

  const EmptyStateWidget({
    super.key,
    required this.onAddAccount,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500), 
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.05).animate( 
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.55).animate( 
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.spaceXl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - AppConstants.iconSizeXxl * 2),
            child: Column(
              mainAxisAlignment: AppTheme.mainAxisCenter,
              mainAxisSize: MainAxisSize.min, // CRITICAL: Size to content
              children: [
                // Animated CDAC Logo watermark
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          width: AppConstants.spaceXxl * 4,
                          height: AppConstants.spaceXxl * 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ),
                          padding: EdgeInsets.all(AppConstants.spaceXl + AppConstants.spaceSm),
                          child: Image.asset(
                            'assets/images/CDAC_Logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppConstants.spaceXxl),
                Text(
                  'Secure your accounts with two-factor authentication',
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium),
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: AppTheme.textAlignCenter,
                ),
                SizedBox(height: AppConstants.spaceXl),
                AnimatedButton(
                  onTap: widget.onAddAccount,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceXl, vertical: AppConstants.spaceMd),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: AppConstants.iconSizeMd,
                          color: theme.colorScheme.onPrimary,
                        ),
                        SizedBox(width: AppConstants.otpCardSpacing),
                        Text(
                          'Add Your First Account',
                          style: AppTheme.bodyLarge(theme.colorScheme.onPrimary).copyWith(
                            fontWeight: AppTheme.weightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
