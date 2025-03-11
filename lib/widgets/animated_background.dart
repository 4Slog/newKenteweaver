import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final String backgroundId;
  final Duration duration;
  final Curve curve;

  const AnimatedBackground({
    super.key,
    required this.backgroundId,
    this.duration = const Duration(seconds: 20),
    this.curve = Curves.linear,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.black : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withOpacity(0.8),
                baseColor.withOpacity(0.6),
                baseColor.withOpacity(0.4),
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/backgrounds/${widget.backgroundId}.png',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.1),
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    animation: _animation.value,
                    color: AppTheme.kenteGold.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PatternPainter extends CustomPainter {
  final double animation;
  final Color color;

  PatternPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 10;
    final offset = animation * spacing;

    for (var i = -10; i < size.width / spacing + 10; i++) {
      final x = i * spacing + offset;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
} 