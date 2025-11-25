import 'package:flutter/material.dart';
import '../app/animations.dart';

class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const Skeleton({super.key, this.height = 16, this.width, this.borderRadius = const BorderRadius.all(Radius.circular(8))});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppAnimations.shimmerDuration)..repeat(reverse: false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);
  final highlight = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: [0.0, (_ctrl.value), 1.0],
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
            ),
          ),
        );
      },
    );
  }
}
