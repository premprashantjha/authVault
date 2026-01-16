import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'import_accounts_screen.dart';

/// Screen showing instructions for importing accounts via QR code
class QrImportScreen extends StatelessWidget {
  const QrImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Import from QR Code',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // Tips Icon
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showTipsModal(context),
            tooltip: 'Tips',
          ),
          // Notes Icon
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showNotesModal(context),
            tooltip: 'Important Notes',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Steps Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.format_list_numbered,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'How to Import',
                      style: AppTheme.title(colorScheme.onSurface).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Steps
                ..._importSteps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return _buildModernStep(context, index + 1, step);
                }),

                const SizedBox(height: 24),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep your original app until you verify all accounts work correctly.',
                          style: AppTheme.bodyMedium(colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Action Button - Scan QR Code
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () => _startImport(context),
                icon: const Icon(Icons.qr_code_scanner, size: 22),
                label: const Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStep(BuildContext context, int number, ImportStep step) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Step Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTheme.bodyLarge(colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (step.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      step.description!,
                      style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                  if (step.substeps != null && step.substeps!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...step.substeps!.map((substep) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  substep,
                                  style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Important Notes',
                    style: AppTheme.headlineMedium(colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _importNotes.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _importNotes[index],
                            style: AppTheme.bodyMedium(colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipsModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Helpful Tips',
                    style: AppTheme.headlineMedium(colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _importTips.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _importTips[index],
                            style: AppTheme.bodyMedium(colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ImportAccountsScreen(),
      ),
    );
  }
}

// Data Models
class ImportStep {
  final String title;
  final String? description;
  final List<String>? substeps;

  ImportStep({
    required this.title,
    this.description,
    this.substeps,
  });
}

// Import Steps
final _importSteps = [
  ImportStep(
    title: 'Open Your Other Authenticator App',
    description: 'Launch the authenticator app you want to import accounts from (e.g., Google Authenticator, 2FAS, etc.)',
  ),
  ImportStep(
    title: 'Find the Export Feature',
    description: 'Look for options like:',
    substeps: [
      '"Transfer accounts" or "Export accounts"',
      '"Share" or "Backup"',
      '"Settings" → "Export" or "Transfer"',
      'The exact location varies by app',
    ],
  ),
  ImportStep(
    title: 'Generate QR Code',
    substeps: [
      'Select the accounts you want to export',
      'Choose "Export via QR code" or similar option',
      'The app will display one or more QR codes',
      'Keep the QR code(s) visible on screen',
    ],
  ),
  ImportStep(
    title: 'Scan with This App',
    substeps: [
      'Tap the "Scan QR Code" button below',
      'Point your camera at the displayed QR code',
      'Or tap the gallery icon to upload a saved QR image',
      'The app will automatically detect and parse the QR code',
    ],
  ),
  ImportStep(
    title: 'Select and Import',
    substeps: [
      'Review the list of detected accounts',
      'Select which accounts you want to import',
      'Tap "Import" to add them to this app',
      'If there are multiple QR codes, scan each one',
    ],
  ),
  ImportStep(
    title: 'Verify Accounts',
    substeps: [
      'Test each imported account to ensure codes work',
      'Compare codes with your original app',
      'Only remove from original app after verification',
    ],
  ),
];

// Important Notes
final _importNotes = [
  'Works with Google Authenticator, 2FAS, and many other authenticator apps',
  'Accounts remain in your original app after export',
  'Some apps may limit the number of accounts per QR code (usually 10)',
  'Always verify imported accounts work before removing from original app',
];

// Helpful Tips
final _importTips = [
  'Scan in a well-lit area for best results',
  'If camera scanning fails, try uploading the QR code image from gallery',
  'Keep your original authenticator app as backup until fully verified',
  'If an app doesn\'t support QR export, you\'ll need to re-scan from services',
];
