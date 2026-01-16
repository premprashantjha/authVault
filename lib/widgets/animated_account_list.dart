import 'package:flutter/material.dart';
import '../models/account.dart';

/// A simple list widget for displaying accounts
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
  late List<AccountWithOTP> _displayedItems;

  @override
  void initState() {
    super.initState();
    _displayedItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(AnimatedAccountList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!_areListsEqual(_displayedItems, widget.items)) {
      setState(() {
        _displayedItems = List.from(widget.items);
      });
    }
  }
  
  bool _areListsEqual(List<AccountWithOTP> a, List<AccountWithOTP> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].account.id != b[i].account.id || 
          a[i].isFavorite != b[i].isFavorite ||
          a[i].otp != b[i].otp) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _displayedItems.length,
      itemBuilder: (context, index) {
        final item = _displayedItems[index];
        const animation = AlwaysStoppedAnimation<double>(1.0);
        return widget.itemBuilder(context, item, animation);
      },
    );
  }
}
