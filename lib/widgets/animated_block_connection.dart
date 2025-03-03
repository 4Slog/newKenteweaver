import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';

// Extension to add normalize method to Offset
extension OffsetExtension on Offset {
  Offset normalize() {
    final magnitude = distance;
    if (magnitude == 0) return Offset.zero;
    return Offset(dx / magnitude, dy / magnitude);
  }
}

class AnimatedBlockConnection extends StatefulWidget {
  final PatternDifficulty difficulty;
  final Offset startPoint;
  final Offset endPoint;
  final bool isValid;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double strokeWidth;
  final bool animate;
  final bool isConnecting;
  final String? connectionType;

  const AnimatedBlockConnection({
    super.key,
    required this.difficulty,
    required this.startPoint,
    required this.endPoint,
    this.isValid = true,
    this.isHighlighted = false,
    this.onTap,
    this.strokeWidth = 2.0,
    this.animate = true,
    this.isConnecting = false,
    this.connectionType,
  });

  @override
  State<AnimatedBlockConnection> createState() => _AnimatedBlockConnectionState();
}

class _AnimatedBlockConnectionState extends State<AnimatedBlockConnection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _glowAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 1.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate && (widget.isHighlighted || widget.isConnecting)) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedBlockConnection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation state when properties change
    if (widget.animate != oldWidget.animate ||
        widget.isHighlighted != oldWidget.isHighlighted ||
        widget.isConnecting != oldWidget.isConnecting) {
      if (widget.animate && (widget.isHighlighted || widget.isConnecting)) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(BuildContext context) {
    switch (widget.difficulty) {
      case PatternDifficulty.basic:
        return AppTheme.kenteGold;
      case PatternDifficulty.intermediate:
        return AppTheme.kenteRed;
      case PatternDifficulty.advanced:
        return AppTheme.kenteGreen;
      case PatternDifficulty.master:
        return AppTheme.kenteBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isValid
        ? _getDifficultyColor(context)
        : Colors.redAccent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: CustomPaint(
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          painter: widget.animate && (widget.isHighlighted || widget.isConnecting)
              ? AnimatedConnectionPainter(
            startPoint: widget.startPoint,
            endPoint: widget.endPoint,
            color: baseColor,
            animation: _animation,
            glowAnimation: _glowAnimation,
            isHighlighted: widget.isHighlighted,
            isHovering: _isHovering,
            strokeWidth: widget.strokeWidth,
            connectionType: widget.connectionType,
            isConnecting: widget.isConnecting,
          )
              : ConnectionPainter(
            startPoint: widget.startPoint,
            endPoint: widget.endPoint,
            color: baseColor,
            isHighlighted: widget.isHighlighted,
            isHovering: _isHovering,
            strokeWidth: widget.strokeWidth,
            connectionType: widget.connectionType,
          ),
        ),
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final bool isHighlighted;
  final bool isHovering;
  final double strokeWidth;
  final String? connectionType;

  ConnectionPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.isHighlighted,
    required this.isHovering,
    required this.strokeWidth,
    this.connectionType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveColor = isHovering
        ? color.withOpacity(0.8)
        : isHighlighted
        ? color
        : color.withOpacity(0.6);

    final effectiveStrokeWidth = isHovering || isHighlighted
        ? strokeWidth * 1.5
        : strokeWidth;

    // Define paint styles
    final linePaint = Paint()
      ..color = effectiveColor
      ..strokeWidth = effectiveStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.fill;

    // Apply glow effect for highlighted or hovered connections
    if (isHighlighted || isHovering) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..strokeWidth = effectiveStrokeWidth * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      // Draw glow
      canvas.drawPath(_createConnectionPath(), glowPaint);
    }

    // Draw connection path
    canvas.drawPath(_createConnectionPath(), linePaint);

    // Draw connection points
    _drawConnectionPoints(canvas, pointPaint);

    // Draw arrow if needed
    if (connectionType != null) {
      _drawDirectionalIndicator(canvas, linePaint);
    }
  }

  Path _createConnectionPath() {
    final path = Path();

    // Calculate control points for a smooth Bezier curve
    final midX = (startPoint.dx + endPoint.dx) / 2;
    final xDiff = (endPoint.dx - startPoint.dx).abs();

    // Use different control points based on distance
    final controlPointX1 = startPoint.dx + (xDiff * 0.25);
    final controlPointX2 = endPoint.dx - (xDiff * 0.25);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPointX1, startPoint.dy,
      controlPointX2, endPoint.dy,
      endPoint.dx, endPoint.dy,
    );

    return path;
  }

  void _drawConnectionPoints(Canvas canvas, Paint paint) {
    // Draw start and end points
    canvas.drawCircle(startPoint, strokeWidth + 1, paint);
    canvas.drawCircle(endPoint, strokeWidth + 1, paint);
  }

  void _drawDirectionalIndicator(Canvas canvas, Paint paint) {
    // Calculate direction of connection
    final direction = (endPoint - startPoint).normalize();

    // Calculate position slightly before endpoint
    final arrowPosition = endPoint - direction * (strokeWidth * 4);

    // Calculate perpendicular direction for arrow wings
    final perp = Offset(-direction.dy, direction.dx);

    // Arrow size based on stroke width
    final arrowSize = strokeWidth * 3;

    // Create arrow path
    final arrowPath = Path()
      ..moveTo(endPoint.dx, endPoint.dy)
      ..lineTo(
        arrowPosition.dx + perp.dx * arrowSize,
        arrowPosition.dy + perp.dy * arrowSize,
      )
      ..lineTo(
        arrowPosition.dx - perp.dx * arrowSize,
        arrowPosition.dy - perp.dy * arrowSize,
      )
      ..close();

    // Draw arrow
    canvas.drawPath(
      arrowPath,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is ConnectionPainter) {
      return oldDelegate.startPoint != startPoint ||
          oldDelegate.endPoint != endPoint ||
          oldDelegate.color != color ||
          oldDelegate.isHighlighted != isHighlighted ||
          oldDelegate.isHovering != isHovering ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.connectionType != connectionType;
    }
    return true;
  }
}

class AnimatedConnectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final Animation<double> animation;
  final Animation<double> glowAnimation;
  final bool isHighlighted;
  final bool isHovering;
  final double strokeWidth;
  final String? connectionType;
  final bool isConnecting;

  AnimatedConnectionPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.animation,
    required this.glowAnimation,
    required this.isHighlighted,
    required this.isHovering,
    required this.strokeWidth,
    this.connectionType,
    this.isConnecting = false,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final effectiveColor = isConnecting
        ? color.withOpacity(animation.value * 0.8)
        : isHovering
        ? color.withOpacity(0.8)
        : isHighlighted
        ? color.withOpacity(animation.value)
        : color.withOpacity(0.6);

    final effectiveStrokeWidth = isHovering || isHighlighted
        ? strokeWidth * 1.5
        : strokeWidth;

    // Connection line with animated opacity
    final linePaint = Paint()
      ..color = effectiveColor
      ..strokeWidth = effectiveStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Add animated glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(animation.value * 0.3)
      ..strokeWidth = effectiveStrokeWidth * glowAnimation.value
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isConnecting ? 8.0 : 4.0,
      );

    // Draw glow
    final path = _createConnectionPath();
    canvas.drawPath(path, glowPaint);

    // Draw main line
    canvas.drawPath(path, linePaint);

    // Add directional arrow or indicator
    if (connectionType != null) {
      _drawDirectionalIndicator(canvas, linePaint);
    }

    // Draw animated connection points
    _drawAnimatedConnectionPoints(canvas);

    // Draw animated particles for connecting state
    if (isConnecting) {
      _drawConnectionParticles(canvas);
    }
  }

  Path _createConnectionPath() {
    final path = Path();

    // Calculate control points for a smooth Bezier curve
    final midX = (startPoint.dx + endPoint.dx) / 2;
    final xDiff = (endPoint.dx - startPoint.dx).abs();

    // Use different control points based on distance
    final controlPointX1 = startPoint.dx + (xDiff * 0.25);
    final controlPointX2 = endPoint.dx - (xDiff * 0.25);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPointX1, startPoint.dy,
      controlPointX2, endPoint.dy,
      endPoint.dx, endPoint.dy,
    );

    return path;
  }

  void _drawDirectionalIndicator(Canvas canvas, Paint paint) {
    // Calculate direction of connection
    final direction = (endPoint - startPoint).normalize();

    // Calculate position slightly before endpoint
    final arrowPosition = endPoint - direction * (strokeWidth * 4);

    // Calculate perpendicular direction for arrow wings
    final perp = Offset(-direction.dy, direction.dx);

    // Arrow size based on stroke width and animation
    final arrowSize = strokeWidth * 3 * (isConnecting
        ? (0.7 + animation.value * 0.3)
        : 1.0);

    // Create arrow path
    final arrowPath = Path()
      ..moveTo(endPoint.dx, endPoint.dy)
      ..lineTo(
        arrowPosition.dx + perp.dx * arrowSize,
        arrowPosition.dy + perp.dy * arrowSize,
      )
      ..lineTo(
        arrowPosition.dx - perp.dx * arrowSize,
        arrowPosition.dy - perp.dy * arrowSize,
      )
      ..close();

    // Draw arrow
    canvas.drawPath(
      arrowPath,
      paint..style = PaintingStyle.fill,
    );
  }

  void _drawAnimatedConnectionPoints(Canvas canvas) {
    // Pulsating size based on animation value
    final startPointSize = (strokeWidth + 1) * (0.8 + animation.value * 0.4);
    final endPointSize = (strokeWidth + 1) * (0.8 + animation.value * 0.4);

    final startPointPaint = Paint()
      ..color = color.withOpacity(animation.value * 0.8)
      ..style = PaintingStyle.fill;

    final endPointPaint = Paint()
      ..color = color.withOpacity(animation.value * 0.8)
      ..style = PaintingStyle.fill;

    // Draw connection points with outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(animation.value * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw start point with outline
    canvas.drawCircle(startPoint, startPointSize, startPointPaint);
    canvas.drawCircle(startPoint, startPointSize + 1, outlinePaint);

    // Draw end point with outline
    canvas.drawCircle(endPoint, endPointSize, endPointPaint);
    canvas.drawCircle(endPoint, endPointSize + 1, outlinePaint);
  }

  void _drawConnectionParticles(Canvas canvas) {
    final direction = (endPoint - startPoint);
    final length = direction.distance;
    final particleCount = (length / 20).round();

    // Particle paint
    final particlePaint = Paint()
      ..color = color.withOpacity(animation.value * 0.7)
      ..style = PaintingStyle.fill;

    // Draw particles along the path
    for (int i = 1; i < particleCount; i++) {
      // Calculate position along the curve
      final t = i / particleCount;
      final animOffset = (animation.value * 2) % 1.0; // Animation offset
      final adjustedT = (t + animOffset) % 1.0;

      // Calculate position using a bezier curve
      final xDiff = (endPoint.dx - startPoint.dx).abs();
      final controlPointX1 = startPoint.dx + (xDiff * 0.25);
      final controlPointX2 = endPoint.dx - (xDiff * 0.25);

      // Cubic bezier formula
      final u = 1 - adjustedT;
      final tt = adjustedT * adjustedT;
      final uu = u * u;
      final uuu = uu * u;
      final ttt = tt * adjustedT;

      final x = uuu * startPoint.dx +
          3 * uu * adjustedT * controlPointX1 +
          3 * u * tt * controlPointX2 +
          ttt * endPoint.dx;

      final y = uuu * startPoint.dy +
          3 * uu * adjustedT * startPoint.dy +
          3 * u * tt * endPoint.dy +
          ttt * endPoint.dy;

      // Draw particle
      final particleSize = strokeWidth * (0.5 + animation.value * 0.5);
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is AnimatedConnectionPainter) {
      return oldDelegate.startPoint != startPoint ||
          oldDelegate.endPoint != endPoint ||
          oldDelegate.color != color ||
          oldDelegate.animation.value != animation.value ||
          oldDelegate.glowAnimation.value != glowAnimation.value ||
          oldDelegate.isHighlighted != isHighlighted ||
          oldDelegate.isHovering != isHovering ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.connectionType != connectionType ||
          oldDelegate.isConnecting != isConnecting;
    }
    return true;
  }
}