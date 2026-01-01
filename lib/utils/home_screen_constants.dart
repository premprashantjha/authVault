import 'package:flutter/material.dart';

/// Constants for HomeScreen to avoid magic numbers and improve maintainability
class HomeScreenConstants {
  // Timing
  static const searchFocusDelay = Duration(milliseconds: 150);
  static const bannerAutoDismissDelay = Duration(milliseconds: 2500);
  
  // Spacing
  static const cardBottomSpacing = 12.0;
  static const listPadding = 16.0;
  static const sectionSpacing = 16.0;
  
  // Swipe Actions
  static const favoriteSwipeDirection = DismissDirection.startToEnd;
  static const deleteSwipeDirection = DismissDirection.endToStart;
  
  // UI Dimensions
  static const appBarLogoHeight = 32.0;
  static const filterIndicatorSize = 8.0;
  static const filterIndicatorPosition = 12.0;
  
  // Border Radius
  static const cardBorderRadius = 20.0;
  static const dialogBorderRadius = 20.0;
  static const modalBorderRadius = 24.0;
  
  HomeScreenConstants._(); // Prevent instantiation
}
