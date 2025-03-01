import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Fixed import
import 'dart:convert'; // Added for JSON encoding/decoding
import '../models/pattern_difficulty.dart';
import '../services/ai_service.dart'; // For getNextSuggestedLesson
import '../providers/user_provider.dart'; // For user progress data

class Challenge {
  final String id;
  final String title;
  final String description;
  final List<String> requiredPatterns;
  final PatternDifficulty difficulty;
  final Map<String, dynamic>? constraints;
  final String? reward;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPatterns,
    this.difficulty = PatternDifficulty.basic,
    this.constraints,
    this.reward,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'requiredPatterns': requiredPatterns,
    'difficulty': difficulty.toString(),
    'constraints': constraints,
    'reward': reward,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredPatterns: List<String>.from(json['requiredPatterns'] as List),
      difficulty: PatternDifficulty.values.firstWhere(
            (d) => d.toString() == json['difficulty'],
        orElse: () => PatternDifficulty.basic,
      ),
      constraints: json['constraints'] as Map<String, dynamic>?,
      reward: json['reward'] as String?,
    );
  }
}

class TutorialService {
  final SharedPreferences _prefs;
  final AIService _aiService; // Added for AI-driven lesson suggestion
  static const String _lessonProgressKey = 'tutorial_lesson_progress';
  static const String _challengeProgressKey = 'tutorial_challenge_progress';
  static const String _hintsSeenKey = 'tutorial_hints_seen';

  final Map<String, Map<String, dynamic>> _lessons = {
    'basic_blocks': {
      'title': 'Introduction to Blocks',
      'prerequisites': [],
      'difficulty': PatternDifficulty.basic,
    },
    'color_blocks': {
      'title': 'Working with Colors',
      'prerequisites': ['basic_blocks'],
      'difficulty': PatternDifficulty.basic,
    },
    'patterns_intro': {
      'title': 'Basic Patterns',
      'prerequisites': ['color_blocks'],
      'difficulty': PatternDifficulty.basic,
    },
    'loops': {
      'title': 'Using Repetition',
      'prerequisites': ['patterns_intro'],
      'difficulty': PatternDifficulty.intermediate,
    },
    'rows_columns': {
      'title': 'Rows and Columns',
      'prerequisites': ['loops'],
      'difficulty': PatternDifficulty.intermediate,
    },
    'advanced_patterns': {
      'title': 'Advanced Patterns',
      'prerequisites': ['rows_columns'],
      'difficulty': PatternDifficulty.advanced,
    },
    'master_patterns': {
      'title': 'Master Level Patterns',
      'prerequisites': ['advanced_patterns'],
      'difficulty': PatternDifficulty.master,
    },
  };

  final Map<String, Challenge> _challenges = {};
  final Set<String> _completedLessons = {};
  final Set<String> _completedChallenges = {};
  final Set<String> _seenHints = {};

  TutorialService(this._prefs, this._aiService) {
    _loadProgress();
    _initializeChallenges();
  }

  void _loadProgress() {
    try {
      final completedLessons = _prefs.getStringList(_lessonProgressKey);
      if (completedLessons != null) {
        _completedLessons.addAll(completedLessons);
      }

      final completedChallenges = _prefs.getStringList(_challengeProgressKey);
      if (completedChallenges != null) {
        _completedChallenges.addAll(completedChallenges);
      }

      final seenHints = _prefs.getStringList(_hintsSeenKey);
      if (seenHints != null) {
        _seenHints.addAll(seenHints);
      }
    } catch (e) {
      debugPrint('Error loading tutorial progress: $e');
    }
  }

  void _initializeChallenges() {
    _challenges.addAll({
      'checker_basic': Challenge(
        id: 'checker_basic',
        title: 'Create a Basic Checker Pattern',
        description: 'Create a checker pattern using black and gold colors.',
        requiredPatterns: ['checker'],
        difficulty: PatternDifficulty.basic,
      ),
      'stripes_basic': Challenge(
        id: 'stripes_basic',
        title: 'Vertical Stripes Pattern',
        description: 'Create a vertical stripes pattern with three colors.',
        requiredPatterns: ['stripes_vertical'],
        difficulty: PatternDifficulty.basic,
      ),
      'diamond_advanced': Challenge(
        id: 'diamond_advanced',
        title: 'Complex Diamond Pattern',
        description: 'Create a diamond pattern with alternating colors.',
        requiredPatterns: ['diamond'],
        difficulty: PatternDifficulty.advanced,
      ),
      'master_challenge': Challenge(
        id: 'master_challenge',
        title: 'Master Weaver Challenge',
        description: 'Create a complex pattern combining multiple techniques.',
        requiredPatterns: ['master_weave'],
        difficulty: PatternDifficulty.master,
        reward: 'Master Weaver Badge',
      ),
    });
  }

  Map<String, Map<String, dynamic>> get lessons => _lessons;

  List<String> getAvailableLessons() {
    return _lessons.keys.where((lessonId) {
      final prerequisites = _lessons[lessonId]?['prerequisites'] as List<String>? ?? [];
      return prerequisites.every((prereq) => _completedLessons.contains(prereq));
    }).toList();
  }

  // Returns Map for ChallengeScreen compatibility
  Map<String, dynamic>? getChallenge(String challengeId) {
    final challenge = _challenges[challengeId];
    return challenge != null ? challenge.toJson() : null;
  }

