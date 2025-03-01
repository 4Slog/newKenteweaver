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

  Widget _buildControls() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            onPatternUpdated({
              ...currentPattern,
              'scale': (currentPattern['scale'] ?? 1.0) * 1.2,
            });
          },
          icon: const Icon(Icons.zoom_in),
          label: const Text('Zoom In'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            onPatternUpdated({
              ...currentPattern,
              'scale': (currentPattern['scale'] ?? 1.0) / 1.2,
            });
          },
          icon: const Icon(Icons.zoom_out),
          label: const Text('Zoom Out'),
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Map<String, dynamic> pattern;

  _PatternPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final scale = pattern['scale'] ?? 1.0;
    final center = Offset(size.width / 2, size.height / 2);

    // Draw grid
    _drawGrid(canvas, size, paint);

    // Draw pattern elements
    if (pattern.containsKey('elements')) {
      for (final element in pattern['elements'] as List<dynamic>) {
        _drawElement(canvas, center, element as Map<String, dynamic>, scale, paint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    final gridSize = 20.0;
    paint.color = Colors.grey.withOpacity(0.2);

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawElement(Canvas canvas, Offset center, Map<String, dynamic> element,
      double scale, Paint paint) {
    final type = element['type'] as String;
    final position = element['position'] as Map<String, dynamic>;
    final x = (position['x'] as double) * scale + center.dx;
    final y = (position['y'] as double) * scale + center.dy;

    paint.color = Color(int.parse(element['color'] as String));

    switch (type) {
      case 'square':
        final size = (element['size'] as double) * scale;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: size,
            height: size,
          ),
          paint,
        );
        break;
      case 'circle':
        final radius = (element['radius'] as double) * scale;
        canvas.drawCircle(Offset(x, y), radius, paint);
        break;
      case 'triangle':
        final size = (element['size'] as double) * scale;
        final path = Path()
          ..moveTo(x, y - size / 2)
          ..lineTo(x - size / 2, y + size / 2)
          ..lineTo(x + size / 2, y + size / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern;
  }
}
