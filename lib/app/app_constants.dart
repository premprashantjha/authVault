import 'package:flutter/material.dart';

/// Application-wide constants for consistent spacing, sizing, and timing
/// Use these instead of magic numbers throughout the app
class AppConstants {
  // Prevent instantiation
  AppConstants._();
  
  /// Screen size breakpoints for responsive design
  static const double smallScreenWidth = 360.0;  // Small phones
  static const double mediumScreenWidth = 400.0; // Standard phones
  static const double largeScreenWidth = 480.0;  // Large phones/small tablets
  static const double tabletWidth = 600.0;       // Tablets
  
  /// Screen height breakpoints
  static const double shortScreenHeight = 640.0;  // iPhone SE
  static const double mediumScreenHeight = 800.0; // Standard phones
  static const double tallScreenHeight = 900.0;   // Tall phones
  
  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context, {
    double xs = 4.0,
    double sm = 8.0,
    double md = 16.0,
    double lg = 24.0,
    double xl = 32.0,
    double xxl = 48.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return xs;
    if (screenWidth < mediumScreenWidth) return sm;
    if (screenWidth < largeScreenWidth) return md;
    if (screenWidth < tabletWidth) return lg;
    return xl;
  }
  
  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double small = 12.0,
    double medium = 16.0,
    double large = 20.0,
    double tablet = 24.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double padding;
    if (screenWidth < smallScreenWidth) {
      padding = small;
    } else if (screenWidth < largeScreenWidth) {
      padding = medium;
    } else if (screenWidth < tabletWidth) {
      padding = large;
    } else {
      padding = tablet;
    }
    return EdgeInsets.all(padding);
  }
  
  /// Static spacing values - use for fixed layouts
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;
  
  /// Responsive border radius
  static double getResponsiveRadius(BuildContext context, {
    double small = 8.0,
    double medium = 12.0,
    double large = 16.0,
    double tablet = 20.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return small;
    if (screenWidth < largeScreenWidth) return medium;
    if (screenWidth < tabletWidth) return large;
    return tablet;
  }
  
  /// Static border radius values
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 28.0;
  
  /// Animation durations - use for consistent timing
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);
  static const Duration durationVerySlow = Duration(milliseconds: 500);
  
  /// Elevation values - use for shadows and depth
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;
  static const double elevationVeryHigh = 8.0;
  
  /// Responsive icon sizes
  static double getResponsiveIconSize(BuildContext context, {
    double small = 18.0,
    double medium = 24.0,
    double large = 28.0,
    double tablet = 32.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return small;
    if (screenWidth < largeScreenWidth) return medium;
    if (screenWidth < tabletWidth) return large;
    return tablet;
  }
  
  /// Static icon sizes
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 20.0;
  static const double iconSizeLg = 24.0;
  static const double iconSizeXl = 32.0;
  static const double iconSizeXxl = 48.0;
  
  /// Responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < shortScreenHeight) return 44.0; // iOS minimum
    if (screenWidth < smallScreenWidth) return 46.0;
    if (screenWidth < largeScreenWidth) return 48.0;
    return 52.0;
  }
  
  /// Responsive input height
  static double getResponsiveInputHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight < shortScreenHeight) return 48.0;
    if (screenWidth < smallScreenWidth) return 52.0;
    if (screenWidth < largeScreenWidth) return 56.0;
    return 60.0;
  }
  
  /// Static widget sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double fabSize = 56.0;
  
  /// Responsive OTP Card dimensions - MINIMUM HEIGHT ONLY (Industry Best Practice)
  static double getResponsiveOTPCardMinHeight(context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Minimum height only - content can expand naturally
    if (screenHeight < shortScreenHeight) return 70.0; // Compact for small screens
    if (screenWidth < smallScreenWidth) return 76.0;
    if (screenWidth < largeScreenWidth) return 80.0;
    return 84.0; // Minimum for large screens
  }
  
  /// DEPRECATED: Use getResponsiveOTPCardMinHeight instead
  /// This method enforces fixed height which causes overflow
  @Deprecated("Use getResponsiveOTPCardMinHeight instead - fixed heights cause overflow")
  static double getResponsiveOTPCardHeight(BuildContext context) {
    return getResponsiveOTPCardMinHeight(context);
  }
  
  static double getResponsiveOTPCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return 12.0;
    if (screenWidth < largeScreenWidth) return 16.0;
    return 20.0;
  }
  
  static double getResponsiveOTPFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return 20.0;
    if (screenWidth < largeScreenWidth) return 24.0;
    return 28.0;
  }
  
  /// Static OTP Card constants
  static const double otpCardPadding = 16.0;
  static const double otpCardSpacing = 12.0;
  static const double otpCardRadius = 20.0;
  static const double otpAvatarSize = 36.0;
  static const double otpTimerSize = 40.0;
  static const double otpFontSize = 24.0;
  
  /// Responsive dialog dimensions - PROPER FLEXIBLE APPROACH
  static double getResponsiveDialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return screenWidth * 0.95; // Almost full width on small screens
    if (screenWidth < largeScreenWidth) return screenWidth * 0.9;
    if (screenWidth < tabletWidth) return screenWidth * 0.8;
    return 480.0; // Max width for tablets, but can be smaller
  }
  
  /// DEPRECATED: Use getResponsiveDialogMaxWidth instead
  @Deprecated("Use getResponsiveDialogMaxWidth instead - fixed widths cause layout issues")
  static double getResponsiveDialogWidth(BuildContext context) {
    return getResponsiveDialogMaxWidth(context);
  }
  
  static double getResponsiveDialogPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return 16.0;
    if (screenWidth < largeScreenWidth) return 20.0;
    return 24.0;
  }
  
  /// Static dialog constants
  static const double dialogRadius = 24.0;
  static const double dialogPadding = 24.0;
  static const double modalRadius = 28.0;
  
  /// Responsive modal height
  static double getResponsiveModalHeight(BuildContext context, {double factor = 0.9}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    
    if (screenHeight < shortScreenHeight) return availableHeight * 0.95;
    if (screenHeight < mediumScreenHeight) return availableHeight * factor;
    return availableHeight * 0.85;
  }
  
  /// Safe area helpers
  static EdgeInsets getResponsiveSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  static double getResponsiveFABBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    
    double basePadding = screenWidth < smallScreenWidth ? 12.0 : 16.0;
    return safeAreaBottom > 0 ? safeAreaBottom + basePadding : basePadding;
  }
  
  /// Security constants
  static const Duration clipboardClearDuration = Duration(seconds: 30);
  static const Duration authRetryDelay = Duration(milliseconds: 500);
  static const Duration searchFocusDelay = Duration(milliseconds: 150);
  
  /// Opacity values
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityWatermark = 0.05;
  
  /// Device type detection
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < smallScreenWidth;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletWidth;
  }
  
  static bool isShortScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < shortScreenHeight;
  }
  
  /// Grid columns for responsive layouts
  static int getResponsiveGridColumns(BuildContext context, {
    int smallColumns = 1,
    int mediumColumns = 2,
    int largeColumns = 2,
    int tabletColumns = 3,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < smallScreenWidth) return smallColumns;
    if (screenWidth < largeScreenWidth) return mediumColumns;
    if (screenWidth < tabletWidth) return largeColumns;
    return tabletColumns;
  }
}
