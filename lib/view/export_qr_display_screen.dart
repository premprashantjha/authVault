import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../app/theme.dart';
import '../models/account.dart';
import '../services/app_export_service.dart';
import '../widgets/custom_snackbar.dart';

/// Screen displaying QR code(s) for exported accounts
class ExportQRDisplayScreen extends StatefulWidget {
  final List<Account> accounts;

  const ExportQRDisplayScreen({
    super.key,
    required this.accounts,
  });

  @override
  State<ExportQRDisplayScreen> createState() => _ExportQRDisplayScreenState();
}

class _ExportQRDisplayScreenState extends State<ExportQRDisplayScreen> {
  late final List<List<Account>> _accountBatches;
  int _currentBatchIndex = 0;
  final int _maxAccountsPerQR = 10;
  final GlobalKey _qrKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _accountBatches = _splitIntoBatches(widget.accounts, _maxAccountsPerQR);
  }

  List<List<Account>> _splitIntoBatches(List<Account> accounts, int batchSize) {
    final batches = <List<Account>>[];
    for (var i = 0; i < accounts.length; i += batchSize) {
      final end = (i + batchSize < accounts.length) ? i + batchSize : accounts.length;
      batches.add(accounts.sublist(i, end));
    }
    return batches;
  }

  String _generateQRData(List<Account> accounts) {
    return AppExportService.generateMigrationUri(accounts);
  }

  void _nextBatch() {
    if (_currentBatchIndex < _accountBatches.length - 1) {
      setState(() => _currentBatchIndex++);
    }
  }

  void _previousBatch() {
    if (_currentBatchIndex > 0) {
      setState(() => _currentBatchIndex--);
    }
  }

  Future<void> _shareQRCode() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    try {
      // Capture the QR code as an image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture QR code');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not convert QR code to image');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share the file
      final currentBatch = _accountBatches[_currentBatchIndex];
      final accountCount = currentBatch.length;
      final batchInfo = _accountBatches.length > 1 
          ? ' (${_currentBatchIndex + 1}/${_accountBatches.length})'
          : '';
      
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan this QR code with an authenticator app to import $accountCount account${accountCount > 1 ? 's' : ''}$batchInfo',
      );

      // Clean up
      try {
        await file.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
      
      // Only show success message if user actually shared (not cancelled)
      if (mounted && result.status == ShareResultStatus.success) {
        CustomSnackbar.show(
          context,
          title: 'Shared',
          message: 'Remember to delete the QR code after transfer',
          type: SnackbarType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          title: 'Share Failed',
          message: 'Could not share QR code',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentBatch = _accountBatches[_currentBatchIndex];
    final qrData = _generateQRData(currentBatch);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Export QR Code',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: _isSharing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  )
                : const Icon(Icons.share_outlined),
            onPressed: _isSharing ? null : _shareQRCode,
            tooltip: 'Share QR Code',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scan with an authenticator app to import accounts',
                      style: AppTheme.bodyMedium(colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code with RepaintBoundary for sharing
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 280,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Account count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 18,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${currentBatch.length} account${currentBatch.length > 1 ? 's' : ''}',
                              style: AppTheme.bodyLarge(colorScheme.onPrimaryContainer).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Batch navigation
                      if (_accountBatches.length > 1) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'QR Code ${_currentBatchIndex + 1} of ${_accountBatches.length}',
                                style: AppTheme.bodyLarge(colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scan all QR codes to import all accounts',
                                style: AppTheme.caption(
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filled(
                                    onPressed: _currentBatchIndex > 0 ? _previousBatch : null,
                                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _currentBatchIndex > 0
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                      foregroundColor: _currentBatchIndex > 0
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface.withValues(alpha: 0.38),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_currentBatchIndex + 1}',
                                      style: AppTheme.headlineMedium(colorScheme.onPrimaryContainer).copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton.filled(
                                    onPressed: _currentBatchIndex < _accountBatches.length - 1
                                        ? _nextBatch
                                        : null,
                                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _currentBatchIndex < _accountBatches.length - 1
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                      foregroundColor: _currentBatchIndex < _accountBatches.length - 1
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface.withValues(alpha: 0.38),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to home (pop all screens until home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
