import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable animated input field that follows the app's design system
class AnimatedInput extends StatefulWidget {
  /// The input's label
  final String label;

  /// The input's hint text
  final String? hint;

  /// The input's initial value
  final String? initialValue;

  /// The callback when the input changes
  final ValueChanged<String>? onChanged;

  /// The callback when the input is submitted
  final ValueChanged<String>? onSubmitted;

  /// The input's keyboard type
  final TextInputType keyboardType;

  /// Whether the input is obscured (for passwords)
  final bool isObscured;

  /// Whether the input is disabled
  final bool isDisabled;

  /// Whether the input has an error
  final bool hasError;

  /// The error message to display
  final String? errorText;

  /// The input's prefix icon
  final IconData? prefixIcon;

  /// The input's suffix icon
  final IconData? suffixIcon;

  /// The callback when the suffix icon is tapped
  final VoidCallback? onSuffixTap;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Maximum lines
  final int? maxLines;

  /// Maximum length
  final int? maxLength;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  const AnimatedInput({
    Key? key,
    required this.label,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.isObscured = false,
    this.isDisabled = false,
    this.hasError = false,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  State<AnimatedInput> createState() => _AnimatedInputState();
}

class _AnimatedInputState extends State<AnimatedInput>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _labelAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _labelAnimation = Tween<double>(
      begin: 1.0,
      end: 0.75,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else if (_controller.text.isEmpty) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasValue = _controller.text.isNotEmpty;
    final showLabel = _isFocused || hasValue;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? ColorPalette.darker(ColorPalette.neutralDark, 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getBorderColor(isDark),
                        width: _isFocused ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (widget.prefixIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              widget.prefixIcon,
                              color: _getIconColor(isDark),
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: !widget.isDisabled,
                            obscureText: widget.isObscured,
                            keyboardType: widget.keyboardType,
                            textCapitalization: widget.textCapitalization,
                            maxLines: widget.maxLines,
                            maxLength: widget.maxLength,
                            inputFormatters: widget.inputFormatters,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: widget.isDisabled
                                  ? _getTextColor(isDark).withOpacity(0.5)
                                  : _getTextColor(isDark),
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: showLabel ? 20 : 16,
                              ),
                              border: InputBorder.none,
                              hintText: showLabel ? widget.hint : widget.label,
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: _getHintColor(isDark),
                              ),
                            ),
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                          ),
                        ),
                        if (widget.suffixIcon != null)
                          GestureDetector(
                            onTap: widget.onSuffixTap,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                widget.suffixIcon,
                                color: _getIconColor(isDark),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (showLabel)
                    Positioned(
                      left: 16,
                      top: 4,
                      child: Transform.scale(
                        scale: _labelAnimation.value,
                        child: Text(
                          widget.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getLabelColor(isDark),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.hasError && widget.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 16),
                  child: Text(
                    widget.errorText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ColorPalette.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBorderColor(bool isDark) {
    if (widget.hasError) {
      return ColorPalette.error;
    }
    if (_isFocused) {
      return ColorPalette.kenteGold;
    }
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.3)
        : ColorPalette.neutralMedium.withOpacity(0.2);
  }

  Color _getTextColor(bool isDark) {
    return isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark;
  }

  Color _getHintColor(bool isDark) {
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.7)
        : ColorPalette.neutralMedium;
  }

  Color _getLabelColor(bool isDark) {
    if (widget.hasError) {
      return ColorPalette.error;
    }
    if (_isFocused) {
      return ColorPalette.kenteGold;
    }
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.7)
        : ColorPalette.neutralMedium;
  }

  Color _getIconColor(bool isDark) {
    if (widget.hasError) {
      return ColorPalette.error;
    }
    if (_isFocused) {
      return ColorPalette.kenteGold;
    }
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.7)
        : ColorPalette.neutralMedium;
  }
} 