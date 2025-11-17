import 'package:flutter/material.dart';
import '../theme/animations.dart';

enum PageTransitionStyle { slideRight, slideLeft, fadeModal, scale }

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionStyle style;

  CustomPageRoute({required this.page, this.style = PageTransitionStyle.slideRight})
      : super(
          transitionDuration: AppAnimations.pageTransitionDuration,
          reverseTransitionDuration: AppAnimations.pageTransitionDuration,
          pageBuilder: (context, anim, secAnim) => page,
          transitionsBuilder: (context, anim, secAnim, child) {
            final curved = CurvedAnimation(parent: anim, curve: AppAnimations.standardCurve);

            switch (style) {
              case PageTransitionStyle.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(curved),
                  child: child,
                );

              case PageTransitionStyle.fadeModal:
                return FadeTransition(opacity: curved, child: child);

              case PageTransitionStyle.scale:
                return ScaleTransition(scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved), child: child);

              case PageTransitionStyle.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
                  child: child,
                );
            }
          },
        );
}
