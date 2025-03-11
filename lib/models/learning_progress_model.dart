import 'package:flutter/foundation.dart';

/// Represents a collection of blocks used in a practice attempt
class BlockCollection {
  final List<Map<String, dynamic>> blocks;
  final String pattern;

  BlockCollection({
    required this.blocks,
    required this.pattern,
  });

  Map<String, dynamic> toJson() => {
    'blocks': blocks,
    'pattern': pattern,
  };
}

/// Tracks mastery level for a specific concept
class ConceptMastery {
  final String conceptId;
  double masteryLevel = 0.0;
  int totalAttempts = 0;
  int successfulAttempts = 0;

  ConceptMastery(this.conceptId);

  void addAttempt(BlockCollection attempt, Map<String, dynamic> result) {
    totalAttempts++;
    if (result['success'] == true) {
      successfulAttempts++;
    }
    
    // Update mastery level based on success rate and attempt complexity
    final successRate = successfulAttempts / totalAttempts;
    final complexity = _calculateComplexity(attempt);
    masteryLevel = (successRate * 0.7 + complexity * 0.3).clamp(0.0, 1.0);
  }

  double _calculateComplexity(BlockCollection attempt) {
    // Calculate complexity based on number of blocks and pattern type
    final blockCount = attempt.blocks.length;
    final hasLoops = attempt.blocks.any((b) => b['type'] == 'loop');
    final hasConditionals = attempt.blocks.any((b) => b['type'] == 'conditional');
    
    double complexity = blockCount / 20.0; // Normalize by max expected blocks
    if (hasLoops) complexity += 0.2;
    if (hasConditionals) complexity += 0.3;
    
    return complexity.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'conceptId': conceptId,
    'masteryLevel': masteryLevel,
    'totalAttempts': totalAttempts,
    'successfulAttempts': successfulAttempts,
  };
}

/// Records details of a practice attempt
class PracticeAttempt {
  final DateTime timestamp;
  final BlockCollection blocks;
  final Map<String, dynamic> result;
  final String storyContext;

  PracticeAttempt({
    required this.timestamp,
    required this.blocks,
    required this.result,
    required this.storyContext,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'blocks': blocks.toJson(),
    'result': result,
    'storyContext': storyContext,
  };
} 