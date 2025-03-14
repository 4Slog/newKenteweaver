import 'package:flutter/material.dart';

class KentePattern {
  final String name;
  final List<Color> colors;
  final List<List<int>> patternGrid; // 2D array representing pattern layout
  final int difficultyLevel;

  KentePattern({
    required this.name,
    required this.colors,
    required this.patternGrid,
    required this.difficultyLevel,
  });

  // Example method to generate a sample pattern
  static KentePattern examplePattern() {
    return KentePattern(
      name: "Golden Stripes",
      colors: [Colors.orange, Colors.black, Colors.yellow],
      patternGrid: [
        [1, 0, 1, 0, 1],
        [0, 1, 0, 1, 0],
        [1, 0, 1, 0, 1],
        [0, 1, 0, 1, 0],
      ],
      difficultyLevel: 2,
    );
  }
}
