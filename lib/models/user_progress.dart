import 'pattern_difficulty.dart';

class UserProgress {
  final String userId;
  final PatternDifficulty currentLevel;
  final Map<String, LessonProgress> lessonProgress;
  final List<String> completedLessons;
  final Map<String, List<String>> unlockedSkills;
  final int totalScore;
  /// Map of story IDs to lists of completed node IDs
  final Map<String, List<String>> completedStoryNodes;

  UserProgress({
    required this.userId,
    this.currentLevel = PatternDifficulty.basic,
    Map<String, LessonProgress>? lessonProgress,
    List<String>? completedLessons,
    Map<String, List<String>>? unlockedSkills,
    this.totalScore = 0,
    Map<String, List<String>>? completedStoryNodes,
  })  : lessonProgress = lessonProgress ?? {},
        completedLessons = completedLessons ?? [],
        unlockedSkills = unlockedSkills ?? {},
        completedStoryNodes = completedStoryNodes ?? {};

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] as String,
      currentLevel: PatternDifficulty.values.firstWhere(
        (d) => d.toString() == 'PatternDifficulty.${json['currentLevel']}',
        orElse: () => PatternDifficulty.basic,
      ),
      lessonProgress: (json['lessonProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, LessonProgress.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      completedLessons: List<String>.from(json['completedLessons'] as List? ?? []),
      unlockedSkills: (json['unlockedSkills'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          {},
      totalScore: json['totalScore'] as int? ?? 0,
      completedStoryNodes: (json['completedStoryNodes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentLevel': currentLevel.toString().split('.').last,
      'lessonProgress': lessonProgress.map((k, v) => MapEntry(k, v.toJson())),
      'completedLessons': completedLessons,
      'unlockedSkills': unlockedSkills,
      'totalScore': totalScore,
      'completedStoryNodes': completedStoryNodes,
    };
  }

  UserProgress copyWith({
    String? userId,
    PatternDifficulty? currentLevel,
    Map<String, LessonProgress>? lessonProgress,
    List<String>? completedLessons,
    Map<String, List<String>>? unlockedSkills,
    int? totalScore,
    Map<String, List<String>>? completedStoryNodes,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      completedLessons: completedLessons ?? this.completedLessons,
      unlockedSkills: unlockedSkills ?? this.unlockedSkills,
      totalScore: totalScore ?? this.totalScore,
      completedStoryNodes: completedStoryNodes ?? this.completedStoryNodes,
    );
  }
  
  /// Add a completed story node to the user's progress
  UserProgress addCompletedStoryNode(String storyId, String nodeId) {
    final Map<String, List<String>> updatedNodes = Map.from(completedStoryNodes);
    
    if (updatedNodes.containsKey(storyId)) {
      if (!updatedNodes[storyId]!.contains(nodeId)) {
        updatedNodes[storyId] = [...updatedNodes[storyId]!, nodeId];
      }
    } else {
      updatedNodes[storyId] = [nodeId];
    }
    
    return copyWith(completedStoryNodes: updatedNodes);
  }
  
  /// Check if a story node has been completed
  bool hasCompletedStoryNode(String storyId, String nodeId) {
    return completedStoryNodes[storyId]?.contains(nodeId) ?? false;
  }
  
  /// Get all completed nodes for a story
  List<String> getCompletedNodesForStory(String storyId) {
    return completedStoryNodes[storyId] ?? [];
  }
  
  /// Add a completed lesson to the user's progress
  UserProgress addCompletedLesson(String lessonId) {
    if (completedLessons.contains(lessonId)) {
      return this;
    }
    
    return copyWith(
      completedLessons: [...completedLessons, lessonId],
    );
  }
}

class LessonProgress {
  final double bestScore;
  final int attempts;
  final bool isCompleted;
  final DateTime lastAttempt;

  LessonProgress({
    this.bestScore = 0.0,
    this.attempts = 0,
    this.isCompleted = false,
    DateTime? lastAttempt,
  }) : lastAttempt = lastAttempt ?? DateTime.now();

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      bestScore: (json['bestScore'] as num).toDouble(),
      attempts: json['attempts'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastAttempt: DateTime.parse(json['lastAttempt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestScore': bestScore,
      'attempts': attempts,
      'isCompleted': isCompleted,
      'lastAttempt': lastAttempt.toIso8601String(),
    };
  }

  LessonProgress copyWith({
    double? bestScore,
    int? attempts,
    bool? isCompleted,
    DateTime? lastAttempt,
  }) {
    return LessonProgress(
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      isCompleted: isCompleted ?? this.isCompleted,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }
}
