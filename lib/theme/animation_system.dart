import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// Mixin that provides standard animation controllers and animations
mixin StandardAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  // Standard animations
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _initializeAnimations();
  }

  void _initializeAnimationControllers() {
    _fadeController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
  }

  void _initializeAnimations() {
    fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AnimationConstants.defaultEasing,
    );

    scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: AnimationConstants.emphasisedEasing,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AnimationConstants.defaultEasing,
    ));
  }

  /// Start all animations
  Future<void> startAnimations() async {
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  /// Reverse all animations
  Future<void> reverseAnimations() async {
    _fadeController.reverse();
    _scaleController.reverse();
    _slideController.reverse();
  }

  /// Reset all animations
  void resetAnimations() {
    _fadeController.reset();
    _scaleController.reset();
    _slideController.reset();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

/// Class that provides pre-built animated transitions
class AnimatedTransitions {
  /// Fade transition
  static Widget fade({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale transition
  static Widget scale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Slide transition
  static Widget slide({
    required Widget child,
    required Animation<Offset> animation,
  }) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Combined fade and scale transition
  static Widget fadeScale({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }

  /// Combined fade and slide transition
  static Widget fadeSlide({
    required Widget child,
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
  }) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

/// Class that provides pre-built animated builders
class AnimatedBuilders {
  /// Fade in builder
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale in builder
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    double from = 0.8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in builder
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Offset from = const Offset(0, 0.2),
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: from, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
} 