import '../models/pattern_difficulty.dart';

class PatternGenerator {
  static List<List<String>> generatePattern({
    required String patternType,
    required List<String> colors,
    required int rows,
    required int columns,
    PatternDifficulty difficulty = PatternDifficulty.basic,
  }) {
    // Ensure we have at least one color
    if (colors.isEmpty) {
      colors = ['black'];
    }

    // Ensure dimensions are within reasonable limits
    rows = rows.clamp(1, 32);
    columns = columns.clamp(1, 32);

    // Generate pattern based on type
    switch (patternType) {
      case 'checker_pattern':
        return _generateCheckerPattern(colors, rows, columns);
      case 'stripes_vertical_pattern':
        return _generateVerticalStripes(colors, rows, columns);
      case 'stripes_horizontal_pattern':
        return _generateHorizontalStripes(colors, rows, columns);
      case 'diamond_pattern':
        return _generateDiamondPattern(colors, rows, columns);
      case 'zigzag_pattern':
        return _generateZigzagPattern(colors, rows, columns);
      default:
      // Default to empty pattern
        return List.generate(
          rows,
              (_) => List.filled(columns, 'white'),
        );
    }
  }

  static List<List<String>> _generateCheckerPattern(
      List<String> colors,
      int rows,
      int columns,
      ) {
    // Ensure we have at least two colors for a checker pattern
    while (colors.length < 2) {
      colors.add(colors.length == 1 ? 'white' : 'black');
    }

    final pattern = List.generate(rows, (row) {
      return List.generate(columns, (col) {
        final colorIndex = (row + col) % 2;
        return colors[colorIndex % colors.length];
      });
    });

    return pattern;
  }

  static List<List<String>> _generateVerticalStripes(
      List<String> colors,
      int rows,
      int columns,
      ) {
    final pattern = List.generate(rows, (row) {
      return List.generate(columns, (col) {
        final colorIndex = col % colors.length;
        return colors[colorIndex];
      });
    });

    return pattern;
  }

  static List<List<String>> _generateHorizontalStripes(
      List<String> colors,
      int rows,
      int columns,
      ) {
    final pattern = List.generate(rows, (row) {
      final colorIndex = row % colors.length;
      return List.filled(columns, colors[colorIndex]);
    });

    return pattern;
  }

  static List<List<String>> _generateDiamondPattern(
      List<String> colors,
      int rows,
      int columns,
      ) {
    // Ensure dimensions are odd for better diamond centering
    if (rows % 2 == 0) rows++;
    if (columns % 2 == 0) columns++;

    final centerRow = rows ~/ 2;
    final centerCol = columns ~/ 2;
    final maxDist = (centerRow > centerCol) ? centerRow : centerCol;

    final pattern = List.generate(rows, (row) {
      return List.generate(columns, (col) {
        // Calculate distance from center (modified for diamond shape)
        final rowDist = (row - centerRow).abs();
        final colDist = (col - centerCol).abs();
        final dist = rowDist + colDist;

        // Calculate color index based on distance rings
        final colorIndex = dist % colors.length;
        return colors[colorIndex];
      });
    });

    return pattern;
  }

  static List<List<String>> _generateZigzagPattern(
      List<String> colors,
      int rows,
      int columns,
      ) {
    final pattern = List.generate(rows, (row) {
      return List.generate(columns, (col) {
        // Calculate zigzag position
        final zigzagPos = (row + (col ~/ 2)) % colors.length;
        return colors[zigzagPos];
      });
    });

    return pattern;
  }
}
