// no extra dart:async required
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';
import '../models/account.dart';
import '../view_models/account_view_model.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_snackbar.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _scanAnimation;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  bool _torchOn = false;
  CameraFacing _facing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(facing: _facing, torchEnabled: false);
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimation.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    
    // Prevent camera restart during navigation transitions
    if (state == AppLifecycleState.inactive) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      // Only restart camera if we're still on this screen
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _cameraController.start();
      }
    }
  }

  void _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      // ignore
    }
  }

  void _switchCamera() async {
    try {
      await _cameraController.switchCamera();
      setState(() => _facing = _facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back);
    } catch (e) {
      // ignore
    }
  }

  void _processScannedData(String scannedData) {
    try {
      final otpAuth = OTPAuthURI.fromString(scannedData);

      if (otpAuth.isValid) {
        _addAccountFromQR(otpAuth);
      } else {
        _setError('Invalid QR code format');
      }
    } catch (e) {
      _setError('Failed to parse QR code: ${e.toString()}');
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
        _setError('Failed to add account. Please try again.');
      }
    }
  }

  void _showDuplicateAccountDialog(Account account, AccountViewModel viewModel) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context, large: 20.0))
        ),
        title: Text(
          'Account Already Exists', 
          style: AppTheme.responsiveHeadlineMedium(context, theme.colorScheme.onSurface)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${account.issuer} - ${account.accountName}', 
              style: AppTheme.responsiveBodyLarge(context, theme.colorScheme.onSurface).copyWith(
                fontWeight: FontWeight.w600
              )
            ),
            SizedBox(height: AppConstants.getResponsiveSpacing(context)),
            Text(
              'This account is already added to your authenticator.', 
              style: AppTheme.responsiveBodyMedium(context, theme.colorScheme.onSurface)
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Restart camera for scanning again
              _isProcessing = false;
              _cameraController.start();
            },
            child: Text(
              'Cancel', 
              style: AppTheme.responsiveBodyMedium(context, theme.colorScheme.onSurface)
            ),
          ),
          TextButton(
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            child: Text('Update', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) return _buildErrorState();

    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController,
          fit: BoxFit.cover,
          onDetect: (capture) {
            if (_isProcessing) return;
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final raw = barcodes.first.rawValue;
            if (raw == null || raw.isEmpty) return;
            _isProcessing = true;
            _cameraController.stop();
            _processScannedData(raw);
          },
        ),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    final theme = Theme.of(context);
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return Center(
      child: SizedBox(
        width: scanAreaSize,
        height: scanAreaSize,
        child: Stack(
          children: [
            // Corner borders
            CustomPaint(
              size: Size(scanAreaSize, scanAreaSize),
              painter: _CornerBorderPainter(
                color: theme.colorScheme.primary,
                cornerLength: 40,
                borderWidth: 4,
              ),
            ),
            // Scanning line animation
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: scanAreaSize * _scanAnimation.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0),
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Semi-transparent hint text
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                'Position QR code within frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white70),
              const SizedBox(height: 20),
              const Text(
                'Camera Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AnimatedButton(
                onTap: () async {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  try {
                    await _cameraController.start();
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for corner borders
class _CornerBorderPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double borderWidth;

  _CornerBorderPainter({
    required this.color,
    required this.cornerLength,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final radius = 16.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height), radius: Radius.circular(radius))
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius), radius: Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.borderWidth != borderWidth;
}
