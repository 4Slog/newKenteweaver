import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BreadcrumbNavigation extends StatefulWidget {
  final List<BreadcrumbItem> items;
  final bool enableAnimation;
  final double spacing;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const BreadcrumbNavigation({
    Key? key,
    required this.items,
    this.enableAnimation = true,
    this.spacing = 4.0,
    this.iconSize = 16.0,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  State<BreadcrumbNavigation> createState() => _BreadcrumbNavigationState();
}

class _BreadcrumbNavigationState extends State<BreadcrumbNavigation> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildBreadcrumbItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context) {
    final List<Widget> breadcrumbWidgets = [];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isLast = i == widget.items.length - 1;

      breadcrumbWidgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing),
          child: _buildBreadcrumbItem(context, item, i, isLast, isDarkMode),
        ),
      );

      // Add separator between items
      if (!isLast) {
        breadcrumbWidgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing),
            child: Icon(
              Icons.chevron_right,
              size: widget.iconSize,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        );
      }
    }

    return breadcrumbWidgets;
  }

  Widget _buildBreadcrumbItem(
      BuildContext context,
      BreadcrumbItem item,
      int index,
      bool isLast,
      bool isDarkMode,
      ) {
    final isClickable = item.route != null;
    final isHovered = _hoveredIndex == index;

    // Style based on item position and state
    final textColor = isLast
        ? AppTheme.kenteGold
        : isHovered
        ? isDarkMode ? Colors.white : AppTheme.kenteGold
        : isDarkMode ? Colors.white70 : Colors.black87;

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
      color: textColor,
      decoration: isClickable && !isLast ? TextDecoration.underline : null,
      decorationColor: AppTheme.kenteGold.withOpacity(0.5),
      decorationThickness: 1,
    );

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: widget.enableAnimation
            ? const Duration(milliseconds: 200)
            : Duration.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isHovered && isClickable
              ? isDarkMode
              ? Colors.grey[700]
              : Colors.grey[200]
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isLast
              ? Border.all(
            color: AppTheme.kenteGold.withOpacity(isHovered ? 0.8 : 0.3),
            width: 1,
          )
              : null,
        ),
        child: InkWell(
          onTap: isClickable
              ? () {
            Navigator.pushNamed(
              context,
              item.route!,
              arguments: item.arguments,
            );
          }
              : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.iconAsset != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      item.iconAsset!,
                      width: widget.iconSize,
                      height: widget.iconSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          item.fallbackIcon ?? Icons.arrow_right,
                          size: widget.iconSize,
                          color: textColor,
                        );
                      },
                    ),
                  ),
                )
              else if (item.fallbackIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    item.fallbackIcon!,
                    size: widget.iconSize,
                    color: textColor,
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: widget.enableAnimation
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                style: textStyle,
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? fallbackIcon;
  final String? iconAsset;
  final Map<String, dynamic>? arguments;
  final bool isActive;

  BreadcrumbItem({
    required this.label,
    this.route,
    this.fallbackIcon,
    this.iconAsset,
    this.arguments,
    this.isActive = false,
  });
}

// Helper class to create common breadcrumb patterns
class BreadcrumbBuilder {
  static List<BreadcrumbItem> buildFromRoutes(
      List<String> routes,
      List<String> labels, {
        List<IconData>? icons,
        Map<String, dynamic>? arguments,
      }) {
    assert(routes.length == labels.length, 'Routes and labels must have the same length');

    final items = <BreadcrumbItem>[];

    for (int i = 0; i < routes.length; i++) {
      final isLast = i == routes.length - 1;

      items.add(BreadcrumbItem(
        label: labels[i],
        route: isLast ? null : routes[i],
        fallbackIcon: icons != null && i < icons.length ? icons[i] : null,
        arguments: arguments,
        isActive: isLast,
      ));
    }

    return items;
  }
}
