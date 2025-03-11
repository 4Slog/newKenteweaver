import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable animated button that follows the app's design system
class AnimatedButton extends StatefulWidget {
  /// The text to display on the button
  final String text;

  /// The icon to display before the text (optional)
  final IconData? icon;

  /// The callback when the button is pressed
  final VoidCallback onPressed;

  /// Whether the button is disabled
  final bool isDisabled;

  /// The button's variant (filled, outlined, text)
  final AnimatedButtonVariant variant;

  /// The button's size (small, medium, large)
  final AnimatedButtonSize size;

  /// Whether to show a loading indicator
  final bool isLoading;

  /// Custom background color (optional)
  final Color? backgroundColor;

  /// Custom text color (optional)
  final Color? textColor;

  const AnimatedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isDisabled = false,
    this.variant = AnimatedButtonVariant.filled,
    this.size = AnimatedButtonSize.medium,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.short,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on variant and state
    final colors = _getButtonColors(isDark);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          height: widget.size.height,
          padding: widget.size.padding,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? colors.backgroundColor.withOpacity(0.5)
                : colors.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.variant == AnimatedButtonVariant.outlined
                ? Border.all(
                    color: widget.isDisabled
                        ? colors.borderColor.withOpacity(0.5)
                        : colors.borderColor,
                  )
                : null,
            boxShadow: widget.variant == AnimatedButtonVariant.filled && !widget.isDisabled
                ? [
                    BoxShadow(
                      color: colors.backgroundColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.textColor),
                    ),
                  ),
                )
              else if (widget.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    widget.icon,
                    size: widget.size.iconSize,
                    color: widget.isDisabled
                        ? colors.textColor.withOpacity(0.5)
                        : colors.textColor,
                  ),
                ),
              Text(
                widget.text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: widget.isDisabled
                      ? colors.textColor.withOpacity(0.5)
                      : colors.textColor,
                  fontSize: widget.size.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonColors _getButtonColors(bool isDark) {
    final customBackground = widget.backgroundColor;
    final customText = widget.textColor;

    switch (widget.variant) {
      case AnimatedButtonVariant.filled:
        return ButtonColors(
          backgroundColor: customBackground ?? ColorPalette.kenteGold,
          textColor: customText ??
              (isDark ? ColorPalette.neutralDark : Colors.white),
          borderColor: Colors.transparent,
        );

      case AnimatedButtonVariant.outlined:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          textColor: customText ?? ColorPalette.kenteGold,
          borderColor: ColorPalette.kenteGold,
        );

      case AnimatedButtonVariant.text:
        return ButtonColors(
          backgroundColor: Colors.transparent,
          textColor: customText ?? ColorPalette.kenteGold,
          borderColor: Colors.transparent,
        );
    }
  }
}

/// Button variants
enum AnimatedButtonVariant {
  filled,
  outlined,
  text,
}

/// Button sizes
class AnimatedButtonSize {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;

  const AnimatedButtonSize._({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
  });

  static const small = AnimatedButtonSize._(
    height: 32,
    padding: EdgeInsets.symmetric(horizontal: 12),
    fontSize: 12,
    iconSize: 16,
  );

  static const medium = AnimatedButtonSize._(
    height: 40,
    padding: EdgeInsets.symmetric(horizontal: 16),
    fontSize: 14,
    iconSize: 18,
  );

  static const large = AnimatedButtonSize._(
    height: 48,
    padding: EdgeInsets.symmetric(horizontal: 24),
    fontSize: 16,
    iconSize: 20,
  );
}

/// Button colors
class ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
} 
