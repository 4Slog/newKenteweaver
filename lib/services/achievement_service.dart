import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/achievement_celebration.dart';
import 'dart:convert';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final String? hint;
  final int xpReward;
  final Map<String, dynamic>? requirements;
  final double? progress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.hint,
    this.xpReward = 50,
    this.requirements,
    this.progress,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageAsset': imageAsset,
    'hint': hint,
    'xpReward': xpReward,
    'requirements': requirements,
    'progress': progress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    imageAsset: json['imageAsset'],
    hint: json['hint'],
    xpReward: json['xpReward'] ?? 50,
    requirements: json['requirements'],
    progress: json['progress']?.toDouble(),
  );
}

class AchievementService {
  final StorageService _storage;
  final AudioService _audioService;
  final GlobalKey<NavigatorState> navigatorKey;

  static const String _achievementsKey = 'user_achievements';
  static const String _progressKey = 'achievement_progress';

  AchievementService(this._storage, this._audioService, this.navigatorKey);

  // Achievement definitions
  final Map<String, Achievement> _achievements = {
    'pattern_first': Achievement(
      id: 'pattern_first',
      title: 'First Pattern',
      description: 'Create your first Kente pattern',
      imageAsset: 'assets/images/achievements/pattern_first.png',
      xpReward: 50,
    ),
    'pattern_10': Achievement(
      id: 'pattern_10',
      title: 'Pattern Explorer',
      description: 'Create 10 different patterns',
      imageAsset: 'assets/images/achievements/pattern_10.png',
      hint: 'Try creating more patterns in the Coding Screen',
      xpReward: 100,
      requirements: {'patterns_created': 10},
    ),
    'pattern_master': Achievement(
      id: 'pattern_master',
      title: 'Pattern Master',
      description: 'Create all basic pattern types',
      imageAsset: 'assets/images/achievements/pattern_master.png',
      xpReward: 200,
      requirements: {'all_basic_patterns': true},
    ),
    'challenge_first': Achievement(
      id: 'challenge_first',
      title: 'Challenge Accepted',
      description: 'Complete your first challenge',
      imageAsset: 'assets/images/achievements/challenge_first.png',
      xpReward: 50,
    ),
    'challenge_5': Achievement(
      id: 'challenge_5',
      title: 'Challenge Enthusiast',
      description: 'Complete 5 challenges',
      imageAsset: 'assets/images/achievements/challenge_5.png',
      xpReward: 150,
      requirements: {'challenges_completed': 5},
    ),
    'challenge_advanced': Achievement(
      id: 'challenge_advanced',
      title: 'Advanced Challenger',
      description: 'Complete an advanced difficulty challenge',
      imageAsset: 'assets/images/achievements/challenge_advanced.png',
      hint: 'Try challenges in the Advanced section',
      xpReward: 200,
      requirements: {'advanced_challenge': true},
    ),
    // Add more achievements as needed
  };

  // Get all achievements
  List<Achievement> getAllAchievements() => _achievements.values.toList();

  // Get achievement by ID
  Achievement? getAchievement(String id) => _achievements[id];

  // Check if user has achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    final achievements = await _getUserAchievements(userId);
    return achievements.contains(achievementId);
  }

  // Get user's achievements
  Future<List<String>> _getUserAchievements(String userId) async {
    final data = await _storage.read('${_achievementsKey}_$userId');
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  // Get achievement progress
  Future<Map<String, double>> getProgress(String userId) async {
    final data = await _storage.read('${_progressKey}_$userId');
    if (data == null) return {};
    return Map<String, double>.from(jsonDecode(data));
  }

  // Update achievement progress
  Future<void> updateProgress(String userId, String achievementId, double progress) async {
    final currentProgress = await getProgress(userId);
    currentProgress[achievementId] = progress;
    await _storage.write(
      '${_progressKey}_$userId',
      jsonEncode(currentProgress),
    );
  }

  // Award achievement
  Future<void> awardAchievement(String userId, String achievementId) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return;

    final achievements = await _getUserAchievements(userId);
    if (achievements.contains(achievementId)) return;

    achievements.add(achievementId);
    await _storage.write(
      '${_achievementsKey}_$userId',
      jsonEncode(achievements),
    );

    // Play achievement sound
    if (_audioService.soundEnabled) {
      _audioService.playSoundEffect(AudioType.achievement);
    }

    // Show achievement celebration
    final context = navigatorKey.currentContext;
    if (context != null) {
      showAchievementCelebration(context, achievement);
    }
  }

  // Show achievement celebration
  void showAchievementCelebration(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementCelebration(
        title: achievement.title,
        description: achievement.description,
        iconPath: achievement.imageAsset,
        xpGained: achievement.xpReward,
      ),
    );
  }

  // Check and award pattern-related achievements
  Future<void> checkPatternAchievements(
    String userId,
    int patternsCreated,
    List<String> unlockedPatterns,
  ) async {
    if (patternsCreated == 1) {
      await awardAchievement(userId, 'pattern_first');
    }
    if (patternsCreated >= 10) {
      await awardAchievement(userId, 'pattern_10');
    }
    // Check for pattern master achievement
    final requiredPatterns = [
      'basic_stripe',
      'basic_zigzag',
      'basic_diamond',
      'basic_check',
    ];
    final hasAllBasicPatterns = requiredPatterns.every(
      (pattern) => unlockedPatterns.contains(pattern)
    );
    if (hasAllBasicPatterns) {
      await awardAchievement(userId, 'pattern_master');
    }
  }

  // Check and award challenge-related achievements
  Future<void> checkChallengeAchievements(
    String userId,
    int challengesCompleted,
    PatternDifficulty difficulty,
  ) async {
    if (challengesCompleted == 1) {
      await awardAchievement(userId, 'challenge_first');
    }
    if (challengesCompleted >= 5) {
      await awardAchievement(userId, 'challenge_5');
    }
    if (difficulty == PatternDifficulty.advanced) {
      await awardAchievement(userId, 'challenge_advanced');
    }
  }
} 