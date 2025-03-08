import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable tooltip that follows the app's design system
class CustomTooltip extends StatefulWidget {
  /// The widget that triggers the tooltip
  final Widget child;

  /// The tooltip message
  final String message;

  /// The tooltip position
  final TooltipPosition position;

  /// Whether to show an arrow indicator
  final bool showArrow;

  /// Custom background color (optional)
  final Color? backgroundColor;

  /// Custom text color (optional)
  final Color? textColor;

  /// Custom padding (optional)
  final EdgeInsets? padding;

  /// Whether to show immediately
  final bool showImmediately;

  const CustomTooltip({
    Key? key,
    required this.child,
    required this.message,
    this.position = TooltipPosition.top,
    this.showArrow = true,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.showImmediately = false,
  }) : super(key: key);

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _tooltipKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.tooltipDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.showImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTooltip();
      });
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (_isVisible) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _TooltipOverlay(
          key: _tooltipKey,
          message: widget.message,
          position: widget.position,
          showArrow: widget.showArrow,
          targetPosition: position,
          targetSize: size,
          backgroundColor: widget.backgroundColor,
          textColor: widget.textColor,
          padding: widget.padding,
          fadeAnimation: _fadeAnimation,
          scaleAnimation: _scaleAnimation,
        );
      },
    );

    _isVisible = true;
    overlay.insert(_overlayEntry!);
    _controller.forward();
  }

  void _hideTooltip() {
    if (!_isVisible) return;

    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  final String message;
  final TooltipPosition position;
  final bool showArrow;
  final Offset targetPosition;
  final Size targetSize;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const _TooltipOverlay({
    Key? key,
    required this.message,
    required this.position,
    required this.showArrow,
    required this.targetPosition,
    required this.targetSize,
    this.backgroundColor,
    this.textColor,
    this.padding,
    required this.fadeAnimation,
    required this.scaleAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark
            ? ColorPalette.neutralLight.withOpacity(0.9)
            : ColorPalette.neutralDark.withOpacity(0.9));
    final txtColor = textColor ??
        (isDark ? ColorPalette.neutralDark : ColorPalette.neutralLight);

    const arrowSize = 8.0;
    const borderRadius = 4.0;
    final tooltipPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Positioned(
      left: _getTooltipPosition(position).dx,
      top: _getTooltipPosition(position).dy,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (position == TooltipPosition.bottom && showArrow)
                _buildArrow(bgColor, position),
              Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: tooltipPadding,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: txtColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (position == TooltipPosition.top && showArrow)
                _buildArrow(bgColor, position),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow(Color color, TooltipPosition position) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _ArrowPainter(
        color: color,
        position: position,
      ),
    );
  }

  Offset _getTooltipPosition(TooltipPosition position) {
    switch (position) {
      case TooltipPosition.top:
        return Offset(
          targetPosition.dx + (targetSize.width - 200) / 2,
          targetPosition.dy - 40,
        );
      case TooltipPosition.bottom:
        return Offset(
          targetPosition.dx + (targetSize.width - 200) / 2,
          targetPosition.dy + targetSize.height + 8,
        );
      case TooltipPosition.left:
        return Offset(
          targetPosition.dx - 208,
          targetPosition.dy + (targetSize.height - 32) / 2,
        );
      case TooltipPosition.right:
        return Offset(
          targetPosition.dx + targetSize.width + 8,
          targetPosition.dy + (targetSize.height - 32) / 2,
        );
    }
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final TooltipPosition position;

  _ArrowPainter({
    required this.color,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (position == TooltipPosition.top) {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(size.width / 2 - 8, 0);
      path.lineTo(size.width / 2 + 8, 0);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width / 2 - 8, size.height);
      path.lineTo(size.width / 2 + 8, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tooltip position
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
} 