import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable loading indicator that follows the app's design system
class LoadingIndicator extends StatefulWidget {
  /// The size of the loading indicator
  final LoadingIndicatorSize size;

  /// The variant of the loading indicator
  final LoadingIndicatorVariant variant;

  /// Custom color (optional)
  final Color? color;

  /// Whether to show a label
  final bool showLabel;

  /// Custom label text (optional)
  final String? labelText;

  const LoadingIndicator({
    Key? key,
    this.size = LoadingIndicatorSize.medium,
    this.variant = LoadingIndicatorVariant.circular,
    this.color,
    this.showLabel = false,
    this.labelText,
  }) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.color ?? ColorPalette.kenteGold;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            switch (widget.variant) {
              case LoadingIndicatorVariant.circular:
                return SizedBox(
                  width: widget.size.dimension,
                  height: widget.size.dimension,
                  child: CircularProgressIndicator(
                    strokeWidth: widget.size.strokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                );

              case LoadingIndicatorVariant.rotatingDots:
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: SizedBox(
                    width: widget.size.dimension,
                    height: widget.size.dimension,
                    child: Stack(
                      children: List.generate(8, (index) {
                        final angle = index * 3.14159 / 4;
                        final offset = widget.size.dimension / 3;
                        return Positioned(
                          left: widget.size.dimension / 2 +
                              offset * cos(angle) -
                              widget.size.dotSize / 2,
                          top: widget.size.dimension / 2 +
                              offset * sin(angle) -
                              widget.size.dotSize / 2,
                          child: Transform.scale(
                            scale: 1.0 - (index * 0.1),
                            child: Container(
                              width: widget.size.dotSize,
                              height: widget.size.dotSize,
                              decoration: BoxDecoration(
                                color: color.withOpacity(1.0 - (index * 0.1)),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );

              case LoadingIndicatorVariant.pulsingDot:
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size.dimension,
                    height: widget.size.dimension,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: widget.size.dimension * 0.6,
                        height: widget.size.dimension * 0.6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
            }
          },
        ),
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.labelText ?? 'Loading...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark,
              ),
            ),
          ),
      ],
    );
  }
}

/// Loading indicator variants
enum LoadingIndicatorVariant {
  circular,
  rotatingDots,
  pulsingDot,
}

/// Loading indicator sizes
class LoadingIndicatorSize {
  final double dimension;
  final double strokeWidth;
  final double dotSize;

  const LoadingIndicatorSize._({
    required this.dimension,
    required this.strokeWidth,
    required this.dotSize,
  });

  static const small = LoadingIndicatorSize._(
    dimension: 24,
    strokeWidth: 2,
    dotSize: 4,
  );

  static const medium = LoadingIndicatorSize._(
    dimension: 40,
    strokeWidth: 3,
    dotSize: 6,
  );

  static const large = LoadingIndicatorSize._(
    dimension: 56,
    strokeWidth: 4,
    dotSize: 8,
  );
} 