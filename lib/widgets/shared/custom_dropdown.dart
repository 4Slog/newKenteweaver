import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';
import 'custom_tooltip.dart';

/// A customizable dropdown that follows the app's design system
class CustomDropdown<T> extends StatefulWidget {
  /// The currently selected value
  final T? value;

  /// The list of items to display
  final List<DropdownItem<T>> items;

  /// Callback when value changes
  final ValueChanged<T?> onChanged;

  /// The dropdown's label
  final String label;

  /// The dropdown's hint text
  final String? hint;

  /// Whether the dropdown is disabled
  final bool isDisabled;

  /// Whether the dropdown has an error
  final bool hasError;

  /// The error message to display
  final String? errorText;

  /// Custom width (optional)
  final double? width;

  /// Custom icon (optional)
  final IconData? icon;

  /// Whether to show a clear button
  final bool showClear;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.hint,
    this.isDisabled = false,
    this.hasError = false,
    this.errorText,
    this.width,
    this.icon,
    this.showClear = true,
  }) : super(key: key);

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _menuAnimation;
  OverlayEntry? _overlayEntry;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _menuAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hideDropdown();
    _controller.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.isDisabled) return;

    setState(() {
      _isOpen = !_isOpen;
      _isFocused = _isOpen;
      if (_isOpen) {
        _showDropdown();
        _controller.forward();
      } else {
        _controller.reverse().then((_) => _hideDropdown());
      }
    });
  }

  void _showDropdown() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleDropdown,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
                _buildDropdownMenu(size),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
        _isFocused = false;
      });
    }
  }

  Widget _buildDropdownMenu(Size size) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      top: size.height + 4,
      child: FadeTransition(
        opacity: _menuAnimation,
        child: ScaleTransition(
          alignment: Alignment.topCenter,
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(_menuAnimation),
          child: Container(
            width: size.width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.neutralDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) {
                    final isSelected = item.value == widget.value;
                    return _DropdownMenuItem<T>(
                      item: item,
                      isSelected: isSelected,
                      onTap: () {
                        widget.onChanged(item.value);
                        _toggleDropdown();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedItem = widget.items
        .firstWhere((item) => item.value == widget.value, orElse: () => widget.items.first);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? (isDark
                    ? ColorPalette.neutralDark.withOpacity(0.5)
                    : ColorPalette.neutralLight.withOpacity(0.5))
                : (isDark ? ColorPalette.neutralDark : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(isDark),
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getLabelColor(isDark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.value != null
                                    ? selectedItem.label
                                    : (widget.hint ?? ''),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: widget.value != null
                                      ? (isDark
                                          ? ColorPalette.neutralLight
                                          : ColorPalette.neutralDark)
                                      : ColorPalette.neutralMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showClear && widget.value != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            iconSize: 20,
                            onPressed: widget.isDisabled
                                ? null
                                : () => widget.onChanged(null),
                            color: _getIconColor(isDark),
                          ),
                        RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: _getIconColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.hasError && widget.errorText != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
                  child: Text(
                    widget.errorText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ColorPalette.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    if (widget.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.5)
          : ColorPalette.neutralDark.withOpacity(0.5);
    }
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

class _DropdownMenuItem<T> extends StatelessWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownMenuItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? (isDark
                ? ColorPalette.kenteGold.withOpacity(0.1)
                : ColorPalette.kenteGold.withOpacity(0.05))
            : Colors.transparent,
        child: Row(
          children: [
            if (item.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? ColorPalette.kenteGold
                      : (isDark
                          ? ColorPalette.neutralLight
                          : ColorPalette.neutralDark),
                ),
              ),
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? ColorPalette.kenteGold
                      : (isDark
                          ? ColorPalette.neutralLight
                          : ColorPalette.neutralDark),
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: ColorPalette.kenteGold,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown item model
class DropdownItem<T> {
  /// The item's value
  final T value;

  /// The item's display label
  final String label;

  /// The item's icon (optional)
  final IconData? icon;

  /// The item's tooltip (optional)
  final String? tooltip;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });
} 