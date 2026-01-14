import 'package:flutter/material.dart';

/// Utility class for responsive design across different iPhone screen sizes
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Screen size breakpoints for different iPhone models
  static const double smallScreenWidth = 375.0; // iPhone SE, iPhone 12 mini
  static const double mediumScreenWidth = 390.0; // iPhone 12, iPhone 13
  static const double largeScreenWidth = 428.0; // iPhone 12 Pro Max, iPhone 13 Pro Max

  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= smallScreenWidth) {
      return ScreenSize.small;
    } else if (width <= mediumScreenWidth) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  /// Check if device is a small screen (iPhone SE, iPhone 12 mini)
  static bool isSmallScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.small;
  }

  /// Check if device is a large screen (iPhone Pro Max models)
  static bool isLargeScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.large;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
  }) {
    final screenSize = getScreenSize(context);
    double padding;
    
    switch (screenSize) {
      case ScreenSize.small:
        padding = small;
        break;
      case ScreenSize.medium:
        padding = medium;
        break;
      case ScreenSize.large:
        padding = large;
        break;
    }
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, {
    double small = 14.0,
    double medium = 16.0,
    double large = 18.0,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }

  /// Get responsive icon size based on screen size
  static double getResponsiveIconSize(BuildContext context, {
    double small = 20.0,
    double medium = 24.0,
    double large = 28.0,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }

  /// Get responsive card height for OTP cards
  static double getOTPCardHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return 80.0; // Compact for small screens
      case ScreenSize.medium:
        return 88.0; // Standard height
      case ScreenSize.large:
        return 96.0; // More spacious for large screens
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return 44.0; // iOS minimum touch target
      case ScreenSize.medium:
        return 48.0; // Standard button height
      case ScreenSize.large:
        return 52.0; // Larger for better accessibility
    }
  }

  /// Get safe area padding for different iPhone models
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Check if device has a notch (iPhone X and later)
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 20; // Standard status bar height is 20
  }

  /// Get responsive app bar height considering safe area
  static double getAppBarHeight(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    return kToolbarHeight + safeAreaTop;
  }

  /// Get responsive bottom padding for floating action button
  static double getFABBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    return safeAreaBottom > 0 ? safeAreaBottom + 16.0 : 16.0;
  }

  /// Get responsive modal height (useful for bottom sheets)
  static double getModalHeight(BuildContext context, {double factor = 0.9}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return (screenHeight - safeAreaTop - safeAreaBottom) * factor;
  }

  /// Get responsive grid column count for different layouts
  static int getGridColumnCount(BuildContext context, {
    int smallColumns = 1,
    int mediumColumns = 2,
    int largeColumns = 2,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return smallColumns;
      case ScreenSize.medium:
        return mediumColumns;
      case ScreenSize.large:
        return largeColumns;
    }
  }
}

/// Screen size categories for responsive design
enum ScreenSize {
  small,  // iPhone SE, iPhone 12 mini
  medium, // iPhone 12, iPhone 13, iPhone 14
  large,  // iPhone Pro Max models
}

/// Extension to make responsive utilities easier to use
extension ResponsiveContext on BuildContext {
  /// Get screen size category
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  
  /// Check if small screen
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
  
  /// Check if large screen
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
  
  /// Check if device has notch
  bool get hasNotch => ResponsiveUtils.hasNotch(this);
  
  /// Get responsive padding
  EdgeInsets responsivePadding({
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
  }) => ResponsiveUtils.getResponsivePadding(this, small: small, medium: medium, large: large);
  
  /// Get responsive font size
  double responsiveFontSize({
    double small = 14.0,
    double medium = 16.0,
    double large = 18.0,
  }) => ResponsiveUtils.getResponsiveFontSize(this, small: small, medium: medium, large: large);
  
  /// Get responsive spacing
  double responsiveSpacing({
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
  }) => ResponsiveUtils.getResponsiveSpacing(this, small: small, medium: medium, large: large);
  
  /// Get responsive icon size
  double responsiveIconSize({
    double small = 20.0,
    double medium = 24.0,
    double large = 28.0,
  }) => ResponsiveUtils.getResponsiveIconSize(this, small: small, medium: medium, large: large);
}