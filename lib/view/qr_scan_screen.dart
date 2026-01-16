import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';
import '../services/qr_scanner_service.dart';
import '../models/account.dart';
import '../view_models/account_view_model.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/custom_snackbar.dart';

/// Screen for scanning QR codes to add accounts
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey<QRScannerWidgetState> _scannerKey = GlobalKey();

  void _processScannedData(String scannedData) {
    try {
      final otpAuth = OTPAuthURI.fromString(scannedData);

      if (otpAuth.isValid) {
        _addAccountFromQR(otpAuth);
      } else {
        _showError('This QR code is not supported');
      }
    } catch (e) {
      _showError('Failed to parse QR code: ${e.toString()}');
    }
  }

  void _addAccountFromQR(OTPAuthURI otpAuth) async {
    if (!mounted) return;
    final account = Account.fromOTPAuthURI(otpAuth);
    final viewModel = context.read<AccountViewModel>();

    // Check if account already exists
    final exists = await viewModel.accountExists(account);

    if (exists && mounted) {
      _showDuplicateAccountDialog(account, viewModel);
    } else {
      final success = await viewModel.addAccount(account);

      if (success && mounted) {
        HapticFeedback.lightImpact();

        if (!mounted) return;

        // Pop and return success
        Navigator.of(context).pop(true);
      } else if (mounted) {
        _showError('Failed to add account. Please try again.');
      }
    }
  }

  void _showDuplicateAccountDialog(
      Account account, AccountViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              AppConstants.getResponsiveRadius(context, large: 20.0)),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Account Already Exists',
                  style: AppTheme.responsiveHeadlineMedium(
                      context, colorScheme.onSurface)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account.issuer} - ${account.accountName}',
                style: AppTheme.responsiveBodyLarge(context, colorScheme.onSurface)
                    .copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            Text('This account is already added to your authenticator.',
                style: AppTheme.responsiveBodyMedium(
                    context, colorScheme.onSurface)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Restart scanning
              _scannerKey.currentState?.restartScanning();
            },
            child: Text('Cancel',
                style: AppTheme.responsiveBodyMedium(
                    context, colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await viewModel.updateAccount(account);
              if (!mounted) return;
              if (success) {
                HapticFeedback.lightImpact();
                CustomSnackbar.show(
                  context,
                  title: 'Account Updated',
                  message: '${account.issuer} account has been refreshed.',
                  type: SnackbarType.success,
                );
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: Text('Update',
                style: AppTheme.bodyMedium(colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      CustomSnackbar.show(
        context,
        title: 'Scan Error',
        message: message,
        type: SnackbarType.error,
      );
      // Restart scanning
      _scannerKey.currentState?.restartScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return QRScannerWidget(
      key: _scannerKey,
      title: 'Scan QR Code',
      scanHint: 'Position QR code within frame',
      onQRCodeScanned: _processScannedData,
      showGalleryButton: true,
    );
  }
}
