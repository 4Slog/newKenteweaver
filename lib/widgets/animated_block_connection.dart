import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';

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

  const AnimatedBlockConnection({
    super.key,
    required this.difficulty,
    required this.startPoint,
    required this.endPoint,
    this.isValid = true,
    this.isHighlighted = false,
    this.onTap,
    this.strokeWidth = 2.0,
  });

  @override
  State<AnimatedBlockConnection> createState() => _AnimatedBlockConnectionState();
}

class _AnimatedBlockConnectionState extends State<AnimatedBlockConnection> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    
    if (widget.isHighlighted) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(AnimatedBlockConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
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
    final theme = Theme.of(context);
    switch (widget.difficulty) {
      case PatternDifficulty.basic:
        return theme.colorScheme.primary;
      case PatternDifficulty.intermediate:
        return theme.colorScheme.secondary;
      case PatternDifficulty.advanced:
        return theme.colorScheme.tertiary;
      case PatternDifficulty.master:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: CustomPaint(
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height,
        ),
        painter: widget.isHighlighted
            ? AnimatedConnectionPainter(
                startPoint: widget.startPoint,
                endPoint: widget.endPoint,
                color: widget.isValid 
                    ? _getDifficultyColor(context) 
                    : Colors.redAccent,
                animation: _animation,
                isHighlighted: true,
                strokeWidth: widget.strokeWidth,
              )
            : ConnectionPainter(
                startPoint: widget.startPoint,
                endPoint: widget.endPoint,
                color: widget.isValid 
                    ? _getDifficultyColor(context) 
                    : Colors.redAccent,
                isHighlighted: false,
                strokeWidth: widget.strokeWidth,
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
  final double strokeWidth;

  ConnectionPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.isHighlighted,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (isHighlighted) {
      paint.strokeWidth = strokeWidth * 1.5;
    }
    
    // Draw connection path
    final path = _createConnectionPath();
    canvas.drawPath(path, paint);
    
    // Draw connection points
    _drawConnectionPoints(canvas);
  }
  
  Path _createConnectionPath() {
    final path = Path();
    
    // Calculate control points for the curve
    final controlPointX1 = startPoint.dx + (endPoint.dx - startPoint.dx) / 3;
    final controlPointX2 = startPoint.dx + 2 * (endPoint.dx - startPoint.dx) / 3;
    
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPointX1, startPoint.dy,
      controlPointX2, endPoint.dy,
      endPoint.dx, endPoint.dy,
    );
    
    return path;
  }
  
  void _drawConnectionPoints(Canvas canvas) {
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Draw start and end points
    canvas.drawCircle(startPoint, strokeWidth + 1, pointPaint);
    canvas.drawCircle(endPoint, strokeWidth + 1, pointPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is ConnectionPainter) {
      return oldDelegate.startPoint != startPoint ||
             oldDelegate.endPoint != endPoint ||
             oldDelegate.color != color ||
             oldDelegate.isHighlighted != isHighlighted ||
             oldDelegate.strokeWidth != strokeWidth;
    }
    return true;
  }
}

class AnimatedConnectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final Animation<double> animation;
  final bool isHighlighted;
  final double strokeWidth;

  AnimatedConnectionPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.animation,
    required this.isHighlighted,
    required this.strokeWidth,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Connection line
    final paint = Paint()
      ..color = color.withOpacity(animation.value)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    if (isHighlighted) {
      // Add glow effect for highlighted connections
      final glowPaint = Paint()
        ..color = color.withOpacity(animation.value * 0.5)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        
      final path = _createConnectionPath();
      canvas.drawPath(path, glowPaint);
    }
    
    final path = _createConnectionPath();
    canvas.drawPath(path, paint);
    
    // Add directional arrow
    _drawDirectionalArrow(canvas, paint);
    
    // Connection points with pulsating effect
    _drawAnimatedConnectionPoints(canvas);
  }
  
  Path _createConnectionPath() {
    final path = Path();
    
    // Calculate control points for the curve
    final controlPointX1 = startPoint.dx + (endPoint.dx - startPoint.dx) / 3;
    final controlPointX2 = startPoint.dx + 2 * (endPoint.dx - startPoint.dx) / 3;
    
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPointX1, startPoint.dy,
      controlPointX2, endPoint.dy,
      endPoint.dx, endPoint.dy,
    );
    
    return path;
  }
  
  void _drawDirectionalArrow(Canvas canvas, Paint paint) {
    // Calculate direction of the connection
    final direction = (endPoint - startPoint).normalize();
    
    // Calculate the arrow position (slightly before the endpoint)
    final arrowPosition = endPoint - direction * (strokeWidth * 3);
    
    // Calculate perpendicular direction for arrow wings
    final perp = Offset(-direction.dy, direction.dx);
    
    // Arrow size based on stroke width
    final arrowSize = strokeWidth * 3;
    
    // Draw arrow
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
      ..color = color.withOpacity(animation.value)
      ..style = PaintingStyle.fill;
      
    final endPointPaint = Paint()
      ..color = color.withOpacity(animation.value)
      ..style = PaintingStyle.fill;
    
    // Draw connection points
    canvas.drawCircle(startPoint, startPointSize, startPointPaint);
    canvas.drawCircle(endPoint, endPointSize, endPointPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is AnimatedConnectionPainter) {
      return oldDelegate.startPoint != startPoint ||
             oldDelegate.endPoint != endPoint ||
             oldDelegate.color != color ||
             oldDelegate.animation.value != animation.value ||
             oldDelegate.isHighlighted != isHighlighted ||
             oldDelegate.strokeWidth != strokeWidth;
    }
    return true;
  }
}
