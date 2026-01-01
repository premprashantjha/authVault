import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // CDAC Brand Colors - Professional Navy Blue Palette
  static const Color primaryColor = Color(0xFF03176D); // CDAC Navy Blue
  static const Color primaryLight = Color(0xFF1E3A8A); // Lighter navy for accents
  static const Color primaryDark = Color(0xFF020F4D); // Darker navy for depth
  static const Color accentColor = Color(0xFF3B82F6); // Bright blue for highlights
  static const Color secondaryColor = Color(0xFF0EA5E9); // Sky blue for secondary actions
  static const Color tertiaryColor = Color(0xFF10B981); // Success green
  static const Color errorColor = Color(0xFFEF4444); // Error red
  static const Color warningColor = Color(0xFFF59E0B); // Warning amber
  static const Color successColor = tertiaryColor;
  
  // Neutral Colors - Professional Gray Scale
  static const Color neutralGray50 = Color(0xFFF8FAFC);
  static const Color neutralGray100 = Color(0xFFF1F5F9);
  static const Color neutralGray200 = Color(0xFFE2E8F0);
  static const Color neutralGray300 = Color(0xFFCBD5E1);
  static const Color neutralGray400 = Color(0xFF94A3B8);
  static const Color neutralGray500 = Color(0xFF64748B);
  static const Color neutralGray600 = Color(0xFF475569);
  static const Color neutralGray700 = Color(0xFF334155);
  static const Color neutralGray800 = Color(0xFF1E293B);
  static const Color neutralGray900 = Color(0xFF0F172A);

  // Typography - Professional & Clean
  static const String fontFamily = 'SF Pro Display'; // Fallback to system default
  
  // Text Alignment - Centralized Control
  static const TextAlign textAlignStart = TextAlign.start;
  static const TextAlign textAlignCenter = TextAlign.center;
  static const TextAlign textAlignEnd = TextAlign.end;
  
  // Content Alignment - Consistent Throughout App
  static const MainAxisAlignment mainAxisStart = MainAxisAlignment.start;
  static const MainAxisAlignment mainAxisCenter = MainAxisAlignment.center;
  static const MainAxisAlignment mainAxisEnd = MainAxisAlignment.end;
  static const MainAxisAlignment mainAxisSpaceBetween = MainAxisAlignment.spaceBetween;
  
  static const CrossAxisAlignment crossAxisStart = CrossAxisAlignment.start;
  static const CrossAxisAlignment crossAxisCenter = CrossAxisAlignment.center;
  static const CrossAxisAlignment crossAxisEnd = CrossAxisAlignment.end;
  
  // Default Text Alignment for Body Content (Left-aligned for professional look)
  static const TextAlign defaultTextAlign = TextAlign.start;
  static const CrossAxisAlignment defaultCrossAlign = CrossAxisAlignment.start;
  
  // Font Sizes - Moderate & Refined
  static const double fontSizeHeadlineLarge = 24.0;
  static const double fontSizeHeadlineMedium = 18.0;
  static const double fontSizeTitle = 16.0;
  static const double fontSizeBodyLarge = 15.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeSmall = 11.0;
  
  // Font Weights - Consistent & Elegant
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightLight = FontWeight.w300;

  // Light Theme Colors - Clean & Professional
  static const Color lightBackgroundColor = neutralGray50;
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightOnSurfaceColor = neutralGray900;

  // Dark Theme Colors - Sophisticated Navy
  static const Color darkBackgroundColor = Color(0xFF0A0E1F); // Very dark navy
  static const Color darkSurfaceColor = Color(0xFF141829); // Dark navy surface
  static const Color darkOnSurfaceColor = neutralGray100;

  // High-contrast Material 3 color schemes with CDAC branding
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor, // CDAC Navy
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBE3FF), // Light blue container
    onPrimaryContainer: primaryDark,
    secondary: secondaryColor, // Sky blue
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE0F2FE),
    onSecondaryContainer: Color(0xFF075985),
    tertiary: tertiaryColor, // Success green
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFD1FAE5),
    onTertiaryContainer: Color(0xFF065F46),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    background: lightBackgroundColor,
    onBackground: lightOnSurfaceColor,
    surface: lightSurfaceColor,
    onSurface: lightOnSurfaceColor,
    surfaceVariant: neutralGray100,
    onSurfaceVariant: neutralGray700,
    outline: neutralGray300,
    outlineVariant: neutralGray200,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: neutralGray800,
    onInverseSurface: neutralGray100,
    inversePrimary: accentColor,
    surfaceTint: primaryColor,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accentColor, // Brighter blue for dark mode
    onPrimary: Colors.white,
    primaryContainer: primaryColor, // CDAC Navy as container
    onPrimaryContainer: Color(0xFFDBE3FF),
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF075985),
    onSecondaryContainer: Color(0xFFE0F2FE),
    tertiary: tertiaryColor,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF065F46),
    onTertiaryContainer: Color(0xFFD1FAE5),
    error: Color(0xFFFCA5A5), // Lighter error for dark mode
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: Color(0xFFFEE2E2),
    background: darkBackgroundColor,
    onBackground: darkOnSurfaceColor,
    surface: darkSurfaceColor,
    onSurface: darkOnSurfaceColor,
    surfaceVariant: Color(0xFF1E293B),
    onSurfaceVariant: neutralGray300,
    outline: neutralGray600,
    outlineVariant: neutralGray700,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: neutralGray100,
    onInverseSurface: neutralGray900,
    inversePrimary: primaryColor,
    surfaceTint: accentColor,
  );

  static ThemeData get lightTheme => _buildTheme(_lightColorScheme);
  static ThemeData get darkTheme => _buildTheme(_darkColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      fontFamily: fontFamily,
    );
    
    final textTheme = base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: fontFamily,
    ).copyWith(
      displayLarge: TextStyle(fontSize: fontSizeHeadlineLarge, fontWeight: weightBold, height: 1.2, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: fontSizeHeadlineMedium, fontWeight: weightSemiBold, height: 1.3),
      titleLarge: TextStyle(fontSize: fontSizeTitle, fontWeight: weightSemiBold, height: 1.3),
      titleMedium: TextStyle(fontSize: fontSizeBodyLarge, fontWeight: weightMedium, height: 1.3),
      bodyLarge: TextStyle(fontSize: fontSizeBodyLarge, fontWeight: weightRegular, height: 1.5),
      bodyMedium: TextStyle(fontSize: fontSizeBody, fontWeight: weightRegular, height: 1.5),
      bodySmall: TextStyle(fontSize: fontSizeCaption, fontWeight: weightRegular, height: 1.4),
      labelLarge: TextStyle(fontSize: fontSizeBody, fontWeight: weightMedium, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: fontSizeCaption, fontWeight: weightMedium, letterSpacing: 0.5),
      labelSmall: TextStyle(fontSize: fontSizeSmall, fontWeight: weightMedium, letterSpacing: 0.5),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
        titleTextStyle: TextStyle(
          fontSize: fontSizeHeadlineMedium,
          fontWeight: weightSemiBold,
          color: colorScheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        elevation: isDark ? 2 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          fontSize: fontSizeHeadlineMedium,
          fontWeight: weightSemiBold,
          color: colorScheme.onSurface,
          fontFamily: fontFamily,
        ),
        contentTextStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onSurface,
          fontFamily: fontFamily,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onInverseSurface,
          fontFamily: fontFamily,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceVariant.withValues(alpha: 0.5)
            : colorScheme.surfaceVariant.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        hintStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontFamily: fontFamily,
        ),
        labelStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          elevation: isDark ? 2 : 1,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          textStyle: TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: weightSemiBold,
            fontFamily: fontFamily,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(48),
          textStyle: TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: weightSemiBold,
            fontFamily: fontFamily,
            letterSpacing: 0.2,
          ),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: fontSizeBody,
            fontWeight: weightSemiBold,
            fontFamily: fontFamily,
            letterSpacing: 0.1,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return colorScheme.primary;
          return colorScheme.outlineVariant;
        }),
        checkColor: MaterialStateProperty.all(colorScheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return colorScheme.onPrimary;
          return colorScheme.onSurfaceVariant;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceVariant;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return colorScheme.primary;
          return colorScheme.outlineVariant;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 32,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceVariant,
      ),
    );
  }

  // Text Style Helpers - Centralized & Consistent
  static TextStyle headlineLarge(Color color) => TextStyle(
        fontSize: fontSizeHeadlineLarge,
        fontWeight: weightBold,
        color: color,
        fontFamily: fontFamily,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle headlineMedium(Color color) => TextStyle(
        fontSize: fontSizeHeadlineMedium,
        fontWeight: weightSemiBold,
        color: color,
        fontFamily: fontFamily,
        height: 1.3,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: weightSemiBold,
        color: color,
        fontFamily: fontFamily,
        height: 1.3,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: fontSizeBodyLarge,
        fontWeight: weightRegular,
        color: color,
        fontFamily: fontFamily,
        height: 1.5,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: weightRegular,
        color: color,
        fontFamily: fontFamily,
        height: 1.5,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: weightRegular,
        color: color,
        fontFamily: fontFamily,
        height: 1.4,
      );

  static TextStyle small(Color color) => TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: weightRegular,
        color: color,
        fontFamily: fontFamily,
        height: 1.3,
      );

  // Gradients with CDAC branding
  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryColor, primaryLight, accentColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      
  static Gradient get subtleGradient => LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.1),
          accentColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
      
  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
