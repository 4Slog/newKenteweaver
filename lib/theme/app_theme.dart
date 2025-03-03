import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';

class AppTheme {
  // Brand Colors
  static const kenteGold = Color(0xFFFFD700);
  static const kenteRed = Color(0xFFB22222);
  static const kenteGreen = Color(0xFF006400);
  static const kenteBlue = Color(0xFF000080);

  // Additional Cultural Colors
  static const kentePurple = Color(0xFF800080);
  static const kenteOrange = Color(0xFFFF8C00);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Enhanced difficulty color function with better contrast handling
  static Color getDifficultyColor(PatternDifficulty difficulty, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (difficulty) {
      case PatternDifficulty.basic:
        return isDark ? Colors.green[300]! : Colors.green;
      case PatternDifficulty.intermediate:
        return isDark ? Colors.blue[300]! : Colors.blue;
      case PatternDifficulty.advanced:
        return isDark ? Colors.orange[300]! : Colors.orange;
      case PatternDifficulty.master:
        return isDark ? Colors.purple[300]! : Colors.purple;
      default:
        return isDark ? Colors.grey[300]! : Colors.grey;
    }
  }

  // Get difficulty gradient (for enhanced visual feedback)
  static LinearGradient getDifficultyGradient(PatternDifficulty difficulty, BuildContext context) {
    final baseColor = getDifficultyColor(difficulty, context);
    final lighterColor = Color.lerp(baseColor, Colors.white, 0.3)!;

    return LinearGradient(
      colors: [baseColor, lighterColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Enhanced text themes with consistent font styling
  static final TextTheme _lightTextTheme = TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 28),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24),
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 16),
    titleSmall: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 14),
    bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
    bodySmall: TextStyle(color: Colors.black, fontSize: 12),
    labelLarge: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
  );

  static final TextTheme _darkTextTheme = TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 28),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
    titleSmall: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
    bodySmall: TextStyle(color: Colors.white, fontSize: 12),
    labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
  );

  // Enhanced light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kenteGold,
      primary: kenteGold,
      secondary: kenteRed,
      tertiary: kenteGreen,
      error: kenteRed,
      background: Colors.white,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: _lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: kenteGold,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kenteGold,
        foregroundColor: Colors.black,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kenteGold,
        side: const BorderSide(color: kenteGold),
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
        foregroundColor: kenteGold,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kenteGold, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kenteGold,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kenteGold,
      thumbColor: kenteGold,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      space: 24,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kenteGold,
      unselectedItemColor: Colors.grey[600],
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: kenteGold,
      unselectedLabelColor: Colors.grey,
      indicatorColor: kenteGold,
    ),
  );

  // Enhanced dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kenteGold,
      primary: kenteGold,
      secondary: kenteRed,
      tertiary: kenteGreen,
      error: kenteRed,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      brightness: Brightness.dark,
    ),
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: kenteGold,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF2A2A2A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kenteGold,
        foregroundColor: Colors.black,
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kenteGold,
        side: const BorderSide(color: kenteGold),
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
        foregroundColor: kenteGold,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kenteGold, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[900],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kenteGold,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kenteGold,
      thumbColor: kenteGold,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return kenteGold.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
      space: 24,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: kenteGold,
      unselectedItemColor: Colors.grey[400],
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: kenteGold,
      unselectedLabelColor: Colors.grey,
      indicatorColor: kenteGold,
    ),
  );

  // Consistent Border Radiuses
  static final BorderRadius smallBorderRadius = BorderRadius.circular(4);
  static final BorderRadius defaultBorderRadius = BorderRadius.circular(8);
  static final BorderRadius largeBorderRadius = BorderRadius.circular(12);
  static final BorderRadius circleBorderRadius = BorderRadius.circular(100);

  // Consistent Paddings
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets largePadding = EdgeInsets.all(24);

  // Helper method to create a card box decoration
  static BoxDecoration cardDecoration(BuildContext context, {Color? color, bool withShadow = true}) {
    final theme = Theme.of(context);

    return BoxDecoration(
      color: color ?? theme.cardTheme.color ?? theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: withShadow ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }

  // Helper method to create a pattern tile decoration
  static BoxDecoration patternTileDecoration(BuildContext context, PatternDifficulty difficulty) {
    final baseColor = getDifficultyColor(difficulty, context);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [baseColor, Color.lerp(baseColor, Colors.white, 0.3)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: baseColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Helper method to get a color with adaptive brightness
  static Color adaptiveColor(BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light ? lightColor : darkColor;
  }

  // Helper method for text color with good contrast against any background
  static Color contrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}