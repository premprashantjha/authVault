import 'package:flutter/material.dart';
import '../../view_models/account_view_model.dart';
import 'search_bar_widget.dart';

class AccountsHeaderWidget extends StatelessWidget {
  final AccountViewModel viewModel;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearchVisible;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchClear;

  const AccountsHeaderWidget({
    super.key,
    required this.viewModel,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearchVisible,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return 
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), // Reduced vertical padding from 16 to 8
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SearchBarWidget(
            controller: searchController,
            focusNode: searchFocusNode,
            isVisible: isSearchVisible,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
        );
  }
}
