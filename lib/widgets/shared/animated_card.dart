import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable animated card that follows the app's design system
class AnimatedCard extends StatefulWidget {
  /// The card's content
  final Widget child;

  /// Whether the card is selectable
  final bool isSelectable;

  /// Whether the card is selected
  final bool isSelected;

  /// The callback when the card is tapped
  final VoidCallback? onTap;

  /// The card's elevation
  final double elevation;

  /// Custom background color (optional)
  final Color? backgroundColor;

  /// Custom border color (optional)
  final Color? borderColor;

  /// Whether to show hover effect
  final bool enableHover;

  /// Whether to animate on appearance
  final bool animateOnAppear;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
    this.elevation = 2,
    this.backgroundColor,
    this.borderColor,
    this.enableHover = true,
    this.animateOnAppear = true,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.animateOnAppear ? 0.95 : 1.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.animateOnAppear) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverChanged(bool isHovered) {
    if (widget.enableHover && widget.onTap != null) {
      setState(() => _isHovered = isHovered);
      if (isHovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = widget.backgroundColor ??
        (isDark ? ColorPalette.neutralDark : Colors.white);
    
    final borderColor = widget.borderColor ??
        (widget.isSelected ? ColorPalette.kenteGold : Colors.transparent);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _handleHoverChanged(true),
            onExit: (_) => _handleHoverChanged(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: AnimationConstants.medium,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
} 