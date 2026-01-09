import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/app_constants.dart';

class AddAccountModal extends StatelessWidget {
  final VoidCallback onScanQR;
  final VoidCallback onManualEntry;

  const AddAccountModal({
    super.key,
    required this.onScanQR,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: AppConstants.getResponsiveModalHeight(context, factor: 0.8),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: AppConstants.getResponsivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min, // CRITICAL: Size to content
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Add Account',
                style: AppTheme.responsiveHeadlineMedium(context, theme.colorScheme.onSurface),
              ),
              SizedBox(height: AppConstants.getResponsiveSpacing(context, xs: 6.0, sm: 8.0)),
              Text(
                'Your secrets stay encrypted on this device. Keep a backup so you can restore them if you switch phones.',
                style: AppTheme.responsiveBodyMedium(context, theme.colorScheme.onSurface).copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.getResponsiveSpacing(context, lg: 24.0)),
              _buildAddOption(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scan QR Code',
                subtitle: 'Recommended. Point your camera at the QR code provided by the service.',
                onTap: onScanQR,
              ),
              SizedBox(height: AppConstants.getResponsiveSpacing(context)),
              _buildAddOption(
                context,
                icon: Icons.keyboard,
                title: 'Enter Manually',
                subtitle: 'Paste or type the secret key if you cannot scan.',
                onTap: onManualEntry,
              ),
              SizedBox(height: AppConstants.getResponsiveSpacing(context)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTheme.responsiveBodyMedium(context, theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconSize = AppConstants.getResponsiveIconSize(context, small: 40.0, medium: 44.0, large: 48.0);
    
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context)),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(AppConstants.getResponsiveSpacing(context)),
        leading: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context, small: 10.0, medium: 12.0)),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: AppConstants.getResponsiveIconSize(context, small: 18.0, medium: 20.0, large: 22.0),
          ),
        ),
        title: Text(
          title,
          style: AppTheme.responsiveBodyLarge(context, theme.colorScheme.onSurface),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: AppConstants.getResponsiveSpacing(context, xs: 4.0, sm: 6.0)),
          child: Text(
            subtitle,
            style: AppTheme.responsiveCaption(context, theme.colorScheme.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: AppConstants.getResponsiveIconSize(context, small: 14.0, medium: 16.0, large: 18.0),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }
}
