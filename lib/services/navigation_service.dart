import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState? get navigator => navigatorKey.currentState;

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToAndRemove(String routeName, {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  Future<dynamic> navigateToAndReplace(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  void goBack() {
    if (navigator!.canPop()) {
      navigator!.pop();
    }
  }

  void goBackToRoot() {
    navigator!.popUntil((route) => route.isFirst);
  }

  void goBackTo(String routeName) {
    navigator!.popUntil((route) => route.settings.name == routeName);
  }

  // Navigation history tracking
  final List<String> _navigationHistory = [];

  void recordNavigation(String routeName) {
    _navigationHistory.add(routeName);
    if (_navigationHistory.length > 10) {
      _navigationHistory.removeAt(0);
    }
  }

  List<String> getNavigationHistory() => List.unmodifiable(_navigationHistory);

  String? getPreviousRoute() {
    if (_navigationHistory.length < 2) return null;
    return _navigationHistory[_navigationHistory.length - 2];
  }

  // Common navigation methods
  void goToHome() => navigateTo(AppRouter.home);
  void goToSettings() => navigateTo(AppRouter.settings);
  void goToProfile() => navigateTo(AppRouter.profile);
  void goToTutorial() => navigateTo(AppRouter.tutorial);
  void goToLearningHub() => navigateTo(AppRouter.learningHub);
  void goToAchievements() => navigateTo(AppRouter.achievements);
  void goToWeaving() => navigateTo(AppRouter.weaving);
  void goToStory() => navigateTo(AppRouter.story);
  void goToChallenge() => navigateTo(AppRouter.challenge);

  // Route guards
  bool canAccessRoute(String routeName, {Object? arguments}) {
    switch (routeName) {
      case AppRouter.challenge:
        // Example: Check if user has completed tutorial
        return _navigationHistory.contains(AppRouter.tutorial);
      case AppRouter.weaving:
        // Example: Check if user has necessary permissions
        return true;
      default:
        return true;
    }
  }

  // Navigation with animation
  Future<dynamic> navigateWithSlideAnimation(
    String routeName, {
    Object? arguments,
    bool isRightToLeft = true,
  }) {
    return navigator!.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          final Widget page = AppRouter.buildRoute(routeName, arguments);
          return page;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
    );
  }

  // Navigation with fade animation
  Future<dynamic> navigateWithFadeAnimation(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          final Widget page = AppRouter.buildRoute(routeName, arguments);
          return page;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
    );
  }

  // Navigation with scale animation
  Future<dynamic> navigateWithScaleAnimation(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          final Widget page = AppRouter.buildRoute(routeName, arguments);
          return page;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          );
        },
        settings: RouteSettings(name: routeName, arguments: arguments),
      ),
    );
  }
} 