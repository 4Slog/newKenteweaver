import 'package:flutter/material.dart';

class SettingsAnimationController {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  SettingsAnimationController(TickerProvider vsync) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  // Getters for animations
  Animation<double> get slideAnimation => _slideAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;

  // Animation control methods
  void forward() => _controller.forward();
  void reverse() => _controller.reverse();
  void reset() => _controller.reset();
  
  // Cleanup
  void dispose() {
    _controller.dispose();
  }
}

class AnimatedSettingsItem extends StatelessWidget {
  final Widget child;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final VoidCallback? onTap;

  const AnimatedSettingsItem({
    Key? key,
    required this.child,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.scaleAnimation,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([slideAnimation, fadeAnimation, scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class SettingsSectionTransition extends StatelessWidget {
  final Widget child;
  final bool visible;
  final Duration duration;
  final Curve curve;

  const SettingsSectionTransition({
    Key? key,
    required this.child,
    this.visible = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: visible ? child : const SizedBox.shrink(),
    );
  }
} 