import 'dart:convert';
import '../models/user_progress.dart';
import '../models/pattern_difficulty.dart';
import 'storage_service.dart';

class ProgressService {
  final StorageService _storage;
  final Map<String, UserProgress> _cache = {};

  ProgressService(this._storage);

  Future<UserProgress> getUserProgress(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final data = await _storage.read('user_progress_$userId');
      if (data != null) {
        final progress = UserProgress.fromJson(jsonDecode(data));
        _cache[userId] = progress;
        return progress;
      }
    } catch (e) {
      // Handle error, possibly log it
    }

    // Return default progress if none exists
    return UserProgress(userId: userId);
  }

  Future<void> updateProgress(String userId, UserProgress progress) async {
    try {
      final data = jsonEncode(progress.toJson());
      await _storage.write('user_progress_$userId', data);
      _cache[userId] = progress;
    } catch (e) {
      // Handle error, possibly log it
      rethrow;
    }
  }

  Future<void> recordLessonAttempt({
    required String userId,
    required String lessonId,
    required double score,
    required Map<String, dynamic> data,
  }) async {
    final progress = await getUserProgress(userId);
    final currentLessonProgress = progress.lessonProgress[lessonId];
    
    final newLessonProgress = LessonProgress(
      bestScore: score > (currentLessonProgress?.bestScore ?? 0.0) ? score : (currentLessonProgress?.bestScore ?? 0.0),
      attempts: (currentLessonProgress?.attempts ?? 0) + 1,
      isCompleted: score >= 0.8,
      lastAttempt: DateTime.now(),
    );

    final updatedProgress = progress.copyWith(
      lessonProgress: {
        ...progress.lessonProgress,
        lessonId: newLessonProgress,
      },
      completedLessons: score >= 0.8 && !progress.completedLessons.contains(lessonId)
          ? [...progress.completedLessons, lessonId]
          : progress.completedLessons,
    );

    // Check if user should level up
    final shouldLevelUp = _checkForLevelUp(updatedProgress);
    if (shouldLevelUp) {
      final currentIndex = PatternDifficulty.values.indexOf(progress.currentLevel);
      if (currentIndex < PatternDifficulty.values.length - 1) {
        final newLevel = PatternDifficulty.values[currentIndex + 1];
        final leveledUpProgress = updatedProgress.copyWith(currentLevel: newLevel);
        await updateProgress(userId, leveledUpProgress);
        return;
      }
    }

    await updateProgress(userId, updatedProgress);
  }

  bool _checkForLevelUp(UserProgress progress) {
    final completedCount = progress.completedLessons.length;
    final averageScore = progress.lessonProgress.values
        .map((p) => p.bestScore)
        .fold(0.0, (a, b) => a + b) /
        progress.lessonProgress.length;

    switch (progress.currentLevel) {
      case PatternDifficulty.basic:
        return completedCount >= 5 && averageScore >= 0.7;
      case PatternDifficulty.intermediate:
        return completedCount >= 10 && averageScore >= 0.75;
      case PatternDifficulty.advanced:
        return completedCount >= 15 && averageScore >= 0.8;
      case PatternDifficulty.master:
        return false; // Already at max level
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
  }
}
