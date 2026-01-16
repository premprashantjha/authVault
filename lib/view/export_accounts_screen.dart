import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../services/icon_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/animated_button.dart';
import 'export_qr_display_screen.dart';

/// Screen for selecting accounts to export via QR code
class ExportAccountsScreen extends StatefulWidget {
  const ExportAccountsScreen({super.key});

  @override
  State<ExportAccountsScreen> createState() => _ExportAccountsScreenState();
}

class _ExportAccountsScreenState extends State<ExportAccountsScreen> {
  final Set<String> _selectedAccountIds = {};

  @override
  void initState() {
    super.initState();
    // Select all accounts by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<AccountViewModel>();
      setState(() {
        _selectedAccountIds.addAll(viewModel.accounts.map((a) => a.id));
      });
    });
  }

  void _toggleSelection(String accountId) {
    setState(() {
      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
      } else {
        _selectedAccountIds.add(accountId);
      }
    });
  }

  void _toggleSelectAll() {
    final viewModel = context.read<AccountViewModel>();
    setState(() {
      if (_selectedAccountIds.length == viewModel.accounts.length) {
        _selectedAccountIds.clear();
      } else {
        _selectedAccountIds.clear();
        _selectedAccountIds.addAll(viewModel.accounts.map((a) => a.id));
      }
    });
  }

  void _generateQRCode() {
    if (_selectedAccountIds.isEmpty) return;

    final viewModel = context.read<AccountViewModel>();
    final selectedAccounts = viewModel.accounts
        .where((account) => _selectedAccountIds.contains(account.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportQRDisplayScreen(accounts: selectedAccounts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<AccountViewModel>();
    final accounts = viewModel.accounts;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Export to QR Code',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: accounts.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Header with info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate a QR code to transfer your accounts to another device securely.',
                        style: AppTheme.bodyMedium(
                          colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Select All checkbox
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: _toggleSelectAll,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value:
                                  _selectedAccountIds.length == accounts.length,
                              tristate:
                                  _selectedAccountIds.isNotEmpty &&
                                  _selectedAccountIds.length < accounts.length,
                              onChanged: (_) => _toggleSelectAll(),
                              activeColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedAccountIds.length == accounts.length
                                ? 'Deselect All'
                                : 'Select All (${_selectedAccountIds.length}/${accounts.length})',
                            style: AppTheme.bodyLarge(
                              colorScheme.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Account list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isSelected = _selectedAccountIds.contains(
                        account.id,
                      );
                      final icon = IconService.getIconForService(
                        account.issuer,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _toggleSelection(account.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
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
                                    onChanged: (_) =>
                                        _toggleSelection(account.id),
                                    activeColor: colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Icon
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
                                // Account info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.issuer,
                                        style: AppTheme.bodyLarge(
                                          colorScheme.onSurface,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        account.accountName,
                                        style: AppTheme.caption(
                                          colorScheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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

                // Bottom action bar
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
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: _selectedAccountIds.isEmpty
                          ? null
                          : _generateQRCode,
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      label: Text(
                        _selectedAccountIds.isEmpty
                            ? 'Select Accounts'
                            : 'Generate QR Code (${_selectedAccountIds.length})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor:
                            colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: colorScheme.onSurface
                            .withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts to Export',
              style: AppTheme.headlineMedium(colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add some accounts first, then you can export them to transfer to another device.',
              style: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Go Back',
                  style: AppTheme.bodyLarge(
                    colorScheme.onPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
