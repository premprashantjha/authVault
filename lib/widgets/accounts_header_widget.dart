import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../view_models/account_view_model.dart';
import 'search_bar_widget.dart';

class AccountsHeaderWidget extends StatelessWidget {
  final AccountViewModel viewModel;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearchVisible;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchClear;
  final int secondsRemaining;

  const AccountsHeaderWidget({
    super.key,
    required this.viewModel,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearchVisible,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCount = viewModel.filteredAccounts.length;
    final totalCount = viewModel.totalAccountCount;
    final countLabel = viewModel.hasActiveFilters
        ? '$filteredCount of $totalCount accounts'
        : '$totalCount Account${totalCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  countLabel,
                  style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Auto-refresh in ${secondsRemaining}s',
                style: AppTheme.caption(theme.colorScheme.onSurface),
              ),
            ],
          ),
          SearchBarWidget(
            controller: searchController,
            focusNode: searchFocusNode,
            isVisible: isSearchVisible,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
        ],
      ),
    );
  }
}
