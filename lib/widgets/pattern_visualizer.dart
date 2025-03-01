import 'package:flutter/material.dart';
import 'dart:math' as math;

class PatternVisualizer extends StatelessWidget {
  final List<List<String>> pattern;
  final double cellSize;
  final bool showGrid;
  final bool isInteractive;
  final bool showKenteInfo;

  const PatternVisualizer({
    Key? key,
    required this.pattern,
    this.cellSize = 30.0,
    this.showGrid = true,
    this.isInteractive = false,
    this.showKenteInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = pattern.length;
        final cols = pattern[0].length;

        // Calculate dynamic cell size based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final dynamicCellSize = math.min(
          availableWidth / cols,
          availableHeight / rows,
        ).clamp(10.0, cellSize);

        return Column(
          children: [
            // Pattern Display
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20.0),
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      pattern.length,
                          (row) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          pattern[row].length,
                              (col) => _buildCell(
                            pattern[row][col],
                            dynamicCellSize,
                            row,
                            col,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Optional Pattern Information
            if (showKenteInfo) ...[
              const SizedBox(height: 8),
              _buildPatternInfo(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCell(String color, double size, int row, int col) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _parseColor(color),
        border: showGrid
            ? Border.all(color: Colors.grey[300]!, width: 0.5)
            : null,
      ),
      child: isInteractive
          ? Tooltip(
        message: 'Row: $row, Col: $col\nColor: $color',
        child: const SizedBox.expand(),
      )
          : null,
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1, 7), radix: 16) + 0xFF000000);
      }

      // Handle color names
      switch (colorStr.toLowerCase()) {
        case 'gold':
          return const Color(0xFFFFD700);
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'red':
          return Colors.red;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'maroon':
          return const Color(0xFF800000);
        default:
          return Colors.grey;
      }
    } catch (e) {
      debugPrint('Error parsing color: $colorStr');
      return Colors.grey;
    }
  }

  Widget _buildPatternInfo() {
    // Calculate pattern properties
    final rows = pattern.length;
    final cols = pattern[0].length;
    final uniqueColors = pattern
        .expand((row) => row)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Details:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Size: $rows × $cols'),
          Text('Colors Used: $uniqueColors'),
          if (uniqueColors < 2)
            Text(
              'Tip: Traditional Kente patterns typically use 2-3 colors',
              style: TextStyle(
                color: Colors.blue[700],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}