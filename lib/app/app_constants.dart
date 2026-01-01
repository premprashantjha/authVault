/// Application-wide constants for consistent spacing, sizing, and timing
/// Use these instead of magic numbers throughout the app
class AppConstants {
  // Prevent instantiation
  AppConstants._();
  
  /// Spacing values - use for padding, margins, gaps
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;
  
  /// Border radius values - use for consistent rounded corners
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
  
  /// Icon sizes - use for consistent icon sizing
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 20.0;
  static const double iconSizeLg = 24.0;
  static const double iconSizeXl = 32.0;
  static const double iconSizeXxl = 48.0;
  
  /// Common widget sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double fabSize = 56.0;
  
  /// OTP Card specific constants
  static const double otpCardPadding = 16.0;
  static const double otpCardSpacing = 12.0;
  static const double otpCardRadius = 20.0;
  static const double otpAvatarSize = 36.0;
  static const double otpTimerSize = 40.0;
  static const double otpFontSize = 24.0;
  
  /// Dialog and Modal constants
  static const double dialogRadius = 24.0;
  static const double dialogPadding = 24.0;
  static const double modalRadius = 28.0;
  
  /// Security constants
  static const Duration clipboardClearDuration = Duration(seconds: 30);
  static const Duration authRetryDelay = Duration(milliseconds: 500);
  static const Duration searchFocusDelay = Duration(milliseconds: 150);
  
  /// Opacity values
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityWatermark = 0.05;
}
