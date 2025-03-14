import 'package:flutter/material.dart';

class PatternPreview extends StatelessWidget {
  final Map<String, dynamic> currentPattern;
  final Function(Map<String, dynamic>) onPatternUpdated;

  const PatternPreview({
    super.key,
    required this.currentPattern,
    required this.onPatternUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Preview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _PatternPainter(pattern: currentPattern),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 16),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPatternPreview() {
    if (_patternData == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Pattern: ${_patternInfo?['name'] ?? widget.patternId}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(widget.width - 24, widget.height - (widget.showMetadata ? 80 : 24)),
      painter: PatternPainter(
        grid: _patternData!['grid'] as List<List<int>>,
        colors: _getPatternColors(),
      ),
    );
  }

  List<Color> _getPatternColors() {
    // Default Kente-inspired colors
    return [
      Colors.black,
      Colors.yellow[700]!,
      Colors.red[900]!,
      Colors.green[800]!,
    ];
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _patternInfo?['name'] ?? 'Unknown Pattern',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          _patternInfo?['meaning'] ?? 'No description available',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.code,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _patternInfo?['codeRelation'] ?? 'Basic coding concepts',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PatternPainter extends CustomPainter {
  final List<List<int>> grid;
  final List<Color> colors;

  PatternPainter({
    required this.grid,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / grid[0].length;
    final cellHeight = size.height / grid.length;

    for (var y = 0; y < grid.length; y++) {
      for (var x = 0; x < grid[y].length; x++) {
        final value = grid[y][x];
        if (value > 0 && value < colors.length) {
          final paint = Paint()
            ..color = colors[value]
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(
              x * cellWidth,
              y * cellHeight,
              cellWidth,
              cellHeight,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) {
    return oldDelegate.grid != grid || oldDelegate.colors != colors;
  }
}
