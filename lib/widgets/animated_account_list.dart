import 'package:flutter/material.dart';
import '../models/account.dart';

/// A custom animated list that smoothly animates reordering
/// Uses Flutter's built-in AnimatedList for future-proof implementation
class AnimatedAccountList extends StatefulWidget {
  final List<AccountWithOTP> items;
  final Widget Function(BuildContext, AccountWithOTP, Animation<double>) itemBuilder;

  const AnimatedAccountList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  @override
  State<AnimatedAccountList> createState() => _AnimatedAccountListState();
}

class _AnimatedAccountListState extends State<AnimatedAccountList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<AccountWithOTP> _displayedItems;

  @override
  void initState() {
    super.initState();
    _displayedItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(AnimatedAccountList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateList(oldWidget.items, widget.items);
  }

  void _updateList(List<AccountWithOTP> oldItems, List<AccountWithOTP> newItems) {
    // Create map for quick lookup by ID
    final newMap = {for (var item in newItems) item.account.id: item};

    // Find items to remove
    for (var i = _displayedItems.length - 1; i >= 0; i--) {
      final item = _displayedItems[i];
      if (!newMap.containsKey(item.account.id)) {
        // Item was removed
        final removedItem = _displayedItems.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildRemovedItem(removedItem, animation),
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    // Find items to add and reorder
    for (var i = 0; i < newItems.length; i++) {
      final newItem = newItems[i];
      final oldIndex = _displayedItems.indexWhere((item) => item.account.id == newItem.account.id);

      if (oldIndex == -1) {
        // Item is new, insert it
        _displayedItems.insert(i, newItem);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));
      } else if (oldIndex != i) {
        // Item exists but in wrong position, move it
        _displayedItems.removeAt(oldIndex);
        _displayedItems.insert(i, newItem);
        
        // Trigger rebuild to show new position
        if (mounted) {
          setState(() {});
        }
      } else {
        // Item is in correct position, just update it
        _displayedItems[i] = newItem;
      }
    }
  }

  Widget _buildRemovedItem(AccountWithOTP item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, item, animation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _displayedItems.length,
      itemBuilder: (context, index, animation) {
        if (index >= _displayedItems.length) {
          return const SizedBox.shrink();
        }
        
        final item = _displayedItems[index];
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: widget.itemBuilder(context, item, animation),
          ),
        );
      },
    );
  }
}
