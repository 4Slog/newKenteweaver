import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final int level;
  final int experience;
  final int completedPatterns;
  final int completedChallenges;
  final Set<String> achievements;
  final Set<String> unlockedPatterns;
  final Set<String> viewedPatterns;
  final bool isPremium;
  final DateTime lastActiveDate;
  final int currentStreak;
  final Map<String, int> difficultyStats;
  
  // New fields for enhanced story tracking
  final Set<String> masteredConcepts;
  final Map<String, dynamic> storyProgress;
  final List<UserChoice> choiceHistory;

  UserModel({
    required this.id,
    required this.name,
    this.level = 1,
    this.experience = 0,
    this.completedPatterns = 0,
    this.completedChallenges = 0,
    Set<String>? achievements,
    Set<String>? unlockedPatterns,
    Set<String>? viewedPatterns,
    this.isPremium = false,
    required this.lastActiveDate,
    this.currentStreak = 0,
    Map<String, int>? difficultyStats,
    Set<String>? masteredConcepts,
    Map<String, dynamic>? storyProgress,
    List<UserChoice>? choiceHistory,
  })  : achievements = achievements ?? {},
        unlockedPatterns = unlockedPatterns ?? {},
        viewedPatterns = viewedPatterns ?? {},
        difficultyStats = difficultyStats ?? {},
        masteredConcepts = masteredConcepts ?? {},
        storyProgress = storyProgress ?? {},
        choiceHistory = choiceHistory ?? [];

  int get xp => experience;
  String get username => name;
  
  // New getters for story progress
  List<String> get completedStories => 
      storyProgress.entries
          .where((e) => e.value['completionScore'] != null && e.value['completionScore'] >= 0.9)
          .map((e) => e.key)
          .toList();
  
  List<String> get inProgressStories =>
      storyProgress.entries
          .where((e) => e.value['completionScore'] != null && e.value['completionScore'] < 0.9)
          .map((e) => e.key)
          .toList();
  
  double getStoryCompletionScore(String storyId) =>
      storyProgress[storyId]?['completionScore'] ?? 0.0;
  
  List<String> getStoryConcepts(String storyId) =>
      (storyProgress[storyId]?['conceptsPracticed'] as List?)?.cast<String>() ?? [];

  UserModel copyWith({
    String? id,
    String? name,
    int? level,
    int? experience,
    int? completedPatterns,
    int? completedChallenges,
    Set<String>? achievements,
    Set<String>? unlockedPatterns,
    Set<String>? viewedPatterns,
    bool? isPremium,
    DateTime? lastActiveDate,
    int? currentStreak,
    Map<String, int>? difficultyStats,
    Set<String>? masteredConcepts,
    Map<String, dynamic>? storyProgress,
    List<UserChoice>? choiceHistory,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      completedPatterns: completedPatterns ?? this.completedPatterns,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      achievements: achievements ?? this.achievements,
      unlockedPatterns: unlockedPatterns ?? this.unlockedPatterns,
      viewedPatterns: viewedPatterns ?? this.viewedPatterns,
      isPremium: isPremium ?? this.isPremium,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      difficultyStats: difficultyStats ?? this.difficultyStats,
      masteredConcepts: masteredConcepts ?? this.masteredConcepts,
      storyProgress: storyProgress ?? this.storyProgress,
      choiceHistory: choiceHistory ?? this.choiceHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'experience': experience,
      'completedPatterns': completedPatterns,
      'completedChallenges': completedChallenges,
      'achievements': achievements.toList(),
      'unlockedPatterns': unlockedPatterns.toList(),
      'viewedPatterns': viewedPatterns.toList(),
      'isPremium': isPremium,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'currentStreak': currentStreak,
      'difficultyStats': difficultyStats,
      'masteredConcepts': masteredConcepts.toList(),
      'storyProgress': storyProgress,
      'choiceHistory': choiceHistory.map((c) => c.toJson()).toList(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      experience: json['experience'] as int,
      completedPatterns: json['completedPatterns'] as int,
      completedChallenges: json['completedChallenges'] as int,
      achievements: Set<String>.from(json['achievements'] as List),
      unlockedPatterns: Set<String>.from(json['unlockedPatterns'] as List),
      viewedPatterns: Set<String>.from(json['viewedPatterns'] as List),
      isPremium: json['isPremium'] as bool,
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      currentStreak: json['currentStreak'] as int,
      difficultyStats: Map<String, int>.from(json['difficultyStats'] as Map),
      masteredConcepts: json['masteredConcepts'] != null
          ? Set<String>.from(json['masteredConcepts'] as List)
          : null,
      storyProgress: json['storyProgress'] as Map<String, dynamic>?,
      choiceHistory: json['choiceHistory'] != null
          ? (json['choiceHistory'] as List)
              .map((c) => UserChoice.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

/// Class for tracking user choices
class UserChoice {
  final String nodeId;
  final String choiceId;
  final String choiceText;
  final String timestamp;
  
  UserChoice({
    required this.nodeId,
    required this.choiceId,
    required this.choiceText,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'choiceId': choiceId,
    'choiceText': choiceText,
    'timestamp': timestamp,
  };
  
  factory UserChoice.fromJson(Map<String, dynamic> json) => UserChoice(
    nodeId: json['nodeId'] as String,
    choiceId: json['choiceId'] as String,
    choiceText: json['choiceText'] as String,
    timestamp: json['timestamp'] as String,
  );
}
