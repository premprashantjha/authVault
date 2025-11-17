import 'package:flutter/animation.dart';

class AppAnimations {
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const Duration listStaggerDuration = Duration(milliseconds: 100);
  static const Duration shimmerDuration = Duration(milliseconds: 1200);
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
