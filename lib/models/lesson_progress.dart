import 'pattern_difficulty.dart';
import 'lesson_type.dart';

class LessonProgress {
  final String lessonId;
  final String userId;
  final DateTime startedAt;
  DateTime? completedAt;
  int attemptsCount;
  double bestScore;
  Map<String, dynamic> lastAttemptData;
  Map<String, dynamic>? bestSolution;
  List<String> unlockedAchievements;
  bool isCompleted;
  List<String> hints;
  int hintsUsed;

  LessonProgress({
    required this.lessonId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    this.attemptsCount = 0,
    this.bestScore = 0.0,
    Map<String, dynamic>? lastAttemptData,
    this.bestSolution,
    List<String>? unlockedAchievements,
    this.isCompleted = false,
    List<String>? hints,
    this.hintsUsed = 0,
  })  : lastAttemptData = lastAttemptData ?? {},
        unlockedAchievements = unlockedAchievements ?? [],
        hints = hints ?? [];

  void incrementAttempts() {
    attemptsCount++;
  }

  void useHint(String hint) {
    if (!hints.contains(hint)) {
      hints.add(hint);
      hintsUsed++;
    }
  }

  void saveSolution(Map<String, dynamic> solution) {
    if (bestSolution == null || solution['score'] > bestSolution!['score']) {
      bestSolution = solution;
    }
  }

  bool hasUsedHint(String hint) => hints.contains(hint);

  bool get hasReachedHintLimit => hintsUsed >= 3;

  double get completionPercentage {
    if (isCompleted) return 100.0;
    if (attemptsCount == 0) return 0.0;
    return (bestScore * 100).clamp(0.0, 99.9);
  }

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] as String,
      userId: json['userId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0.0,
      lastAttemptData: json['lastAttemptData'] as Map<String, dynamic>? ?? {},
      unlockedAchievements:
          List<String>.from(json['unlockedAchievements'] as List? ?? []),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'userId': userId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'attemptsCount': attemptsCount,
      'bestScore': bestScore,
      'lastAttemptData': lastAttemptData,
      'unlockedAchievements': unlockedAchievements,
      'isCompleted': isCompleted,
    };
  }

  void recordAttempt({
    required double score,
    required Map<String, dynamic> attemptData,
    List<String>? newAchievements,
  }) {
    attemptsCount++;
    lastAttemptData = attemptData;
    
    if (score > bestScore) {
      bestScore = score;
    }

    if (newAchievements != null) {
      for (final achievement in newAchievements) {
        if (!unlockedAchievements.contains(achievement)) {
          unlockedAchievements.add(achievement);
        }
      }
    }

    if (score >= 0.8) { // 80% threshold for completion
      isCompleted = true;
      completedAt = DateTime.now();
    }
  }

  Duration get timeSpent {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  bool get isInProgress => !isCompleted && attemptsCount > 0;

  bool get needsReview => attemptsCount > 3 && !isCompleted;
}
