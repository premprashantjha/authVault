import 'package:flutter/material.dart';
import '../app/animations.dart';

typedef ButtonCallback = Future<void> Function();

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final Duration duration;

  const AnimatedButton({super.key, required this.child, this.onTap, this.enabled = true, this.duration = AppAnimations.buttonAnimationDuration});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration, reverseDuration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: AppAnimations.standardCurve));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onTap == null) return;
    try {
      await _ctrl.forward();
      await _ctrl.reverse();
      widget.onTap?.call();
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(12),
          child: widget.child,
        ),
      ),
    );
  }
}