  List<Challenge> getAvailableChallenges(PatternDifficulty maxDifficulty) {
    return _challenges.values
        .where((challenge) =>
    challenge.difficulty.index <= maxDifficulty.index &&
        !_completedChallenges.contains(challenge.id))
        .toList();
  }

  bool isLessonCompleted(String lessonId) {
    return _completedLessons.contains(lessonId);
  }

  bool isChallengeCompleted(String challengeId) {
    return _completedChallenges.contains(challengeId);
  }

  Future<void> markLessonCompleted(String lessonId) async {
    if (!_lessons.containsKey(lessonId)) {
      debugPrint('Warning: Attempted to complete unknown lesson: $lessonId');
      return;
    }

    _completedLessons.add(lessonId);
    await _prefs.setStringList(_lessonProgressKey, _completedLessons.toList());
  }

  Future<void> markChallengeCompleted(String challengeId) async {
    if (!_challenges.containsKey(challengeId)) {
      debugPrint('Warning: Attempted to complete unknown challenge: $challengeId');
      return;
    }

    _completedChallenges.add(challengeId);
    await _prefs.setStringList(_challengeProgressKey, _completedChallenges.toList());
  }

  Future<void> markHintSeen(String hintId) async {
    _seenHints.add(hintId);
    await _prefs.setStringList(_hintsSeenKey, _seenHints.toList());
  }

  bool hasSeenHint(String hintId) {
    return _seenHints.contains(hintId);
  }

  String getContextualHint({
    required String lessonId,
    required Map<String, dynamic> currentState,
    PatternDifficulty difficulty = PatternDifficulty.basic,
  }) {
    try {
      if (currentState['blockCount'] == 0) {
        return 'Start by dragging blocks from the toolbox to your workspace.';
      }

      if (!currentState['hasPattern']) {
        return 'Add a pattern block to define what type of Kente pattern you\'re creating.';
      }

      if (currentState['colors']?.isEmpty ?? true) {
        return 'Traditional Kente cloth uses meaningful colors. Add some color blocks to your pattern.';
      }

      switch (difficulty) {
        case PatternDifficulty.basic:
          if ((currentState['colors']?.length ?? 0) < 2) {
            return 'Traditional Kente patterns use at least two colors. Try adding another color.';
          }
          return 'Looking good! Make sure you have rows and columns set properly.';

        case PatternDifficulty.intermediate:
          if (!currentState['hasLoop']) {
            return 'More complex patterns use repetition. Try adding a loop block.';
          }
          if ((currentState['colors']?.length ?? 0) < 3) {
            return 'Intermediate patterns typically use at least three colors for visual richness.';
          }
          return 'Great progress! Experiment with different color placements.';

        case PatternDifficulty.advanced:
        case PatternDifficulty.master:
          if (!currentState['hasLoop']) {
            return 'Advanced patterns require repetition. Add a loop block.';
          }
          if ((currentState['colors']?.length ?? 0) < 4) {
            return 'Master weavers use at least four colors in complex patterns.';
          }
          return 'You\'re creating a complex pattern! Consider using traditional color combinations.';
      }
    } catch (e) {
      debugPrint('Error generating hint: $e');
    }

    return 'Try experimenting with different block combinations.';
  }

  // Added getNextSuggestedLesson
  Future<String?> getNextSuggestedLesson({
    required UserProvider userProvider,
  }) async {
    try {
      final availableLessons = getAvailableLessons();
      if (availableLessons.isEmpty) return null;

      // Prepare prompt for AI
      final completedLessonsJson = jsonEncode(_completedLessons.toList());
      final userStatsJson = jsonEncode({
        'level': userProvider.level,
        'xp': userProvider.xp,
        'completedPatterns': userProvider.completedPatterns,
        'completedChallenges': userProvider.completedChallenges,
        'difficultyStats': userProvider.difficultyStats.map(
              (k, v) => MapEntry(k.toString(), v),
        ),
      });
      final lessonsJson = jsonEncode(_lessons);

      final prompt = '''
Given the user's completed lessons: $completedLessonsJson
And user stats: $userStatsJson
Suggest the next lesson from available lessons: $lessonsJson
Return the lesson ID as a plain string (e.g., "loops").
''';

      // Using generateCulturalExplanation as a placeholder; adjust if AIService has a specific method
      final response = await _aiService.generateCulturalExplanation(
        patternType: 'suggestion',
        colors: [], // Placeholder; adjust if AIService expects colors
      );
      final suggestedLessonId = response.trim();

      // Validate the suggestion
      if (availableLessons.contains(suggestedLessonId)) {
        return suggestedLessonId;
      } else {
        // Fallback to first available lesson
        return availableLessons.first;
      }
    } catch (e) {
      debugPrint('Error getting next suggested lesson: $e');
      // Fallback to first available lesson if AI fails
      final availableLessons = getAvailableLessons();
      return availableLessons.isNotEmpty ? availableLessons.first : null;
    }
  }

  // Reset progress
  Future<void> resetProgress() async {
    _completedLessons.clear();
    _completedChallenges.clear();
    _seenHints.clear();

    await _prefs.remove(_lessonProgressKey);
    await _prefs.remove(_challengeProgressKey);
    await _prefs.remove(_hintsSeenKey);
  }
}