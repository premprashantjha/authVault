import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
import '../models/account.dart';

// View Models
import '../view_models/account_view_model.dart';

// Services
import '../services/auth_service.dart';
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
    // Accounts are automatically loaded in the ViewModel constructor
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context) async {
    // Capture navigator synchronously to avoid using BuildContext after awaits
    final navigator = Navigator.of(context);

    // Get auth service from context or create new instance
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs: prefs);
    if (!mounted) return;

    await navigator.push(MaterialPageRoute(builder: (context) => SettingsScreen(authService: authService)));
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
        title: Text(
          'Authenticator',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
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
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
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
          // Removed verbose debug logging that was triggered on every rebuild
          if (viewModel.isLoading) {
            // Show lightweight skeleton placeholders while accounts load
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Skeleton(height: 88),
                  SizedBox(height: 12),
                  Skeleton(height: 88),
                  SizedBox(height: 12),
                  Skeleton(height: 88),
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
      // Haptic feedback for better UX
      HapticFeedback.lightImpact();
      
      // Show elegant message at top using MaterialBanner
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 22,
              ),
              const SizedBox(width: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
      
      // Auto-dismiss after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      });
      
      return;
    }
    
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (_isSearchVisible) {
      // Slight delay ensures the animation starts before requesting focus
      Future.delayed(const Duration(milliseconds: 150), () {
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
                    padding: const EdgeInsets.all(16),
                    child: AnimatedAccountList(
                      items: filteredAccounts,
                      itemBuilder: (context, item, animation) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.isFavorite ? Icons.star_border : Icons.star,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              item.isFavorite ? 'Unfavorite' : 'Favorite',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Toggle favorite
          HapticFeedback.mediumImpact();
          await viewModel.toggleFavorite(item.account.id);
          return false; // Don't dismiss
        } else {
          // Swipe left - Delete with confirmation
          HapticFeedback.mediumImpact();
          final confirmed = await _showQuickDeleteConfirmation(context, item);
          return confirmed; // Return true to dismiss if confirmed
        }
      },
      onDismissed: (direction) async {
        // Only called when confirmDismiss returns true (delete confirmed)
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
      },
      child: OTPCard(
        account: item,
        onDelete: () => _deleteAccountWithButton(context, item.account.id),
        onTap: () {},
        onFavoriteToggle: () => viewModel.toggleFavorite(item.account.id),
      ),
    );
  }

  Future<bool> _showQuickDeleteConfirmation(BuildContext context, AccountWithOTP item) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete ${item.account.issuer}?',
                style: AppTheme.headlineMedium(colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently remove this account and you won\'t be able to generate codes.',
                style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: AppTheme.bodyMedium(colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
      ),
    );
    
    return result ?? false;
  }

  void _clearFilters(AccountViewModel viewModel) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    viewModel.clearAllFilters();
  }

  void _navigateToQRScan(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const QRScanScreen()));
    // No explicit refresh needed - addAccount() in QR scan already calls _loadAccounts() which notifies listeners
  }

  void _showManualEntryDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

    // Check duplicate early and provide a clear message
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

  // Delete via button click (with dialog confirmation)
  Future<void> _deleteAccountWithButton(BuildContext context, String accountId) async {
    final viewModel = context.read<AccountViewModel>();
    final account = viewModel.filteredAccounts.firstWhere((a) => a.account.id == accountId);
    
    // Show confirmation dialog
    final confirmed = await _showQuickDeleteConfirmation(context, account);
    if (!confirmed) return;
    
    // Delete the account
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

// Manual Entry Form as a separate widget
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
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an issuer';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNameController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Account Name (e.g., user@gmail.com)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an account name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _secretKeyController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Secret Key (Base32)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onTap: _addAccount,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
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
      // Validate secret decodability before adding (give clearer feedback)
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