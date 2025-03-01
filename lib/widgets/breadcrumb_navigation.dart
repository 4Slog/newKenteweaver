import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNavigation({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        children: items.map((item) => _buildBreadcrumbItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (item.iconAsset != null)
            Image.asset(
              item.iconAsset!,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  item.fallbackIcon ?? Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                );
              },
            )
          else
            Icon(
              item.fallbackIcon ?? Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              if (item.route != null) {
                Navigator.pushNamed(
                  context,
                  item.route!,
                  arguments: item.arguments,
                );
              }
            },
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                decoration: item.route != null ? null : TextDecoration.none,
              ),
            ),
          ),
          if (item != items.last) const Text(' > ', style: TextStyle(color: Colors.grey)),
        ],
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

  BreadcrumbItem({
    required this.label,
    this.route,
    this.fallbackIcon,
    this.iconAsset,
    this.arguments,
  });
}

// Extension methods moved to lib/extensions/breadcrumb_extensions.dart
