import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';
import 'animated_button.dart';

/// A customizable bottom sheet that follows the app's design system
class CustomBottomSheet extends StatefulWidget {
  /// The bottom sheet's title
  final String? title;

  /// The bottom sheet's content
  final Widget content;

  /// The primary action button text
  final String? primaryActionText;

  /// The primary action callback
  final VoidCallback? onPrimaryAction;

  /// The secondary action button text
  final String? secondaryActionText;

  /// The secondary action callback
  final VoidCallback? onSecondaryAction;

  /// Whether to show a close button
  final bool showCloseButton;

  /// Whether to show a drag handle
  final bool showDragHandle;

  /// Custom height (optional)
  final double? height;

  /// Whether the bottom sheet is scrollable
  final bool isScrollable;

  /// Whether to show a loading state
  final bool isLoading;

  /// The bottom sheet's variant
  final BottomSheetVariant variant;

  const CustomBottomSheet({
    Key? key,
    this.title,
    required this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.showCloseButton = true,
    this.showDragHandle = true,
    this.height,
    this.isScrollable = false,
    this.isLoading = false,
    this.variant = BottomSheetVariant.standard,
  }) : super(key: key);

  /// Show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool showCloseButton = true,
    bool showDragHandle = true,
    double? height,
    bool isScrollable = false,
    bool isLoading = false,
    BottomSheetVariant variant = BottomSheetVariant.standard,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        title: title,
        content: content,
        primaryActionText: primaryActionText,
        onPrimaryAction: onPrimaryAction,
        secondaryActionText: secondaryActionText,
        onSecondaryAction: onSecondaryAction,
        showCloseButton: showCloseButton,
        showDragHandle: showDragHandle,
        height: height,
        isScrollable: isScrollable,
        isLoading: isLoading,
        variant: variant,
      ),
    );
  }

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.modalTransitionDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
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
    final mediaQuery = MediaQuery.of(context);
    final defaultHeight = mediaQuery.size.height * 0.7;

    Widget sheetContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? ColorPalette.neutralMedium.withOpacity(0.3)
                    : ColorPalette.neutralMedium.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        if (widget.title != null || widget.showCloseButton)
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: widget.showDragHandle ? 8 : 24,
              bottom: 16,
            ),
            child: Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                if (widget.showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: isDark
                        ? ColorPalette.neutralLight
                        : ColorPalette.neutralDark,
                  ),
              ],
            ),
          ),
        if (widget.isScrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: widget.content,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: widget.content,
          ),
        if (widget.primaryActionText != null || widget.secondaryActionText != null)
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: mediaQuery.padding.bottom + 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.secondaryActionText != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedButton(
                      text: widget.secondaryActionText!,
                      onPressed: widget.onSecondaryAction ??
                          () => Navigator.of(context).pop(),
                      variant: AnimatedButtonVariant.outlined,
                    ),
                  ),
                if (widget.primaryActionText != null)
                  AnimatedButton(
                    text: widget.primaryActionText!,
                    onPressed: widget.onPrimaryAction ?? () => Navigator.of(context).pop(),
                    variant: AnimatedButtonVariant.filled,
                  ),
              ],
            ),
          ),
      ],
    );

    if (widget.isLoading) {
      sheetContent = Stack(
        children: [
          sheetContent,
          Positioned.fill(
            child: Container(
              color: isDark
                  ? ColorPalette.neutralDark.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorPalette.kenteGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, mediaQuery.size.height * _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: widget.height ?? defaultHeight,
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDark),
                borderRadius: _getBorderRadius(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: sheetContent,
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(bool isDark) {
    switch (widget.variant) {
      case BottomSheetVariant.standard:
        return isDark ? ColorPalette.neutralDark : Colors.white;
      case BottomSheetVariant.blur:
        return isDark
            ? ColorPalette.neutralDark.withOpacity(0.9)
            : Colors.white.withOpacity(0.9);
      case BottomSheetVariant.transparent:
        return isDark
            ? ColorPalette.neutralDark.withOpacity(0.7)
            : Colors.white.withOpacity(0.7);
    }
  }

  BorderRadius _getBorderRadius() {
    switch (widget.variant) {
      case BottomSheetVariant.standard:
      case BottomSheetVariant.blur:
        return const BorderRadius.vertical(top: Radius.circular(16));
      case BottomSheetVariant.transparent:
        return BorderRadius.circular(16);
    }
  }
}

/// Bottom sheet variants
enum BottomSheetVariant {
  standard,
  blur,
  transparent,
} 