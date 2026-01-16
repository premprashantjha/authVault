import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import '../app/theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/custom_snackbar.dart';

/// Reusable QR Scanner Widget with camera and gallery support
/// Can be used for both backup QR scanning and account import
class QRScannerWidget extends StatefulWidget {
  final String title;
  final String scanHint;
  final Function(String) onQRCodeScanned;
  final Widget? successBadge;
  final bool showGalleryButton;

  const QRScannerWidget({
    super.key,
    required this.title,
    required this.onQRCodeScanned,
    this.scanHint = 'Position QR code within frame',
    this.successBadge,
    this.showGalleryButton = true,
  });

  @override
  State<QRScannerWidget> createState() => QRScannerWidgetState();
}

class QRScannerWidgetState extends State<QRScannerWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MobileScannerController _cameraController;
  late final AnimationController _scanAnimation;

  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _torchOn = false;
  bool _permissionGranted = false;
  bool _isInitializing = true;
  CameraFacing _facing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final permission = await Permission.camera.status;

      if (permission.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _setError('Camera permission is required to scan QR codes.');
          return;
        }
      }

      if (permission.isPermanentlyDenied) {
        _setError(
            'Camera permission is permanently denied. Please enable in Settings.');
        return;
      }

      _cameraController = MobileScannerController(
        facing: _facing,
        torchEnabled: false,
      );

      setState(() {
        _permissionGranted = true;
        _isInitializing = false;
      });
    } catch (e) {
      _setError('Failed to initialize camera: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimation.dispose();
    if (_permissionGranted) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_permissionGranted) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _cameraController.start();
      }
    }
  }

  void _toggleTorch() async {
    if (!_permissionGranted) return;
    try {
      await _cameraController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      // ignore
    }
  }

  void _switchCamera() async {
    if (!_permissionGranted) return;
    try {
      await _cameraController.switchCamera();
      setState(() =>
          _facing = _facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Pick image from gallery
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      if (file.path == null) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            title: 'Error',
            message: 'Could not access the selected image',
            type: SnackbarType.error,
          );
        }
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Analyze the image for QR codes
      final barcodes = await _cameraController.analyzeImage(file.path!);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (barcodes == null || barcodes.barcodes.isEmpty) {
        CustomSnackbar.show(
          context,
          title: 'No QR Code Found',
          message: 'The selected image does not contain a valid QR code.',
          type: SnackbarType.error,
        );
        return;
      }

      // Process the first barcode found
      final raw = barcodes.barcodes.first.rawValue;
      if (raw == null || raw.isEmpty) {
        CustomSnackbar.show(
          context,
          title: 'Invalid QR Code',
          message: 'Could not read the QR code from the image.',
          type: SnackbarType.error,
        );
        return;
      }

      // Stop camera and process the scanned data
      setState(() => _isProcessing = true);
      if (_permissionGranted) {
        _cameraController.stop();
      }
      widget.onQRCodeScanned(raw);
    } catch (e) {
      if (mounted) {
        // Try to close loading dialog if it's open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        CustomSnackbar.show(
          context,
          title: 'Error',
          message: 'Failed to scan image: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
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

  /// Public method to restart scanning (can be called from parent)
  void restartScanning() {
    if (mounted) {
      setState(() => _isProcessing = false);
      if (_permissionGranted) {
        _cameraController.start();
      }
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
        title: Text(
          widget.title,
          style: AppTheme.headlineMedium(Colors.white),
        ),
        actions: [
          if (widget.showGalleryButton)
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
              onPressed: _pickImageFromGallery,
              tooltip: 'Upload from Gallery',
            ),
          if (_permissionGranted) ...[
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white),
              onPressed: _toggleTorch,
              tooltip: 'Toggle Flash',
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _switchCamera,
              tooltip: 'Switch Camera',
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: widget.showGalleryButton
          ? FloatingActionButton.extended(
              onPressed: _pickImageFromGallery,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload QR'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (!_permissionGranted) {
      return _buildPermissionDeniedState();
    }

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
            setState(() => _isProcessing = true);
            _cameraController.stop();
            widget.onQRCodeScanned(raw);
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
              painter: QRCornerBorderPainter(
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
                          theme.colorScheme.primary.withValues(alpha: 0),
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Hint text
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                widget.scanHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            // Success badge (if provided)
            if (widget.successBadge != null)
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                child: Center(child: widget.successBadge!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: AppTheme.bodyLarge(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Permission Required',
                style: AppTheme.headlineMedium(Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To scan QR codes, please allow camera access in your device settings.',
                style: AppTheme.bodyMedium(Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                onTap: () async {
                  await openAppSettings();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Open Settings',
                    style: AppTheme.bodyLarge(Colors.white).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTheme.bodyMedium(Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Error',
                style: AppTheme.headlineMedium(Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: AppTheme.bodyMedium(Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                onTap: () async {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _isInitializing = true;
                  });
                  await _initializeCamera();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Try Again',
                    style: AppTheme.bodyLarge(Colors.white).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

/// Custom painter for QR scanner corner borders
class QRCornerBorderPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double borderWidth;

  QRCornerBorderPainter({
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
        ..arcToPoint(Offset(size.width, radius),
            radius: Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height),
            radius: Radius.circular(radius))
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius),
            radius: Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(QRCornerBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.borderWidth != borderWidth;
}
