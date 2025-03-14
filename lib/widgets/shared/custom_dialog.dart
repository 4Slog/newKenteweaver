import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';
import 'animated_button.dart';
import 'layout_container.dart';

/// A customizable dialog that follows the app's design system
class CustomDialog extends StatelessWidget {
  /// The dialog's title
  final String title;

  /// The dialog's content
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

  /// Custom width (optional)
  final double? width;

  /// Custom padding (optional)
  final EdgeInsets? padding;

  /// Whether the dialog is scrollable
  final bool isScrollable;

  /// Whether to show a loading state
  final bool isLoading;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.showCloseButton = true,
    this.width,
    this.padding,
    this.isScrollable = false,
    this.isLoading = false,
  }) : super(key: key);

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool showCloseButton = true,
    double? width,
    EdgeInsets? padding,
    bool isScrollable = false,
    bool isLoading = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: AnimationConstants.modalTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomDialog(
          title: title,
          content: content,
          primaryActionText: primaryActionText,
          onPrimaryAction: onPrimaryAction,
          secondaryActionText: secondaryActionText,
          onSecondaryAction: onSecondaryAction,
          showCloseButton: showCloseButton,
          width: width,
          padding: padding,
          isScrollable: isScrollable,
          isLoading: isLoading,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, isDark),
        if (isScrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
              child: content,
            ),
          )
        else
          Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
            child: content,
          ),
        if (primaryActionText != null || secondaryActionText != null)
          _buildActions(context, isDark),
      ],
    );

    if (isLoading) {
      dialogContent = Stack(
        children: [
          dialogContent,
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: LayoutContainer(
        width: width ?? LayoutConstraints.dialogWidth.maxWidth,
        constraints: BoxConstraints(
          maxWidth: width ?? LayoutConstraints.dialogWidth.maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        backgroundColor:
            isDark ? ColorPalette.neutralDark : ColorPalette.neutralBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        child: dialogContent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ColorPalette.neutralMedium.withOpacity(0.2)
                : ColorPalette.neutralMedium.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (showCloseButton)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              color: isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark,
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? ColorPalette.neutralMedium.withOpacity(0.2)
                : ColorPalette.neutralMedium.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (secondaryActionText != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AnimatedButton(
                text: secondaryActionText!,
                onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
                variant: AnimatedButtonVariant.outlined,
              ),
            ),
          if (primaryActionText != null)
            AnimatedButton(
              text: primaryActionText!,
              onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(),
              variant: AnimatedButtonVariant.filled,
            ),
        ],
      ),
    );
  }
} 
