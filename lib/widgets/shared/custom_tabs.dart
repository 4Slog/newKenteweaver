import 'package:flutter/material.dart';
import '../../theme/animation_constants.dart';
import '../../theme/color_palette.dart';

/// A customizable tabs component that follows the app's design system
class CustomTabs extends StatefulWidget {
  /// The list of tabs
  final List<TabItem> tabs;

  /// The currently selected tab index
  final int selectedIndex;

  /// Callback when tab changes
  final ValueChanged<int> onTabChanged;

  /// The tab bar's variant
  final TabVariant variant;

  /// Whether to show badges
  final bool showBadges;

  /// Whether the tabs are scrollable
  final bool isScrollable;

  /// Custom width (optional)
  final double? width;

  /// Whether to show divider
  final bool showDivider;

  const CustomTabs({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.variant = TabVariant.filled,
    this.showBadges = true,
    this.isScrollable = false,
    this.width,
    this.showDivider = true,
  }) : super(key: key);

  @override
  State<CustomTabs> createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );

    _controller.addListener(() {
      if (!_controller.indexIsChanging) {
        widget.onTabChanged(_controller.index);
      }
    });
  }

  @override
  void didUpdateWidget(CustomTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _controller.index) {
      _controller.animateTo(widget.selectedIndex);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.variant == TabVariant.filled
                ? (isDark ? ColorPalette.neutralDark : Colors.white)
                : Colors.transparent,
            border: widget.variant == TabVariant.outlined
                ? Border.all(
                    color: isDark
                        ? ColorPalette.neutralMedium.withOpacity(0.3)
                        : ColorPalette.neutralMedium.withOpacity(0.2),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _controller,
            isScrollable: widget.isScrollable,
            labelColor: ColorPalette.kenteGold,
            unselectedLabelColor:
                isDark ? ColorPalette.neutralLight : ColorPalette.neutralDark,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.labelLarge,
            indicator: _buildIndicator(isDark),
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                return states.contains(MaterialState.focused)
                    ? null
                    : Colors.transparent;
              },
            ),
            tabs: widget.tabs.map((tab) {
              return _buildTab(tab, isDark);
            }).toList(),
          ),
        ),
        if (widget.showDivider)
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

  Widget _buildTab(TabItem tab, bool isDark) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                tab.icon,
                size: 20,
              ),
            ),
          Text(tab.label),
          if (widget.showBadges && tab.badgeCount != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ColorPalette.kenteGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tab.badgeCount.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColorPalette.kenteGold,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Decoration _buildIndicator(bool isDark) {
    switch (widget.variant) {
      case TabVariant.filled:
        return UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: ColorPalette.kenteGold,
          ),
        );
      case TabVariant.outlined:
        return BoxDecoration(
          color: ColorPalette.kenteGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        );
      case TabVariant.text:
        return UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2,
            color: ColorPalette.kenteGold,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        );
    }
  }
}

/// Tab variants
enum TabVariant {
  filled,
  outlined,
  text,
}

/// Tab item model
class TabItem {
  /// The tab's label
  final String label;

  /// The tab's icon (optional)
  final IconData? icon;

  /// The tab's badge count (optional)
  final int? badgeCount;

  const TabItem({
    required this.label,
    this.icon,
    this.badgeCount,
  });
} 