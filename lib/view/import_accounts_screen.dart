import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../services/google_auth_import_service.dart';
import '../services/qr_scanner_service.dart';
import '../services/icon_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/custom_snackbar.dart';

/// Screen for importing accounts from other authenticator apps
class ImportAccountsScreen extends StatefulWidget {
  const ImportAccountsScreen({super.key});

  @override
  State<ImportAccountsScreen> createState() => _ImportAccountsScreenState();
}

class _ImportAccountsScreenState extends State<ImportAccountsScreen> {
  final GlobalKey<QRScannerWidgetState> _scannerKey = GlobalKey();
  int _importedCount = 0;

  Future<void> _handleQRCode(String code) async {
    try {
      // Check if it's a Google Authenticator migration URI (includes our app's export)
      if (code.startsWith('otpauth-migration://')) {
        await _handleGoogleAuthMigration(code);
      }
      // Check if it's a standard otpauth URI
      else if (code.startsWith('otpauth://')) {
        await _handleStandardOtpAuth(code);
      } else {
        throw FormatException('This QR code is not supported');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        if (errorMessage.startsWith('FormatException: ')) {
          errorMessage = errorMessage.replaceFirst('FormatException: ', '');
        }

        if (errorMessage.contains('No accounts found')) {
          errorMessage +=
              '\n\nTip: Make sure you\'re scanning a valid authenticator QR code.';
        }

        CustomSnackbar.show(
          context,
          title: 'Import Failed',
          message: errorMessage,
          type: SnackbarType.error,
        );

        // Restart scanning
        _scannerKey.currentState?.restartScanning();
      }
    }
  }

  Future<void> _handleGoogleAuthMigration(String uri) async {
    try {
      final accounts = GoogleAuthImportService.parseMigrationUri(uri);

      if (accounts.isEmpty) {
        throw FormatException(
            'No accounts found in QR code. Please make sure you scanned a Google Authenticator export QR code.');
      }

      // Show import dialog
      if (!mounted) return;
      await _showImportDialog(accounts);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Auth migration error: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleStandardOtpAuth(String uri) async {
    try {
      final otpAuth = OTPAuthURI.fromString(uri);

      if (!otpAuth.isValid) {
        throw FormatException('This QR code cannot be read');
      }

      final account = ImportedAccount(
        issuer: otpAuth.issuer,
        accountName: otpAuth.account,
        secret: otpAuth.secret,
        algorithm: otpAuth.algorithm ?? 'SHA1',
        digits: otpAuth.digits ?? 6,
        type: otpAuth.type,
      );

      // Show import dialog
      if (!mounted) return;
      await _showImportDialog([account]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _showImportDialog(List<ImportedAccount> accounts) async {
    final result = await showDialog<ImportResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportConfirmationDialog(
        accounts: accounts,
        onImport: _importAccounts,
      ),
    );

    if (result != null && result.success && mounted) {
      // Show success and navigate to home
      HapticFeedback.lightImpact();

      CustomSnackbar.show(
        context,
        title: 'Import Successful',
        message: 'Imported ${result.importedCount} account(s) successfully',
        type: SnackbarType.success,
      );

      // Navigate back to home (pop all import screens)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      // Continue scanning
      _scannerKey.currentState?.restartScanning();
    }
  }

  Future<bool> _importAccounts(List<ImportedAccount> accounts) async {
    final viewModel = context.read<AccountViewModel>();
    int successCount = 0;

    for (final importedAccount in accounts) {
      try {
        final account = importedAccount.toAccount();
        final success = await viewModel.addAccount(account);

        if (success) {
          successCount++;
        }
      } catch (e) {
        // Continue with other accounts
      }
    }

    setState(() {
      _importedCount += successCount;
    });

    return successCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Return the imported count when popping
        }
      },
      child: QRScannerWidget(
        key: _scannerKey,
        title: 'Import Accounts',
        scanHint: 'Position QR code within frame',
        onQRCodeScanned: _handleQRCode,
        showGalleryButton: true,
        successBadge: _importedCount > 0
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Imported: $_importedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

// Result class for import operation
class ImportResult {
  final bool success;
  final int importedCount;

  ImportResult({required this.success, required this.importedCount});
}

class _ImportConfirmationDialog extends StatefulWidget {
  final List<ImportedAccount> accounts;
  final Future<bool> Function(List<ImportedAccount>) onImport;

  const _ImportConfirmationDialog({
    required this.accounts,
    required this.onImport,
  });

  @override
  State<_ImportConfirmationDialog> createState() =>
      _ImportConfirmationDialogState();
}

class _ImportConfirmationDialogState extends State<_ImportConfirmationDialog> {
  late Set<int> _selectedIndices;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    // Select all by default
    _selectedIndices =
        Set.from(List.generate(widget.accounts.length, (index) => index));
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == widget.accounts.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices =
            Set.from(List.generate(widget.accounts.length, (index) => index));
      }
    });
  }

  List<ImportedAccount> get _selectedAccounts {
    return _selectedIndices.map((index) => widget.accounts[index]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = _selectedIndices.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Accounts',
                              style: AppTheme.headlineMedium(
                                  colorScheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.accounts.length} account${widget.accounts.length > 1 ? 's' : ''} found',
                              style: AppTheme.caption(colorScheme.onSurface
                                  .withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Select All checkbox
                  InkWell(
                    onTap: _toggleSelectAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: selectedCount == widget.accounts.length,
                              tristate: true,
                              onChanged: (_) => _toggleSelectAll(),
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedCount == widget.accounts.length
                                ? 'Deselect All'
                                : 'Select All ($selectedCount/${widget.accounts.length})',
                            style: AppTheme.bodyMedium(colorScheme.onSurface)
                                .copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Account list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: widget.accounts.length,
                itemBuilder: (context, index) {
                  final account = widget.accounts[index];
                  final isSelected = _selectedIndices.contains(index);
                  final icon = IconService.getIconForService(account.issuer);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _toggleSelection(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                                  .withValues(alpha: 0.3)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(index),
                                activeColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // App Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Account Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.issuer,
                                    style: AppTheme.bodyLarge(
                                            colorScheme.onSurface)
                                        .copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account.accountName,
                                    style: AppTheme.caption(colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                account.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isImporting
                          ? null
                          : () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodyMedium(colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isImporting || selectedCount == 0
                          ? null
                          : () async {
                              setState(() => _isImporting = true);
                              final success =
                                  await widget.onImport(_selectedAccounts);
                              if (context.mounted) {
                                Navigator.of(context).pop(
                                  ImportResult(
                                    success: success,
                                    importedCount: selectedCount,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor:
                            colorScheme.surfaceContainerHighest,
                        disabledForegroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      child: _isImporting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Import ${selectedCount > 0 ? '($selectedCount)' : ''}',
                              style: AppTheme.bodyMedium(colorScheme.onPrimary)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
