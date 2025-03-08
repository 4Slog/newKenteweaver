import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Typography styles used throughout the app
class AppTypography {
  // Base font families
  static const String primaryFont = 'Roboto';
  static const String displayFont = 'Poppins';
  static const String codeFont = 'FiraCode';

  // Text Styles - Light Theme
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: ColorPalette.neutralDark,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: ColorPalette.neutralDark,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontFamily: displayFont,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: ColorPalette.neutralDark,
    ),
    headlineLarge: TextStyle(
      fontFamily: primaryFont,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    headlineMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    headlineSmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    titleLarge: TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    titleMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    titleSmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: ColorPalette.neutralDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      color: ColorPalette.neutralDark,
    ),
    bodyMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 14,
      color: ColorPalette.neutralDark,
    ),
    bodySmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 12,
      color: ColorPalette.neutralDark,
    ),
  );

  // Text Styles - Dark Theme
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: lightTextTheme.displayLarge!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    displayMedium: lightTextTheme.displayMedium!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    displaySmall: lightTextTheme.displaySmall!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    headlineLarge: lightTextTheme.headlineLarge!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    headlineMedium: lightTextTheme.headlineMedium!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    headlineSmall: lightTextTheme.headlineSmall!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    titleLarge: lightTextTheme.titleLarge!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    titleMedium: lightTextTheme.titleMedium!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    titleSmall: lightTextTheme.titleSmall!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    bodyLarge: lightTextTheme.bodyLarge!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    bodyMedium: lightTextTheme.bodyMedium!.copyWith(
      color: ColorPalette.neutralLight,
    ),
    bodySmall: lightTextTheme.bodySmall!.copyWith(
      color: ColorPalette.neutralLight,
    ),
  );

  // Special Text Styles
  static TextStyle get codeStyle => TextStyle(
    fontFamily: codeFont,
    fontSize: 14,
    color: ColorPalette.neutralDark,
    height: 1.5,
  );

  static TextStyle get buttonText => TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    color: ColorPalette.neutralMedium,
    letterSpacing: 0.2,
  );

  static TextStyle get tooltip => TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    color: ColorPalette.neutralLight,
    fontWeight: FontWeight.w500,
  );
} 