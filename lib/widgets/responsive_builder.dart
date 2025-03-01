import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100 && desktop != null) {
          return desktop!;
        }
        
        if (constraints.maxWidth >= 650 && tablet != null) {
          return tablet!;
        }
        
        return mobile;
      },
    );
  }
}

// Extension method to easily get screen size information
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveBuilder.isMobile(this);
  bool get isTablet => ResponsiveBuilder.isTablet(this);
  bool get isDesktop => ResponsiveBuilder.isDesktop(this);
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  // Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    if (isDesktop) {
      return const EdgeInsets.all(32.0);
    }
    if (isTablet) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }
  
  // Get responsive font size multiplier
  double get fontScale {
    if (isDesktop) {
      return 1.2;
    }
    if (isTablet) {
      return 1.1;
    }
    return 1.0;
  }
  
  // Get responsive spacing
  double get spacing {
    if (isDesktop) {
      return 24.0;
    }
    if (isTablet) {
      return 16.0;
    }
    return 12.0;
  }
  
  // Get responsive width for containers
  double responsiveWidth(double percentage) {
    return screenWidth * percentage;
  }
  
  // Get responsive height for containers
  double responsiveHeight(double percentage) {
    return screenHeight * percentage;
  }
}
