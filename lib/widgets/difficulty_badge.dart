import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';

class DifficultyBadge extends StatelessWidget {
  final PatternDifficulty difficulty;
  final bool showLabel;
  final double? size;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.showLabel = true,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: _getColor(),
            size: size ?? 16,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getLabel(),
              style: TextStyle(
                color: _getColor(),
                fontSize: size != null ? size! * 0.75 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return Colors.green;
      case PatternDifficulty.intermediate:
        return Colors.blue;
      case PatternDifficulty.advanced:
        return Colors.orange;
      case PatternDifficulty.master:
        return Colors.purple;
    }
  }

  IconData _getIcon() {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return Icons.star_border;
      case PatternDifficulty.intermediate:
        return Icons.star_half;
      case PatternDifficulty.advanced:
        return Icons.star;
      case PatternDifficulty.master:
        return Icons.auto_awesome;
    }
  }

  String _getLabel() {
    return difficulty.toString().split('.').last.toUpperCase();
  }
}
