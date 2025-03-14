import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable progress indicator that follows the app's design system
class CustomProgressIndicator extends StatefulWidget {
  /// The progress value (0.0 to 1.0)
  final double? value;

  /// The progress variant
  final ProgressVariant variant;

  /// The progress size
  final ProgressSize size;

  /// Custom color (optional)
  final Color? color;

  /// Custom background color (optional)
  final Color? backgroundColor;

  /// Whether to show label
  final bool showLabel;

  /// Custom label (optional)
  final String? label;

  /// Whether to show percentage
  final bool showPercentage;

  /// Whether to animate value changes
  final bool animate;

  /// Custom width (for linear variant)
  final double? width;

  const CustomProgressIndicator({
    Key? key,
    this.value,
    this.variant = ProgressVariant.linear,
    this.size = ProgressSize.medium,
    this.color,
    this.backgroundColor,
    this.showLabel = false,
    this.label,
    this.showPercentage = false,
    this.animate = true,
    this.width,
  }) : super(key: key);

  @override
  State<CustomProgressIndicator> createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.animate && widget.value != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.value ?? 0.0,
        end: widget.value ?? 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      if (widget.animate) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    }
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

    final progressColor = widget.color ?? ColorPalette.kenteGold;
    final bgColor = widget.backgroundColor ??
        (isDark
            ? ColorPalette.neutralMedium.withOpacity(0.2)
            : ColorPalette.neutralLight.withOpacity(0.3));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel && widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark,
                  ),
                ),
                if (widget.showPercentage && widget.value != null)
                  Text(
                    ' (${(widget.value! * 100).round()}%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark,
                    ),
                  ),
              ],
            ),
          ),
        _buildProgressIndicator(progressColor, bgColor),
      ],
    );
  }

  Widget _buildProgressIndicator(Color progressColor, Color backgroundColor) {
    switch (widget.variant) {
      case ProgressVariant.linear:
        return SizedBox(
          width: widget.width,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: widget.value != null ? _progressAnimation.value : null,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: widget.size.dimension,
              );
            },
          ),
        );

      case ProgressVariant.circular:
        return SizedBox(
          width: widget.size.dimension,
          height: widget.size.dimension,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: widget.value != null ? _progressAnimation.value : null,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                strokeWidth: widget.size.strokeWidth,
              );
            },
          ),
        );

      case ProgressVariant.circularCentered:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widget.size.dimension,
              height: widget.size.dimension,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: widget.value != null ? _progressAnimation.value : null,
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    strokeWidth: widget.size.strokeWidth,
                  );
                },
              ),
            ),
            if (widget.value != null && widget.showPercentage)
              Text(
                '${(_progressAnimation.value * 100).round()}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: widget.size.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        );

      case ProgressVariant.dots:
        return SizedBox(
          width: widget.size.dimension,
          height: widget.size.dimension,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Stack(
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
                          color: progressColor.withOpacity(1.0 - (index * 0.1)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );
    }
  }
}

/// Progress variants
enum ProgressVariant {
  linear,
  circular,
  circularCentered,
  dots,
}

/// Progress sizes
class ProgressSize {
  final double dimension;
  final double strokeWidth;
  final double dotSize;
  final double fontSize;

  const ProgressSize._({
    required this.dimension,
    required this.strokeWidth,
    required this.dotSize,
    required this.fontSize,
  });

  static const small = ProgressSize._(
    dimension: 24,
    strokeWidth: 2,
    dotSize: 4,
    fontSize: 10,
  );

  static const medium = ProgressSize._(
    dimension: 40,
    strokeWidth: 3,
    dotSize: 6,
    fontSize: 12,
  );

  static const large = ProgressSize._(
    dimension: 56,
    strokeWidth: 4,
    dotSize: 8,
    fontSize: 14,
  );
} 
