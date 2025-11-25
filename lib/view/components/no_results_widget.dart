import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../view_models/account_view_model.dart';

class NoResultsWidget extends StatelessWidget {
  final AccountViewModel viewModel;
  final VoidCallback onClearFilters;

  const NoResultsWidget({
    super.key,
    required this.viewModel,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.manage_search,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching accounts',
              style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
              textAlign: AppTheme.textAlignCenter,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different keyword or reset filters to see everything again.',
              style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: AppTheme.textAlignCenter,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
