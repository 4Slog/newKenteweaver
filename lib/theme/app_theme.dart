import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_constants.dart';
import 'color_palette.dart';
import 'typography.dart';

/// Main theme configuration for the app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Generate the light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: ColorPalette.kenteGold,
        secondary: ColorPalette.kenteBlue,
        tertiary: ColorPalette.kenteGreen,
        error: ColorPalette.error,
        background: ColorPalette.neutralBackground,
        surface: Colors.white,
      ),
      textTheme: AppTypography.lightTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ColorPalette.neutralDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: ColorPalette.kenteGold,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.kenteGold,
          side: BorderSide(color: ColorPalette.kenteGold),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.kenteGold,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ColorPalette.kenteGold,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorPalette.neutralDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTypography.tooltip,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Generate the dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: ColorPalette.kenteGold,
        secondary: ColorPalette.kenteBlue,
        tertiary: ColorPalette.kenteGreen,
        error: ColorPalette.error,
        background: ColorPalette.neutralDark,
        surface: ColorPalette.darker(ColorPalette.neutralDark, 0.2),
      ),
      textTheme: AppTypography.darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.neutralDark,
        foregroundColor: ColorPalette.neutralLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: ColorPalette.darker(ColorPalette.neutralDark, 0.1),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: ColorPalette.neutralDark,
          backgroundColor: ColorPalette.kenteGold,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorPalette.kenteGold,
          side: BorderSide(color: ColorPalette.kenteGold),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.kenteGold,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ColorPalette.kenteGold,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: ColorPalette.darker(ColorPalette.neutralDark, 0.1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.darker(ColorPalette.neutralDark, 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorPalette.neutralLight.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTypography.tooltip.copyWith(
          color: ColorPalette.neutralDark,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Get a theme-aware color for difficulty levels
  static Color getDifficultyColor(BuildContext context, String difficulty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = ColorPalette.difficultyColors[difficulty] ?? ColorPalette.neutralMedium;
    
    return isDark ? ColorPalette.lighter(baseColor, 0.2) : baseColor;
  }

  /// Get a gradient for difficulty levels
  static LinearGradient getDifficultyGradient(BuildContext context, String difficulty) {
    final baseColor = getDifficultyColor(context, difficulty);
    final lighterColor = ColorPalette.lighter(baseColor, 0.3);

    return LinearGradient(
      colors: [baseColor, lighterColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}