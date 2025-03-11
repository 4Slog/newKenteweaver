import 'package:flutter/material.dart';
import 'pattern_image_generator.dart';

/// This is a utility script to generate pattern images for the app.
/// Run this script using:
/// flutter run -t lib/utils/generate_patterns.dart
void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate all pattern images
  await PatternImageGenerator.generateAllPatternImages();
  
  // Exit the app after generating images
  print('Pattern generation complete. You can now exit the app.');
}
