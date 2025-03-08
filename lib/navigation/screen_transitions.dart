import 'package:flutter/material.dart';
import '../theme/animation_constants.dart';

/// Provides consistent screen transitions throughout the app
class ScreenTransitions {
  /// Fade transition
  static PageRouteBuilder<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AnimationConstants.pageTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Slide transition
  static PageRouteBuilder<T> slide<T>({
    required Widget page,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AnimationConstants.pageTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = direction.getOffset();
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static PageRouteBuilder<T> scale<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AnimationConstants.pageTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }

  /// Fade and scale transition
  static PageRouteBuilder<T> fadeScale<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AnimationConstants.pageTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  /// Fade and slide transition
  static PageRouteBuilder<T> fadeSlide<T>({
    required Widget page,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AnimationConstants.pageTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = direction.getOffset();
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Slide direction for transitions
enum SlideDirection {
  left,
  right,
  up,
  down;

  Offset getOffset() {
    switch (this) {
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, -1.0);
      case SlideDirection.down:
        return const Offset(0.0, 1.0);
    }
  }
} 