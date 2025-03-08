import 'package:flutter/material.dart';

/// Color palette constants used throughout the app
class ColorPalette {
  // Primary Kente Colors
  static const Color kenteGold = Color(0xFFFFD700);
  static const Color kenteRed = Color(0xFFB22222);
  static const Color kenteGreen = Color(0xFF006400);
  static const Color kenteBlue = Color(0xFF000080);
  static const Color kentePurple = Color(0xFF800080);
  static const Color kenteOrange = Color(0xFFFF8C00);

  // Neutral Colors
  static const Color neutralDark = Color(0xFF1A1A1A);
  static const Color neutralMedium = Color(0xFF666666);
  static const Color neutralLight = Color(0xFFE5E5E5);
  static const Color neutralBackground = Color(0xFFF5F5F5);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Cultural Significance Colors
  static const Map<String, Color> culturalColors = {
    'wisdom': kenteGold,      // Gold represents wisdom and learning
    'earth': kenteRed,        // Red represents the earth and political power
    'growth': kenteGreen,     // Green represents growth and spiritual renewal
    'peace': kenteBlue,       // Blue represents peace and harmony
    'royalty': kentePurple,   // Purple represents royalty and leadership
    'energy': kenteOrange,    // Orange represents energy and vitality
  };

  // Difficulty Level Colors
  static const Map<String, Color> difficultyColors = {
    'basic': Color(0xFF4CAF50),      // Easier to distinguish green
    'intermediate': Color(0xFF2196F3), // Clear blue
    'advanced': Color(0xFFFF9800),    // Vibrant orange
    'master': Color(0xFF9C27B0),      // Rich purple
  };

  // Get a color with adjusted opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Get a lighter version of a color
  static Color lighter(Color color, [double amount = 0.1]) {
    return Color.lerp(color, Colors.white, amount)!;
  }

  // Get a darker version of a color
  static Color darker(Color color, [double amount = 0.1]) {
    return Color.lerp(color, Colors.black, amount)!;
  }

  // Generate a complementary color
  static Color complementary(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return HSLColor.fromAHSL(
      color.alpha / 255.0,
      (hslColor.hue + 180) % 360,
      hslColor.saturation,
      hslColor.lightness,
    ).toColor();
  }
} 