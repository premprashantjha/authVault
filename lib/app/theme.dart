import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Brand palette
  static const Color primaryColor = Color(0xFF7C3AED);
  static const Color secondaryColor = Color(0xFFEC4899);
  static const Color tertiaryColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = tertiaryColor;

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

  // Light tokens
  static const Color lightBackgroundColor = Color(0xFFF5F5FA);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightOnSurfaceColor = Color(0xFF1A1B2E);

  // Dark tokens
  static const Color darkBackgroundColor = Color(0xFF0F1020);
  static const Color darkSurfaceColor = Color(0xFF191A2C);
  static const Color darkOnSurfaceColor = Color(0xFFE2E8F0);

  // High-contrast Material 3 color schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE8DDFF),
    onPrimaryContainer: Color(0xFF2E1065),
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFD3E8),
    onSecondaryContainer: Color(0xFF4A0F2F),
    tertiary: tertiaryColor,
    onTertiary: Color(0xFF00270E),
    tertiaryContainer: Color(0xFFA8F2C3),
    onTertiaryContainer: Color(0xFF00200A),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: lightBackgroundColor,
    onBackground: lightOnSurfaceColor,
    surface: lightSurfaceColor,
    onSurface: lightOnSurfaceColor,
    surfaceVariant: Color(0xFFE3DFF5),
    onSurfaceVariant: Color(0xFF4A4767),
    outline: Color(0xFF7C7894),
    outlineVariant: Color(0xFFC9C4DE),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF2F3042),
    onInverseSurface: Color(0xFFF0EFF9),
    inversePrimary: Color(0xFFD0BCFF),
    surfaceTint: primaryColor,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF4C1D95),
    onPrimaryContainer: Color(0xFFF1E4FF),
    secondary: secondaryColor,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF6B103D),
    onSecondaryContainer: Color(0xFFFFE8F4),
    tertiary: tertiaryColor,
    onTertiary: Color(0xFF00220E),
    tertiaryContainer: Color(0xFF0D5A2C),
    onTertiaryContainer: Color(0xFFBFFFD7),
    error: errorColor,
    onError: Colors.white,
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFFFDAD4),
    background: darkBackgroundColor,
    onBackground: darkOnSurfaceColor,
    surface: darkSurfaceColor,
    onSurface: darkOnSurfaceColor,
    surfaceVariant: Color(0xFF2D2F45),
    onSurfaceVariant: Color(0xFFCAC4DD),
    outline: Color(0xFF908BA9),
    outlineVariant: Color(0xFF3F4156),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE4E1F7),
    onInverseSurface: Color(0xFF292A35),
    inversePrimary: Color(0xFFD0BCFF),
    surfaceTint: primaryColor,
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
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
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
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surfaceVariant.withValues(alpha: 0.6),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        hintStyle: TextStyle(
          fontSize: fontSizeBody,
          fontWeight: weightRegular,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
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
          textStyle: TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: weightSemiBold,
            color: colorScheme.onPrimary,
            fontFamily: fontFamily,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(48),
          textStyle: TextStyle(
            fontSize: fontSizeBodyLarge,
            fontWeight: weightSemiBold,
            color: colorScheme.onSurface,
            fontFamily: fontFamily,
            letterSpacing: 0.2,
          ),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: TextStyle(
            fontSize: fontSizeBody,
            fontWeight: weightSemiBold,
            color: colorScheme.primary,
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
            return colorScheme.primary.withValues(alpha: 0.7);
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
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 32,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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

  // Gradients and shadows still available for custom widgets
  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}