// no extra dart:async required
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/account.dart';
import '../view_models/account_view_model.dart';
import '../widgets/animated/animated_button.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;
  bool _torchOn = false;
  CameraFacing _facing = CameraFacing.back;

  // Animation for scanner overlay
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraController = MobileScannerController(facing: _facing, torchEnabled: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        if (mounted) setState(() {});
      })
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.start();
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

    debugPrint('QR: Adding account ${account.issuer} - ${account.accountName}');

    // Check if account already exists
    final exists = await viewModel.accountExists(account);

    if (exists && mounted) {
      debugPrint('QR: Account already exists, showing dialog');
      _showDuplicateAccountDialog(account, viewModel);
    } else {
      debugPrint('QR: Calling viewModel.addAccount...');
      final success = await viewModel.addAccount(account);
      debugPrint('QR: addAccount returned: $success');

      if (success && mounted) {
        HapticFeedback.lightImpact();

        // Capture ScaffoldMessenger before popping
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        debugPrint('QR: Popping back to Home...');
        // Pop to return to Home
        navigator.pop(true);

        // Show success message on Home screen
        messenger.showSnackBar(
          SnackBar(
            content: Text('${account.issuer} account added successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        _setError('Failed to add account. Please try again.');
      }
    }
  }

  void _showDuplicateAccountDialog(Account account, AccountViewModel viewModel) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Account Already Exists', style: AppTheme.headlineMedium(theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account.issuer} - ${account.accountName}', style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('This account is already added to your authenticator.', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final success = await viewModel.updateAccount(account);
              if (success && mounted) {
                HapticFeedback.lightImpact();
                navigator.pop(true);
                messenger.showSnackBar(
                  SnackBar(content: Text('${account.issuer} account updated!'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
                );
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
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, color: Colors.white, size: 24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 20)),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.cameraswitch, color: Colors.white, size: 20)),
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
        // MobileScanner provides a distortion-free preview optimized for scanning
        MobileScanner(
          controller: _cameraController,
          fit: BoxFit.cover,
          // Note: `allowDuplicates` and `MobileScannerArguments` were removed in mobile_scanner 7.x.
          // onDetect now provides a BarcodeCapture-like `capture` with a `barcodes` list.
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

        // Semi-transparent overlay with clear scan area
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ),

        // Scan frame and animated line
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: QrScannerOverlayPainter(_animationController.value),
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 0,
          right: 0,
          child: const Text(
            'Position QR code in frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 20),
              Text('Camera Error', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_errorMessage, style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
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
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)), child: const Text('Try Again', style: TextStyle(color: Colors.white))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrScannerOverlayPainter extends CustomPainter {
  final double animationValue;

  QrScannerOverlayPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Calculate scanner dimensions - responsive for all devices
    final maxScannerSize = width; // use full sized square passed in
    final minScannerSize = 200.0;
    final scannerSize = maxScannerSize.clamp(minScannerSize, 300.0);

    final scannerRect = Rect.fromCenter(center: Offset(width / 2, height / 2), width: scannerSize, height: scannerSize);

    _drawScannerCorners(canvas, scannerRect);
    _drawScanLine(canvas, scannerRect);
    _drawInstructionText(canvas, scannerRect, width, height);
  }

  void _drawScannerCorners(Canvas canvas, Rect scannerRect) {
    const cornerLength = 28.0;
    const cornerWidth = 5.0;

    final cornerPaint = Paint()..color = AppTheme.primaryColor..strokeWidth = cornerWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    final glowPaint = Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.3)..strokeWidth = cornerWidth + 8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Top-left
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + Offset(cornerLength, 0), glowPaint);
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + Offset(0, cornerLength), glowPaint);
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight - Offset(cornerLength, 0), glowPaint);
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight + Offset(0, cornerLength), glowPaint);
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight + Offset(0, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft + Offset(cornerLength, 0), glowPaint);
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft - Offset(0, cornerLength), glowPaint);
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft - Offset(0, cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight - Offset(cornerLength, 0), glowPaint);
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight - Offset(0, cornerLength), glowPaint);
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight - Offset(0, cornerLength), cornerPaint);
  }

  void _drawScanLine(Canvas canvas, Rect scannerRect) {
    final scanLineY = scannerRect.top + (scannerRect.height * animationValue);

    final scanLinePaint = Paint()..color = AppTheme.primaryColor..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(scannerRect.left + 15, scanLineY), Offset(scannerRect.right - 15, scanLineY), scanLinePaint);

    final glowPaint = Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 12.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawLine(Offset(scannerRect.left + 15, scanLineY), Offset(scannerRect.right - 15, scanLineY), glowPaint);

    final dotPaint = Paint()..color = AppTheme.primaryColor..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(scannerRect.left + 15, scanLineY), 4.0, dotPaint);
    canvas.drawCircle(Offset(scannerRect.right - 15, scanLineY), 4.0, dotPaint);
  }

  void _drawInstructionText(Canvas canvas, Rect scannerRect, double width, double height) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, shadows: [const Shadow(blurRadius: 8.0, color: Colors.black, offset: Offset(2.0, 2.0))]);

    final instructionSpan = TextSpan(text: 'Position QR code inside the frame', style: textStyle);
    final instructionPainter = TextPainter(text: instructionSpan, textDirection: TextDirection.ltr);
    instructionPainter.layout();
    instructionPainter.paint(canvas, Offset((width - instructionPainter.width) / 2, scannerRect.bottom + 40));

    final helpSpan = TextSpan(text: 'It will scan automatically', style: textStyle.copyWith(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.normal));
    final helpPainter = TextPainter(text: helpSpan, textDirection: TextDirection.ltr);
    helpPainter.layout();
    helpPainter.paint(canvas, Offset((width - helpPainter.width) / 2, scannerRect.bottom + 70));

    final titleSpan = TextSpan(text: 'Authenticator', style: textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor));
    final titlePainter = TextPainter(text: titleSpan, textDirection: TextDirection.ltr);
    titlePainter.layout();
    titlePainter.paint(canvas, Offset((width - titlePainter.width) / 2, scannerRect.top - 80));
  }

  @override
  bool shouldRepaint(covariant QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
