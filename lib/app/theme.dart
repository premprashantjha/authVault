import 'package:flutter/material.dart';

class AppTheme {
 // Colors - Modern Purple
  static const Color primaryColor = Color(0xFF8B5CF6);    // Vibrant purple
  static const Color secondaryColor = Color(0xFFEC4899);  // Pink accent
  static const Color backgroundColor = Color(0xFF0F0F23); // Deep space
  static const Color surfaceColor = Color(0xFF1A1B2E);    // Dark purple-gray
  static const Color onSurfaceColor = Color(0xFFE2E8F0);  // Light gray
  static const Color errorColor = Color(0xFFFF6B6B);      // Coral red
  static const Color successColor = Color(0xFF51CF66);    // Bright green



  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurfaceColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onSurfaceColor,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF94A3B8),
  );

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        titleTextStyle: headlineMedium,
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withValues(alpha:0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: bodyMedium.copyWith(color: Colors.white54),
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
          textStyle: bodyLarge,
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