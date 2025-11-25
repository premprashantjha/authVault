import 'package:flutter/material.dart';
import '../../app/theme.dart';

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
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Account',
            style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Your secrets stay encrypted on this device. Keep a backup so you can restore them if you switch phones.',
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
            textAlign: AppTheme.textAlignCenter,
          ),
          const SizedBox(height: 24),
          _buildAddOption(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Scan QR Code',
            subtitle: 'Recommended. Point your camera at the QR code provided by the service.',
            onTap: onScanQR,
          ),
          const SizedBox(height: 16),
          _buildAddOption(
            context,
            icon: Icons.keyboard,
            title: 'Enter Manually',
            subtitle: 'Paste or type the secret key if you cannot scan.',
            onTap: onManualEntry,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
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
    
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge(theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.caption(theme.colorScheme.onSurface),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onTap: onTap,
      ),
    );
  }
}
