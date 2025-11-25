import 'package:authenticator/services/totp_service.dart';
import 'package:authenticator/widgets/animated/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
import '../models/account.dart';

// View Models
import '../view_models/account_view_model.dart';

// Services
import '../services/auth_service.dart';

// Components
import 'components/search_bar_widget.dart';
import 'components/empty_state_widget.dart';
import 'components/no_results_widget.dart';
import 'components/accounts_header_widget.dart';
import 'components/add_account_modal.dart';
import 'components/manual_entry_form.dart';

// Widgets
import 'widget/otp_card.dart';
import '../widgets/animated/staggered_list.dart';
import '../widgets/animated/animated_fab.dart';
import '../widgets/animated/skeleton.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/filter_modal.dart';

// Screens
import 'qr_scan_screen.dart';
import 'settings_screen.dart';

// Animations
import '../animations/animation_service.dart';
import '../animations/custom_page_route.dart';

// Theme
import '../app/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _fabOpen = false;
  final StaggeredListController<AccountWithOTP> _listController = StaggeredListController<AccountWithOTP>();
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

    await navigator.push(CustomPageRoute(page: SettingsScreen(authService: authService), style: PageTransitionStyle.scale));
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
        // Accounts List
        Expanded(
          child: filteredAccounts.isEmpty
              ? NoResultsWidget(
                  viewModel: viewModel,
                  onClearFilters: () => _clearFilters(viewModel),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: StaggeredList<AccountWithOTP>(
                    key: ValueKey('accounts_${filteredAccounts.length}_${viewModel.hasActiveFilters}'),
                    controller: _listController,
                    items: filteredAccounts,
                    itemBuilder: (context, index, item, animation) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OTPCard(
                          account: item,
                          onDelete: () => _deleteAccount(context, item.account.id),
                          onTap: () {},
                          onFavoriteToggle: () => viewModel.toggleFavorite(item.account.id),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _clearFilters(AccountViewModel viewModel) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    viewModel.clearAllFilters();
  }

  void _navigateToQRScan(BuildContext context) async {
    await AnimationService.pushWithStyle(context, const QRScanScreen(), style: PageTransitionStyle.slideRight);
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

  Future<void> _deleteAccount(BuildContext context, String accountId) async {
    final viewModel = context.read<AccountViewModel>();
    final index = viewModel.filteredAccounts.indexWhere((a) => a.account.id == accountId);

    if (index != -1) {
      try {
        await _listController.removeAt(index, (removedItem, animation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OTPCard(
              account: removedItem,
              onDelete: () {},
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          );
        });
      } catch (_) {
        // ignore animation errors and continue to delete
      }
    }

    final success = await viewModel.deleteAccount(accountId);
    if (!mounted) return;

    if (success) {
      CustomSnackbar.show(
        context,
        title: 'Account Deleted',
        message: 'This account and its OTPs were removed from Authenticator.',
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