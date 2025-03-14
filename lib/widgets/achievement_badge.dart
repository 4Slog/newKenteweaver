import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AchievementBadge extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final bool isUnlocked;
  final double? progress;
  final VoidCallback? onTap;

  const AchievementBadge({
    Key? key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.isUnlocked = false,
    this.progress,
    this.onTap,
  }) : super(key: key);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60,
      ),
    ]).animate(_controller);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 0.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20
      ),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.05, end: -0.05)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30
      ),
      TweenSequenceItem(
          tween: Tween<double>(begin: -0.05, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isUnlocked && widget.isUnlocked) {
      setState(() {
        _isNew = true;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUnlocked && _isNew ? _scaleAnimation.value : 1.0,
            child: Transform.rotate(
              angle: widget.isUnlocked && _isNew ? _rotateAnimation.value : 0.0,
              child: Card(
                elevation: widget.isUnlocked ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: widget.isUnlocked
                        ? AppTheme.kenteGold.withValues(alpha: _isNew ? (_glowAnimation.value * 0.8 + 0.2) : 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                    width: widget.isUnlocked ? 2 : 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: widget.isUnlocked
                        ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.kenteGold.withValues(alpha: 0.2),
                      ],
                    )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge image with overlay if locked
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Badge image
                          _buildBadgeImage(),

                          // Lock overlay
                          if (!widget.isUnlocked)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                          // New indicator
                          if (widget.isUnlocked && _isNew)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: widget.isUnlocked
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isUnlocked
                              ? null
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Progress indicator if available
                      if (widget.progress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: widget.progress!,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isUnlocked
                                  ? AppTheme.kenteGold
                                  : Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeImage() {
    Widget imageWidget;

    try {
      imageWidget = Image.asset(
        widget.imageAsset,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } catch (e) {
      imageWidget = _buildFallbackImage();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.isUnlocked ? 1.0 : 0.3,
      child: imageWidget,
    );
  }

  Widget _buildFallbackImage() {
    // Default icons based on achievement ID patterns
    IconData icon = Icons.emoji_events;
    Color color = AppTheme.kenteGold;

    if (widget.id.contains('pattern')) {
      icon = Icons.grid_on;
      color = Colors.blue;
    } else if (widget.id.contains('challenge')) {
      icon = Icons.sports;
      color = Colors.orange;
    } else if (widget.id.contains('story')) {
      icon = Icons.book;
      color = Colors.green;
    } else if (widget.id.contains('master')) {
      icon = Icons.workspace_premium;
      color = Colors.purple;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
