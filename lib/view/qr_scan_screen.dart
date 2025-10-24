import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../models/account.dart';
import '../view_models/account_view_model.dart';
import '../services/qr_scanner_service.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> 
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  final _barcodeScanner = BarcodeScanner();
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedCameraIndex = 0;
  Timer? _scanTimer;
  
  // Animation for scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize scanner animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    _initializeCamera();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _barcodeScanner.close();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _onNewCameraSelected(_controller!.description);
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        _setError('No camera available on this device');
        return;
      }

      // Prefer back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      await _onNewCameraSelected(backCamera);
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller!.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _hasError = false;
        });
        _startContinuousScanning();
      }
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  void _startContinuousScanning() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (_isProcessing || !_isCameraInitialized || !mounted) return;
      
      await _captureAndScan();
    });
  }

  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile imageFile = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      // Delete the temporary file
      await File(imageFile.path).delete();

      for (final barcode in barcodes) {
        if (barcode.rawValue != null) {
          _processScannedData(barcode.rawValue!);
          return; // Process only first valid barcode
        }
      }
    } catch (e) {
      print('Scan error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
    final account = Account.fromOTPAuthURI(otpAuth);
    final viewModel = Provider.of<AccountViewModel>(context, listen: false);
    
    final success = await viewModel.addAccount(account);
    
    if (success && mounted) {
      // Navigate back to home with success
      Navigator.of(context).pop(true);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.issuer} account added successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      _setError('Failed to add account. It might already exist.');
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

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _onNewCameraSelected(_cameras![_selectedCameraIndex]);
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white, 
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
              ),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingState();
    }

    return _buildCameraPreview();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 20),
              Text(
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        // Camera Preview - full screen
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_controller!),
        ),
        
        // Scanner Overlay
        _buildScannerOverlay(),
        
        // Processing Indicator
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scanning QR Code...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: QrScannerOverlayPainter(_animation.value),
            size: MediaQuery.of(context).size,
          );
        },
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
    final maxScannerSize = width * 0.75; // 75% of screen width
    final minScannerSize = 200.0; // Minimum size for very small screens
    final scannerSize = maxScannerSize.clamp(minScannerSize, 300.0);
    
    // Center the scanner box with proper spacing
    final scannerRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: scannerSize,
      height: scannerSize,
    );


    // corner design
    _drawScannerCorners(canvas, scannerRect);
    
    // animated scan line
    _drawScanLine(canvas, scannerRect);
    
    // instructional text
    _drawInstructionText(canvas, scannerRect, width, height);
  }

  void _drawScannerCorners(Canvas canvas, Rect scannerRect) {
    const cornerLength = 22.0;
    const cornerWidth = 4.0;
    
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight - Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft - Offset(0, cornerLength),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - Offset(0, cornerLength),
      cornerPaint,
    );
  }

  void _drawScanLine(Canvas canvas, Rect scannerRect) {
    // Calculate scan line position with smooth animation
    final scanLineY = scannerRect.top + (scannerRect.height * animationValue);
    
    // Main scan line
    final scanLinePaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // the moving scan line
    canvas.drawLine(
      Offset(scannerRect.left + 15, scanLineY),
      Offset(scannerRect.right - 15, scanLineY),
      scanLinePaint,
    );

    // Add glow effect to scan line
    final glowPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha:0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawLine(
      Offset(scannerRect.left + 15, scanLineY),
      Offset(scannerRect.right - 15, scanLineY),
      glowPaint,
    );

    // Add scanning dots at the ends
    final dotPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    // Left dot
    canvas.drawCircle(
      Offset(scannerRect.left + 15, scanLineY),
      4.0,
      dotPaint,
    );

    // Right dot
    canvas.drawCircle(
      Offset(scannerRect.right - 15, scanLineY),
      4.0,
      dotPaint,
    );
  }

  void _drawInstructionText(Canvas canvas, Rect scannerRect, double width, double height) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      shadows: [
        const Shadow(
          blurRadius: 8.0,
          color: Colors.black,
          offset: Offset(2.0, 2.0),
        ),
      ],
    );
    
    // Main instruction text
    final instructionSpan = TextSpan(
      text: 'Position QR code inside the frame',
      style: textStyle,
    );
    
    final instructionPainter = TextPainter(
      text: instructionSpan,
      textDirection: TextDirection.ltr,
    );
    
    instructionPainter.layout();
    
    instructionPainter.paint(
      canvas,
      Offset(
        (width - instructionPainter.width) / 2,
        scannerRect.bottom + 40,
      ),
    );

    // Secondary help text
    final helpSpan = TextSpan(
      text: 'It will scan automatically',
      style: textStyle.copyWith(
        fontSize: 14,
        color: Colors.white70,
        fontWeight: FontWeight.normal,
      ),
    );
    
    final helpPainter = TextPainter(
      text: helpSpan,
      textDirection: TextDirection.ltr,
    );
    
    helpPainter.layout();
    
    helpPainter.paint(
      canvas,
      Offset(
        (width - helpPainter.width) / 2,
        scannerRect.bottom + 70,
      ),
    );

    // Title above scanner
    final titleSpan = TextSpan(
      text: 'AuthVault',
      style: textStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
    
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    );
    
    titlePainter.layout();
    
    titlePainter.paint(
      canvas,
      Offset(
        (width - titlePainter.width) / 2,
        scannerRect.top - 80,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}