import 'dart:async';
import 'package:flutter/material.dart';
import '../app/animations.dart';
import '../../models/account.dart';

typedef StaggeredItemBuilder<T> = Widget Function(BuildContext context, int index, T item, Animation<double> animation);

/// Controller for programmatic operations on a [StaggeredList].
class StaggeredListController<T> {
  _StaggeredListState<T>? _state;

  /// Remove the item at [index] with the provided [removedItemBuilder] visual.
  /// The Future completes after the removal animation duration.
  Future<void> removeAt(int index, Widget Function(T item, Animation<double> animation) removedItemBuilder) async {
    if (_state == null) return;
    await _state!._removeAt(index, removedItemBuilder);
  }
}

class StaggeredList<T> extends StatefulWidget {
  final List<T> items;
  final StaggeredItemBuilder<T> itemBuilder;
  final Duration staggerDuration;
  final StaggeredListController<T>? controller;

  const StaggeredList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.staggerDuration = AppAnimations.listStaggerDuration,
    this.controller,
  });

  @override
  State<StaggeredList<T>> createState() => _StaggeredListState<T>();
  
  /// Compare items semantically instead of by identity
  static bool _itemsEqual(dynamic a, dynamic b) {
    if (a is AccountWithOTP && b is AccountWithOTP) {
      return a.account.id == b.account.id;
    }
    return identical(a, b);
  }
}

class _StaggeredListState<T> extends State<StaggeredList<T>> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late List<T> _items;

  @override
  void initState() {
    super.initState();
    _items = [];
    widget.controller?._state = this;
    // Stagger insert items after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertItems());
  }

  @override
  void didUpdateWidget(covariant StaggeredList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If incoming items list has changed since last build, reconcile differences.
    // Handle the common cases: new items appended or items removed.
    final newItems = widget.items;

    // If we currently have no items but newItems has entries, insert them.
    if (_items.isEmpty && newItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _insertItems());
      return;
    }

    // If items length increased, insert new trailing items.
    if (newItems.length > _items.length) {
      final start = _items.length;
      for (var i = start; i < newItems.length; i++) {
        final item = newItems[i];
        _items.insert(i, item);
        _listKey.currentState?.insertItem(i, duration: widget.staggerDuration);
      }
      return;
    }

    // If items length decreased, remove trailing items.
    if (newItems.length < _items.length) {
      for (var i = _items.length - 1; i >= newItems.length; i--) {
        final removed = _items.removeAt(i);
        final duration = widget.staggerDuration * 1;
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0.0, 0.06)).animate(animation),
              child: widget.itemBuilder(context, i, removed, animation),
            ),
          ),
          duration: duration,
        );
      }
      return;
    }

    // If counts are equal, perform a best-effort diff: replace items that differ in identity.
    for (var i = 0; i < newItems.length; i++) {
      if (!StaggeredList._itemsEqual(newItems[i], _items[i])) {
        // Replace item at i by removing and inserting at same index.
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0.0, 0.06)).animate(animation),
              child: widget.itemBuilder(context, i, removed, animation),
            ),
          ),
          duration: widget.staggerDuration,
        );
        // insert the new item
        _items.insert(i, newItems[i]);
        _listKey.currentState?.insertItem(i, duration: widget.staggerDuration);
      } else {
        // Items are equal by ID, just update the reference in _items
        // without triggering animation
        _items[i] = newItems[i];
      }
    }
  }

  Future<void> _insertItems() async {
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      _items.insert(i, item);
      _listKey.currentState?.insertItem(i, duration: widget.staggerDuration);
      await Future.delayed(widget.staggerDuration);
    }
  }

  Future<void> _removeAt(int index, Widget Function(T item, Animation<double> animation) removedItemBuilder) async {
    if (index < 0 || index >= _items.length) return;
    final removed = _items.removeAt(index);
    final duration = widget.staggerDuration * 1;
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0.0, 0.06)).animate(animation),
          child: removedItemBuilder(removed, animation),
        ),
      ),
      duration: duration,
    );
    await Future.delayed(duration);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        final item = _items[index];
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
            child: widget.itemBuilder(context, index, item, animation),
          ),
        );
      },
    );
  }
}
