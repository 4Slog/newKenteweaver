import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';

class ChallengeFeedback extends StatelessWidget {
  final bool success;
  final String message;
  final String? hint;
  final VoidCallback onTryAgain;
  final VoidCallback onContinue;
  final PatternDifficulty difficulty;
  final Map<String, dynamic>? culturalContext;

  const ChallengeFeedback({
    Key? key,
    required this.success,
    required this.message,
    this.hint,
    required this.onTryAgain,
    required this.onContinue,
    this.difficulty = PatternDifficulty.basic,
    this.culturalContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: success ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getIcon(), color: _getIconColor(), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: _getTextColor(), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          _buildDifficultyIndicator(),
          if (culturalContext != null && difficulty != PatternDifficulty.basic) _buildCulturalContext(),
          if (!success && hint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: _getHintIconColor(), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hint!, style: TextStyle(color: _getHintTextColor(), fontSize: 14))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!success)
                TextButton.icon(
                  onPressed: onTryAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              if (!success) const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(backgroundColor: success ? Colors.green : Colors.orange, foregroundColor: Colors.white),
                icon: Icon(success ? Icons.check_circle : Icons.skip_next),
                label: Text(success ? 'Continue' : 'Skip Challenge'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(_getDifficultyIcon(), size: 16, color: _getDifficultyColor()),
          const SizedBox(width: 8),
          Text(_getDifficultyText(), style: TextStyle(color: _getDifficultyColor(), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCulturalContext() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(culturalContext?['name'] ?? 'Traditional Pattern', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(culturalContext?['meaning'] ?? '', style: const TextStyle(fontSize: 12)),
          if (difficulty == PatternDifficulty.advanced) ...[
            const SizedBox(height: 4),
            Text(culturalContext?['context'] ?? '', style: TextStyle(fontSize: 12, color: Colors.blue[700], fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (success) {
      switch (difficulty) {
        case PatternDifficulty.basic:
          return Colors.green[50]!;
        case PatternDifficulty.intermediate:
          return Colors.green[100]!;
        case PatternDifficulty.advanced:
        case PatternDifficulty.master:
          return Colors.green[200]!;
      }
    } else {
      switch (difficulty) {
        case PatternDifficulty.basic:
          return Colors.orange[50]!;
        case PatternDifficulty.intermediate:
          return Colors.orange[100]!;
        case PatternDifficulty.advanced:
        case PatternDifficulty.master:
          return Colors.orange[200]!;
      }
    }
  }

  IconData _getIcon() {
    if (success) {
      switch (difficulty) {
        case PatternDifficulty.basic:
          return Icons.check_circle;
        case PatternDifficulty.intermediate:
          return Icons.star;
        case PatternDifficulty.advanced:
        case PatternDifficulty.master:
          return Icons.workspace_premium;
      }
    }
    return Icons.info_outline;
  }

  Color _getIconColor() => success ? Colors.green : Colors.orange[700]!;

  Color _getTextColor() => success ? Colors.green[700]! : Colors.orange[700]!;

  Color _getHintIconColor() => Colors.orange[300]!;

  Color _getHintTextColor() => Colors.orange[700]!;

  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return Icons.speed;
      case PatternDifficulty.intermediate:
        return Icons.trending_up;
      case PatternDifficulty.advanced:
      case PatternDifficulty.master:
        return Icons.workspace_premium;
    }
  }

  Color _getDifficultyColor() {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return Colors.green;
      case PatternDifficulty.intermediate:
        return Colors.blue;
      case PatternDifficulty.advanced:
        return Colors.purple;
      case PatternDifficulty.master:
        return Colors.deepPurple;
    }
  }

  String _getDifficultyText() {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 'Basic Pattern';
      case PatternDifficulty.intermediate:
        return 'Intermediate Challenge';
      case PatternDifficulty.advanced:
        return 'Master Weaver Level';
      case PatternDifficulty.master:
        return 'Kente Mastery';
    }
  }
}

class AnimatedChallengeFeedback extends StatefulWidget {
  final bool success;
  final String message;
  final String? hint;
  final VoidCallback onTryAgain;
  final VoidCallback onContinue;
  final PatternDifficulty difficulty;
  final Map<String, dynamic>? culturalContext;

  const AnimatedChallengeFeedback({
    Key? key,
    required this.success,
    required this.message,
    this.hint,
    required this.onTryAgain,
    required this.onContinue,
    this.difficulty = PatternDifficulty.basic,
    this.culturalContext,
  }) : super(key: key);

  @override
  State<AnimatedChallengeFeedback> createState() => _AnimatedChallengeFeedbackState();
}

class _AnimatedChallengeFeedbackState extends State<AnimatedChallengeFeedback> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ChallengeFeedback(
          success: widget.success,
          message: widget.message,
          hint: widget.hint,
          onTryAgain: () => _controller.reverse().then((_) => widget.onTryAgain()),
          onContinue: () => _controller.reverse().then((_) => widget.onContinue()),
          difficulty: widget.difficulty,
          culturalContext: widget.culturalContext,
        ),
      ),
    );
  }
}