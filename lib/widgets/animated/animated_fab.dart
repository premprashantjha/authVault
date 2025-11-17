import 'package:flutter/material.dart';
import '../../theme/animations.dart';

class AnimatedFAB extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onTap;
  final Widget openIcon;
  final Widget closeIcon;

  const AnimatedFAB({super.key, required this.isOpen, this.onTap, required this.openIcon, required this.closeIcon});

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppAnimations.buttonAnimationDuration);
    if (widget.isOpen) {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (widget.isOpen) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  // Force white icon color to match app primary-button styling.
  // Use explicit white to avoid relying on colorScheme.onPrimary which may not be set.
  final fg = Colors.white;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: AppAnimations.standardCurve)),
      child: FloatingActionButton(
        onPressed: widget.onTap,
        // Ensure the icon color follows the app theme (typically white on primary)
        foregroundColor: fg,
        child: AnimatedCrossFade(
          firstChild: IconTheme(data: IconThemeData(color: fg), child: widget.openIcon),
          secondChild: IconTheme(data: IconThemeData(color: fg), child: widget.closeIcon),
          crossFadeState: widget.isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppAnimations.buttonAnimationDuration,
        ),
      ),
    );
  }
}
