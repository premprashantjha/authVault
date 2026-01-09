import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';

class FilterSelectionResult {
  final Set<String> selectedIssuers;
  final bool favoritesOnly;
  final bool clearRequested;

  const FilterSelectionResult({
    required this.selectedIssuers,
    required this.favoritesOnly,
    this.clearRequested = false,
  });
}

class FilterModal extends StatefulWidget {
  final List<String> issuers;
  final Set<String> initialSelection;
  final bool favoritesOnly;

  const FilterModal({
    super.key,
    required this.issuers,
    required this.initialSelection,
    required this.favoritesOnly,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Set<String> _selection;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.initialSelection);
    _favoritesOnly = widget.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: AppConstants.getResponsiveModalHeight(context),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.getResponsiveRadius(context, large: 28.0, tablet: 32.0))
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppConstants.getResponsivePadding(context).left,
              AppConstants.getResponsiveSpacing(context, sm: 16.0, md: 20.0, lg: 24.0),
              AppConstants.getResponsivePadding(context).right * 0.7,
              AppConstants.getResponsiveSpacing(context),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Filter Accounts',
                  style: AppTheme.responsiveHeadlineMedium(context, theme.colorScheme.onSurface),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: _favoritesOnly ? 'Show all accounts' : 'Show favorites only',
                      icon: Icon(
                        _favoritesOnly ? Icons.star : Icons.star_border,
                        color: _favoritesOnly ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: AppConstants.getResponsiveIconSize(context),
                      ),
                      onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(
                        Icons.close, 
                        color: theme.colorScheme.onSurface,
                        size: AppConstants.getResponsiveIconSize(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppConstants.getResponsivePadding(context).left,
                0,
                AppConstants.getResponsivePadding(context).right,
                AppConstants.getResponsiveSpacing(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ISSUERS',
                    style: AppTheme.caption(theme.colorScheme.onSurface.withValues(alpha: 0.7)).copyWith(
                      letterSpacing: 0.8,
                      fontWeight: AppTheme.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.issuers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Add accounts to see issuer filters',
                        style: AppTheme.bodyMedium(theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        spacing: 10,
                        runSpacing: 10,
                        children: widget.issuers.map((issuer) {
                          final selected = _selection.contains(issuer);
                          return _FilterPill(
                            label: issuer,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selection.remove(issuer);
                                } else {
                                  _selection.add(issuer);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Footer actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      const FilterSelectionResult(
                        selectedIssuers: <String>{},
                        favoritesOnly: false,
                        clearRequested: true,
                      ),
                    );
                  },
                  child: Text(
                    'Clear',
                    style: AppTheme.bodyMedium(theme.colorScheme.primary).copyWith(
                      fontWeight: AppTheme.weightSemiBold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(110, 44),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      FilterSelectionResult(
                        selectedIssuers: Set<String>.from(_selection),
                        favoritesOnly: _favoritesOnly,
                      ),
                    );
                  },
                  child: Text(
                    'Apply Filters',
                    style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                      fontWeight: AppTheme.weightSemiBold,
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

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTheme.bodyMedium(
                  selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ).copyWith(
                  fontWeight: selected ? AppTheme.weightMedium : AppTheme.weightRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
