import 'package:flutter/material.dart';
import 'custom_page_route.dart';

class AnimationService {
  // Push page with style
  static Future<T?> pushWithStyle<T>(BuildContext context, Widget page, {PageTransitionStyle style = PageTransitionStyle.slideRight}) {
    return Navigator.of(context).push<T>(CustomPageRoute<T>(page: page, style: style));
  }

  static Future<T?> pushModal<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(CustomPageRoute<T>(page: page, style: PageTransitionStyle.fadeModal));
  }

  // Replace the current route with a new one using the same animated route wrapper.
  static Future<T?> pushReplacementWithStyle<T, TO>(BuildContext context, Widget page, {PageTransitionStyle style = PageTransitionStyle.slideRight, TO? result}) {
    return Navigator.of(context).pushReplacement<T, TO>(CustomPageRoute<T>(page: page, style: style), result: result as TO);
  }

  // Push and remove until predicate using styled route
  static Future<T?> pushAndRemoveUntilWithStyle<T>(BuildContext context, Widget page, RoutePredicate predicate, {PageTransitionStyle style = PageTransitionStyle.slideRight}) {
    return Navigator.of(context).pushAndRemoveUntil<T>(CustomPageRoute<T>(page: page, style: style), predicate);
  }

  // Pop the current route — kept for API symmetry and to centralize future exit animations.
  static void popWithStyle<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
