import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable navigation drawer that follows the app's design system
class CustomNavigationDrawer extends StatefulWidget {
  /// The drawer header widget
  final Widget? header;

  /// The list of navigation items
  final List<NavigationItem> items;

  /// The currently selected item index
  final int selectedIndex;

  /// Callback when an item is selected
  final ValueChanged<int> onItemSelected;

  /// The drawer's width
  final double width;

  /// Whether to show dividers between items
  final bool showDividers;

  /// The drawer's variant
  final NavigationDrawerVariant variant;

  /// Footer widget (optional)
  final Widget? footer;

  const CustomNavigationDrawer({
    Key? key,
    this.header,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.width = 280,
    this.showDividers = true,
    this.variant = NavigationDrawerVariant.standard,
    this.footer,
  }) : super(key: key);

  @override
  State<CustomNavigationDrawer> createState() => _CustomNavigationDrawerState();
}

class _CustomNavigationDrawerState extends State<CustomNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _drawerAnimation = CurvedAnimation(
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

    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-widget.width * (1 - _drawerAnimation.value), 0),
          child: Container(
            width: widget.width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _getBackgroundColor(isDark),
              borderRadius: widget.variant == NavigationDrawerVariant.modal
                  ? const BorderRadius.horizontal(right: Radius.circular(12))
                  : null,
              boxShadow: widget.variant == NavigationDrawerVariant.modal
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                if (widget.header != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: widget.header!,
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    separatorBuilder: (context, index) {
                      return widget.showDividers
                          ? Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark
                                  ? ColorPalette.neutralMedium.withOpacity(0.2)
                                  : ColorPalette.neutralMedium.withOpacity(0.1),
                            )
                          : const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isSelected = index == widget.selectedIndex;
                      return _NavigationItem(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => widget.onItemSelected(index),
                        variant: widget.variant,
                      );
                    },
                  ),
                ),
                if (widget.footer != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: widget.footer!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(bool isDark) {
    switch (widget.variant) {
      case NavigationDrawerVariant.standard:
        return isDark ? ColorPalette.neutralDark : Colors.white;
      case NavigationDrawerVariant.modal:
        return isDark
            ? ColorPalette.darker(ColorPalette.neutralDark, 0.1)
            : Colors.white;
      case NavigationDrawerVariant.transparent:
        return Colors.transparent;
    }
  }
}

class _NavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final NavigationDrawerVariant variant;

  const _NavigationItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.variant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: _getItemBackgroundColor(isDark),
      child: InkWell(
        onTap: item.isDisabled ? null : onTap,
        splashColor: ColorPalette.kenteGold.withOpacity(0.1),
        highlightColor: ColorPalette.kenteGold.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (item.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: _getIconColor(isDark),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _getTextColor(isDark),
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                    if (item.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getSubtitleColor(isDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: item.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getItemBackgroundColor(bool isDark) {
    if (isSelected) {
      return isDark
          ? ColorPalette.kenteGold.withOpacity(0.1)
          : ColorPalette.kenteGold.withOpacity(0.05);
    }
    return Colors.transparent;
  }

  Color _getIconColor(bool isDark) {
    if (item.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.5)
          : ColorPalette.neutralDark.withOpacity(0.5);
    }
    if (isSelected) {
      return ColorPalette.kenteGold;
    }
    return isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark;
  }

  Color _getTextColor(bool isDark) {
    if (item.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.5)
          : ColorPalette.neutralDark.withOpacity(0.5);
    }
    if (isSelected) {
      return ColorPalette.kenteGold;
    }
    return isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark;
  }

  Color _getSubtitleColor(bool isDark) {
    if (item.isDisabled) {
      return isDark
          ? ColorPalette.neutralLight.withOpacity(0.3)
          : ColorPalette.neutralDark.withOpacity(0.3);
    }
    return isDark
        ? ColorPalette.neutralMedium.withOpacity(0.7)
        : ColorPalette.neutralMedium;
  }
}

/// Navigation drawer variants
enum NavigationDrawerVariant {
  standard,
  modal,
  transparent,
}

/// Navigation item model
class NavigationItem {
  /// The item's label
  final String label;

  /// The item's subtitle (optional)
  final String? subtitle;

  /// The item's icon (optional)
  final IconData? icon;

  /// The item's trailing widget (optional)
  final Widget? trailing;

  /// Whether the item is disabled
  final bool isDisabled;

  const NavigationItem({
    required this.label,
    this.subtitle,
    this.icon,
    this.trailing,
    this.isDisabled = false,
  });
} 
