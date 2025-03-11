import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable accordion component that follows the app's design system
class CustomAccordion extends StatefulWidget {
  /// The accordion's title
  final String title;

  /// The accordion's content
  final Widget content;

  /// Whether the accordion is initially expanded
  final bool initiallyExpanded;

  /// Whether the accordion is disabled
  final bool isDisabled;

  /// Custom icon (optional)
  final IconData? icon;

  /// Custom width (optional)
  final double? width;

  /// Whether to show a divider
  final bool showDivider;

  /// The accordion's variant
  final AccordionVariant variant;

  /// Callback when expanded state changes
  final ValueChanged<bool>? onExpandedChanged;

  const CustomAccordion({
    Key? key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.showDivider = true,
    this.variant = AccordionVariant.filled,
    this.onExpandedChanged,
  }) : super(key: key);

  @override
  State<CustomAccordion> createState() => _CustomAccordionState();
}

class _CustomAccordionState extends State<CustomAccordion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _contentHeight;
  late Animation<double> _contentOpacity;
  bool _isExpanded = false;
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _contentHeight = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _contentOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (widget.isDisabled) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpandedChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: _getBackgroundColor(isDark),
              border: widget.variant == AccordionVariant.outlined
                  ? Border.all(
                      color: isDark
                          ? ColorPalette.neutralMedium.withOpacity(0.3)
                          : ColorPalette.neutralMedium.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: _getIconColor(isDark),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _getTitleColor(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _getIconColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _contentHeight,
          child: FadeTransition(
            opacity: _contentOpacity,
            child: Container(
              key: _contentKey,
              width: widget.width,
              decoration: BoxDecoration(
                color: _getContentBackgroundColor(isDark),
                border: widget.variant == AccordionVariant.outlined
                    ? Border(
                        left: BorderSide(
                          color: isDark
                              ? ColorPalette.neutralMedium.withOpacity(0.3)
                              : ColorPalette.neutralMedium.withOpacity(0.2),
                          width: 1,
                        ),
                        right: BorderSide(
                          color: isDark
                              ? ColorPalette.neutralMedium.withOpacity(0.3)
                              : ColorPalette.neutralMedium.withOpacity(0.2),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: isDark
                              ? ColorPalette.neutralMedium.withOpacity(0.3)
                              : ColorPalette.neutralMedium.withOpacity(0.2),
                          width: 1,
                        ),
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: widget.content,
            ),
          ),
        ),
        if (widget.showDivider && !_isExpanded)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? ColorPalette.neutralMedium.withOpacity(0.2)
                : ColorPalette.neutralMedium.withOpacity(0.1),
          ),
      ],
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark
          ? ColorPalette.neutralDark.withOpacity(0.5)
          : ColorPalette.neutralLight.withOpacity(0.5);
    }
    switch (widget.variant) {
      case AccordionVariant.filled:
        return isDark ? ColorPalette.neutralDark : Colors.white;
      case AccordionVariant.outlined:
        return Colors.transparent;
      case AccordionVariant.text:
        return Colors.transparent;
    }
  }

  Color _getContentBackgroundColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark
          ? ColorPalette.neutralDark.withOpacity(0.5)
          : ColorPalette.neutralLight.withOpacity(0.5);
    }
    switch (widget.variant) {
      case AccordionVariant.filled:
        return isDark
            ? ColorPalette.darker(ColorPalette.neutralDark, 0.1)
            : ColorPalette.neutralLight.withOpacity(0.05);
      case AccordionVariant.outlined:
        return Colors.transparent;
      case AccordionVariant.text:
        return Colors.transparent;
    }
  }

  Color _getTitleColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.5)
          : ColorPalette.neutralDark.withOpacity(0.5);
    }
    return isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark;
  }

  Color _getIconColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.5)
          : ColorPalette.neutralDark.withOpacity(0.5);
    }
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.7)
        : ColorPalette.neutralMedium;
  }
}

/// Accordion variants
enum AccordionVariant {
  filled,
  outlined,
  text,
}

/// A group of accordions that ensures only one is expanded at a time
class CustomAccordionGroup extends StatefulWidget {
  /// The list of accordions
  final List<CustomAccordion> accordions;

  /// The initially expanded accordion index
  final int? initiallyExpandedIndex;

  /// Custom width (optional)
  final double? width;

  /// Whether to show dividers
  final bool showDividers;

  /// The group's variant
  final AccordionVariant variant;

  const CustomAccordionGroup({
    Key? key,
    required this.accordions,
    this.initiallyExpandedIndex,
    this.width,
    this.showDividers = true,
    this.variant = AccordionVariant.filled,
  }) : super(key: key);

  @override
  State<CustomAccordionGroup> createState() => _CustomAccordionGroupState();
}

class _CustomAccordionGroupState extends State<CustomAccordionGroup> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initiallyExpandedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.accordions.length, (index) {
        final accordion = widget.accordions[index];
        return CustomAccordion(
          title: accordion.title,
          content: accordion.content,
          initiallyExpanded: index == _expandedIndex,
          isDisabled: accordion.isDisabled,
          icon: accordion.icon,
          width: widget.width,
          showDivider: widget.showDividers && index < widget.accordions.length - 1,
          variant: widget.variant,
          onExpandedChanged: (isExpanded) {
            setState(() {
              _expandedIndex = isExpanded ? index : null;
            });
          },
        );
      }),
    );
  }
} 
