import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';

/// A layout container that provides consistent spacing and padding options
class LayoutContainer extends StatelessWidget {
  /// The container's child
  final Widget child;

  /// The container's padding
  final EdgeInsets? padding;

  /// The container's margin
  final EdgeInsets? margin;

  /// The container's width
  final double? width;

  /// The container's height
  final double? height;

  /// The container's constraints
  final BoxConstraints? constraints;

  /// The container's background color
  final Color? backgroundColor;

  /// The container's border radius
  final BorderRadius? borderRadius;

  /// The container's border
  final Border? border;

  /// The container's shadow
  final List<BoxShadow>? boxShadow;

  /// Whether to clip the container's content
  final bool clipContent;

  /// The container's alignment
  final Alignment? alignment;

  const LayoutContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.clipContent = false,
    this.alignment,
  }) : super(key: key);

  /// Creates a layout container with standard padding
  factory LayoutContainer.standard({
    required Widget child,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxConstraints? constraints,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    bool clipContent = false,
    Alignment? alignment,
  }) {
    return LayoutContainer(
      padding: const EdgeInsets.all(16),
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      clipContent: clipContent,
      alignment: alignment,
      child: child,
    );
  }

  /// Creates a layout container with compact padding
  factory LayoutContainer.compact({
    required Widget child,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxConstraints? constraints,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    bool clipContent = false,
    Alignment? alignment,
  }) {
    return LayoutContainer(
      padding: const EdgeInsets.all(8),
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      clipContent: clipContent,
      alignment: alignment,
      child: child,
    );
  }

  /// Creates a layout container with no padding
  factory LayoutContainer.none({
    required Widget child,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxConstraints? constraints,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    bool clipContent = false,
    Alignment? alignment,
  }) {
    return LayoutContainer(
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      clipContent: clipContent,
      alignment: alignment,
      child: child,
    );
  }

  /// Creates a layout container with custom padding
  factory LayoutContainer.custom({
    required Widget child,
    required EdgeInsets padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxConstraints? constraints,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    bool clipContent = false,
    Alignment? alignment,
  }) {
    return LayoutContainer(
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
      clipContent: clipContent,
      alignment: alignment,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = child;

    if (alignment != null) {
      content = Align(
        alignment: alignment!,
        child: content,
      );
    }

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    if (clipContent) {
      content = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      constraints: constraints,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? ColorPalette.neutralDark : Colors.transparent),
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: content,
    );
  }
}

/// Layout spacing constants
class LayoutSpacing {
  static const double none = 0;
  static const double xxsmall = 2;
  static const double xsmall = 4;
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double xlarge = 32;
  static const double xxlarge = 48;

  /// Get padding with equal spacing on all sides
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// Get padding with horizontal spacing
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  /// Get padding with vertical spacing
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  /// Get padding with custom spacing for each side
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );
}

/// Layout constraints constants
class LayoutConstraints {
  static const BoxConstraints contentWidth = BoxConstraints(maxWidth: 1200);
  static const BoxConstraints dialogWidth = BoxConstraints(maxWidth: 600);
  static const BoxConstraints cardWidth = BoxConstraints(maxWidth: 400);
  static const BoxConstraints buttonWidth = BoxConstraints(maxWidth: 200);
  static const BoxConstraints inputWidth = BoxConstraints(maxWidth: 300);
} 
