import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Modern Purple (consistent across themes)
  static const Color primaryColor = Color(0xFF8B5CF6);    // Vibrant purple
  static const Color secondaryColor = Color(0xFFEC4899);  // Pink accent
  static const Color errorColor = Color(0xFFFF6B6B);      // Coral red
  static const Color successColor = Color(0xFF51CF66);    // Bright green

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF0F0F23); // Deep space
  static const Color darkSurfaceColor = Color(0xFF1A1B2E);    // Dark purple-gray
  static const Color darkOnSurfaceColor = Color(0xFFE2E8F0);  // Light gray

  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFFAFAFA); // Light gray
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);    // White
  static const Color lightOnSurfaceColor = Color(0xFF1A1B2E);  // Dark gray



  // Text Styles - Theme-aware
  static TextStyle headlineLarge(Color onSurfaceColor) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
    letterSpacing: -0.5,
  );

  static TextStyle headlineMedium(Color onSurfaceColor) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static TextStyle bodyLarge(Color onSurfaceColor) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  static TextStyle bodyMedium(Color onSurfaceColor) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static TextStyle caption(Color onSurfaceColor) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor.withValues(alpha: 0.6),
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        onSurface: darkOnSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 0,
        titleTextStyle: headlineMedium(darkOnSurfaceColor),
        iconTheme: const IconThemeData(color: darkOnSurfaceColor),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodyMedium(darkOnSurfaceColor).copyWith(color: Colors.white54),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        buttonColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: bodyLarge(darkOnSurfaceColor),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurfaceColor,
        onSurface: lightOnSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurfaceColor,
        elevation: 0,
        titleTextStyle: headlineMedium(lightOnSurfaceColor),
        iconTheme: const IconThemeData(color: lightOnSurfaceColor),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodyMedium(lightOnSurfaceColor).copyWith(color: Colors.grey[600]),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        buttonColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: bodyLarge(lightOnSurfaceColor),
        ),
      ),
    );
  }

  // Custom gradients
  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}