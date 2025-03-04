import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A widget that displays an animated hint for tutorials
class AnimatedTutorialHint extends StatefulWidget {
  /// The hint text to display
  final String text;
  
  /// Callback when the hint is closed
  final VoidCallback? onClose;
  
  /// Whether to show an icon
  final bool showIcon;
  
  /// The icon to display
  final IconData icon;
  
  /// The color of the hint background
  final Color backgroundColor;
  
  /// The color of the hint text
  final Color textColor;
  
  const AnimatedTutorialHint({
    Key? key,
    required this.text,
    this.onClose,
    this.showIcon = true,
    this.icon = Icons.lightbulb,
    this.backgroundColor = const Color(0xFFFFF8E1), // Light amber
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  State<AnimatedTutorialHint> createState() => _AnimatedTutorialHintState();
}

class _AnimatedTutorialHintState extends State<AnimatedTutorialHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
    
    // Start the animation
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppTheme.kenteGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.kenteGold.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppTheme.kenteGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hint',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onClose != null)
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPulsatingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPulsatingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3 + (0.7 * (value > 0.5 ? 1.0 - value : value) * 2),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.kenteGold.withOpacity(0.3),
                  AppTheme.kenteGold,
                  AppTheme.kenteGold.withOpacity(0.3),
                ],
                stops: [0.0, value, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
      child: Container(),
    );
  }
}
