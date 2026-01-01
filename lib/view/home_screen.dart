import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Models
import '../models/account.dart';

// View Models
import '../view_models/account_view_model.dart';

// Services
import '../services/totp_service.dart';

// Widgets
import '../widgets/animated_button.dart';
import '../widgets/animated_fab.dart';
import '../widgets/skeleton.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/filter_modal.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/no_results_widget.dart';
import '../widgets/accounts_header_widget.dart';
import '../widgets/add_account_modal.dart';
import '../widgets/otp_card.dart';
import '../widgets/animated_account_list.dart';

// Screens
import 'qr_scan_screen.dart';
import 'settings_screen.dart';

// Theme
import '../app/theme.dart';
import '../app/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _fabOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _openFilterModal() async {
    final viewModel = context.read<AccountViewModel>();
    final result = await showModalBottomSheet<FilterSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterModal(
          issuers: viewModel.issuerFilters,
          initialSelection: viewModel.selectedIssuers,
          favoritesOnly: viewModel.favoritesOnly,
        );
      },
    );

    if (result == null) return;

    if (result.clearRequested) {
      viewModel.setFilters(issuers: <String>{}, favoritesOnly: false);
      return;
    }

    if (!mounted) return;

    viewModel.setFilters(issuers: result.selectedIssuers, favoritesOnly: result.favoritesOnly);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo1.png',
              height: AppConstants.iconSizeXl,
              fit: BoxFit.contain,
            ),
            SizedBox(width: AppConstants.otpCardSpacing),
            Text(
              'Authenticator',
              style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isSearchVisible ? 'Close search' : 'Search accounts',
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _toggleSearchBar,
          ),
          Consumer<AccountViewModel>(
            builder: (context, viewModel, _) {
              final hasFilters = viewModel.hasFilterSelections;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Filter accounts',
                    icon: Icon(
                      Icons.filter_alt,
                      color: hasFilters ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                    onPressed: _openFilterModal,
                  ),
                  if (hasFilters)
                    Positioned(
                      right: AppConstants.otpCardSpacing,
                      top: AppConstants.otpCardSpacing,
                      child: Container(
                        width: AppConstants.spaceSm,
                        height: AppConstants.spaceSm,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: Consumer<AccountViewModel>(
        builder: (context, viewModel, child) {
          try {
            if (viewModel.isLoading) {
              return Padding(
                padding: EdgeInsets.all(AppConstants.spaceMd),
                child: Column(
                  children: [
                    Skeleton(height: AppConstants.iconSizeXxl * 2 - 8),
                    SizedBox(height: AppConstants.otpCardSpacing),
                    Skeleton(height: AppConstants.iconSizeXxl * 2 - 8),
                    SizedBox(height: AppConstants.otpCardSpacing),
                    Skeleton(height: AppConstants.iconSizeXxl * 2 - 8),
                  ],
                ),
              );
            }

            if (!viewModel.hasAccounts) {
              return EmptyStateWidget(
                onAddAccount: () => _showAddAccountOptions(context),
              );
            }

            return _buildAccountsList(viewModel);
          } catch (e, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: AppConstants.iconSizeXxl * 2, color: Colors.red),
                  SizedBox(height: AppConstants.spaceMd),
                  Text('Error: $e'),
                  SizedBox(height: AppConstants.spaceMd),
                  ElevatedButton(
                    onPressed: () => viewModel.reloadAfterUnlock(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: AnimatedFAB(
        isOpen: _fabOpen,
        onTap: () {
          setState(() => _fabOpen = !_fabOpen);
          _showAddAccountOptions(context).whenComplete(() {
            if (mounted) setState(() => _fabOpen = false);
          });
        },
        openIcon: const Icon(Icons.add, size: 28),
        closeIcon: const Icon(Icons.close, size: 28),
      ),
    );
  }

  void _toggleSearchBar() {
    final viewModel = context.read<AccountViewModel>();
    if (viewModel.totalAccountCount == 0 && !_isSearchVisible) {
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: AppConstants.iconSizeMd + 2,
              ),
              SizedBox(width: AppConstants.otpCardSpacing),
              Expanded(
                child: Text(
                  'Add accounts to start searching',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: AppConstants.otpCardSpacing),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      });
      
      return;
    }
    
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (_isSearchVisible) {
      Future.delayed(AppConstants.searchFocusDelay, () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else {
      _searchFocusNode.unfocus();
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        viewModel.setSearchQuery('');
      }
    }
  }

  Future<void> _showAddAccountOptions(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddAccountModal(
        onScanQR: () {
          Navigator.pop(context);
          _navigateToQRScan(context);
        },
        onManualEntry: () {
          Navigator.pop(context);
          _showManualEntryDialog(context);
        },
      ),
    );
  }

  Widget _buildAccountsList(AccountViewModel viewModel) {
    final filteredAccounts = viewModel.filteredAccounts;
    final secondsRemaining = viewModel.accountsWithOTP.isNotEmpty
        ? viewModel.accountsWithOTP.first.secondsRemaining
        : 30;

    return Column(
      children: [
        // Header
        AccountsHeaderWidget(
          viewModel: viewModel,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          isSearchVisible: _isSearchVisible,
          onSearchChanged: viewModel.setSearchQuery,
          onSearchClear: () {
            _searchController.clear();
            viewModel.setSearchQuery('');
          },
          secondsRemaining: secondsRemaining,
        ),
        // Accounts List with Pull-to-Refresh
        Expanded(
          child: filteredAccounts.isEmpty
              ? NoResultsWidget(
                  viewModel: viewModel,
                  onClearFilters: () => _clearFilters(viewModel),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await viewModel.reloadAfterUnlock();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spaceMd),
                    child: AnimatedAccountList(
                      items: filteredAccounts,
                      itemBuilder: (context, item, animation) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.otpCardSpacing),
                          child: _buildSwipeableCard(context, item, viewModel),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSwipeableCard(BuildContext context, AccountWithOTP item, AccountViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dismissible(
      key: Key(item.account.id),
      background: _buildSwipeBackground(item.isFavorite, AppTheme.primaryColor, Alignment.centerLeft),
      secondaryBackground: _buildSwipeBackground(false, colorScheme.error, Alignment.centerRight, isDelete: true),
      confirmDismiss: (direction) => _handleSwipeDismiss(direction, item, viewModel),
      onDismissed: (direction) => _handleDismissed(direction, item, viewModel),
      child: OTPCard(
        key: ValueKey('${item.account.id}_${item.isFavorite}'), // Force rebuild when favorite changes
        account: item,
        onDelete: () => _deleteAccountWithButton(context, item.account.id),
        onTap: () {},
        onFavoriteToggle: () => viewModel.toggleFavorite(item.account.id),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isFavorite, Color color, Alignment alignment, {bool isDelete = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.otpCardSpacing),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.otpCardRadius),
      ),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignment == Alignment.centerLeft ? AppConstants.spaceLg : 0,
        right: alignment == Alignment.centerRight ? AppConstants.spaceLg : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDelete ? Icons.delete_outline : (isFavorite ? Icons.star_border : Icons.star),
            color: Colors.white,
            size: AppConstants.iconSizeLg + 4,
          ),
          SizedBox(height: AppConstants.spaceXs),
          Text(
            isDelete ? 'Delete' : (isFavorite ? 'Unfavorite' : 'Favorite'),
            style: TextStyle(
              color: Colors.white,
              fontSize: AppConstants.otpCardSpacing,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleSwipeDismiss(DismissDirection direction, AccountWithOTP item, AccountViewModel viewModel) async {
    if (direction == DismissDirection.startToEnd) {
      HapticFeedback.mediumImpact();
      await viewModel.toggleFavorite(item.account.id);
      return false;
    } else {
      HapticFeedback.mediumImpact();
      final confirmed = await _showQuickDeleteConfirmation(context, item);
      return confirmed;
    }
  }

  Future<void> _handleDismissed(DismissDirection direction, AccountWithOTP item, AccountViewModel viewModel) async {
    if (direction == DismissDirection.endToStart) {
      final success = await viewModel.deleteAccount(item.account.id);
      if (mounted && success) {
        CustomSnackbar.show(
          context,
          title: 'Account Deleted',
          message: '${item.account.issuer} was removed from Authenticator.',
          type: SnackbarType.error,
        );
      }
    }
  }

  Future<bool> _showQuickDeleteConfirmation(BuildContext context, AccountWithOTP item) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(item: item),
    ) ?? false;
  }

  void _clearFilters(AccountViewModel viewModel) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    viewModel.clearAllFilters();
  }

  void _navigateToQRScan(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QRScanScreen())
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
        title: Text('Add Account', style: AppTheme.headlineMedium(theme.colorScheme.onSurface)),
        content: ManualEntryForm(
          onAccountAdded: (account) {
            Navigator.pop(dialogContext);
            // Use the parent context, not the dialog context
            _addAccount(account);
          },
        ),
      ),
    );
  }

  void _addAccount(Account account) async {
    final viewModel = context.read<AccountViewModel>();

    final exists = await viewModel.accountExists(account);
    if (exists) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: account.issuer,
        message: 'This account is already in your vault',
        type: SnackbarType.info,
      );
      return;
    }

    final success = await viewModel.addAccount(account);

    if (!mounted) return;

    if (success) {
      CustomSnackbar.show(
        context,
        title: '${account.issuer} Added',
        message: 'Your account has been securely added to the vault',
        type: SnackbarType.success,
      );
    } else {
      CustomSnackbar.show(
        context,
        title: 'Failed',
        message: 'Unable to add account. Please try again.',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _deleteAccountWithButton(BuildContext context, String accountId) async {
    final viewModel = context.read<AccountViewModel>();
    final account = viewModel.filteredAccounts.firstWhere((a) => a.account.id == accountId);
    
    final confirmed = await _showQuickDeleteConfirmation(context, account);
    if (!confirmed) return;
    
    final success = await viewModel.deleteAccount(accountId);
    if (!mounted) return;

    if (success) {
      CustomSnackbar.show(
        context,
        title: 'Account Deleted',
        message: '${account.account.issuer} was removed from Authenticator.',
        type: SnackbarType.error,
      );
    }
  }
}
class ManualEntryForm extends StatefulWidget {
  final Function(Account) onAccountAdded;

  const ManualEntryForm({super.key, required this.onAccountAdded});

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _secretKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _issuerController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Issuer (e.g., Google)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an issuer';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.spaceMd),
          TextFormField(
            controller: _accountNameController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Account Name (e.g., user@gmail.com)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an account name';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.spaceMd),
          TextFormField(
            controller: _secretKeyController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Secret Key (Base32)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
              hintText: 'JBSWY3DPEHPK3PXP',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a secret key';
              }
              // Basic Base32 validation
              if (!RegExp(r'^[A-Z2-7]+=*$').hasMatch(value.toUpperCase())) {
                return 'Invalid secret key format';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.spaceLg),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onTap: _addAccount,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: AppConstants.radiusMd + 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      'Add Account',
                      style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                        fontWeight: AppTheme.weightSemiBold,
                      ),
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAccount() {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        issuer: _issuerController.text.trim(),
        accountName: _accountNameController.text.trim(),
        secretKey: _secretKeyController.text.trim().toUpperCase(),
      );
      
      final totp = TOTPService();
      if (!totp.validateSecret(account.secretKey)) {
        CustomSnackbar.show(
          context,
          title: 'Invalid Secret Key',
          message: 'Please check the Base32 format and try again',
          type: SnackbarType.error,
        );
        return;
      }

      widget.onAccountAdded(account);
    }
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }
}

// Delete Confirmation Dialog Widget
class _DeleteConfirmationDialog extends StatelessWidget {
  final AccountWithOTP item;

  const _DeleteConfirmationDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg)),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppConstants.fabSize,
              height: AppConstants.fabSize,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: AppConstants.iconSizeLg + 4,
              ),
            ),
            SizedBox(height: AppConstants.spaceMd),
            Text(
              'Delete ${item.account.issuer}?',
              style: AppTheme.headlineMedium(colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spaceSm),
            Text(
              'This will permanently remove this account and you won\'t be able to generate codes.',
              style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spaceLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.radiusMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: Text('Cancel', style: AppTheme.bodyMedium(colorScheme.onSurface)),
                  ),
                ),
                SizedBox(width: AppConstants.otpCardSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      padding: EdgeInsets.symmetric(vertical: AppConstants.radiusMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      ),
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}