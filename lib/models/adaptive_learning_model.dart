import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';

/// Class representing a user's learning style preferences
class LearningStylePreferences {
  /// Whether the user prefers visual learning
  final bool prefersVisual;
  
  /// Whether the user prefers story-based learning
  final bool prefersStories;
  
  /// Whether the user prefers challenge-based learning
  final bool prefersChallenges;
  
  /// Whether the user prefers exploration over direct instruction
  final bool prefersExploration;
  
  /// Number of hints the user typically uses
  final int hintsUsedCount;
  
  /// Number of challenges the user has completed
  final int challengesCompletedCount;
  
  /// Map of interaction types to counts
  final Map<String, int> interactionCounts;
  
  /// Additional preference data
  final Map<String, dynamic> additionalPreferences;

  const LearningStylePreferences({
    this.prefersVisual = true,
    this.prefersStories = true,
    this.prefersChallenges = false,
    this.prefersExploration = false,
    this.hintsUsedCount = 0,
    this.challengesCompletedCount = 0,
    this.interactionCounts = const {},
    this.additionalPreferences = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'prefersVisual': prefersVisual,
      'prefersStories': prefersStories,
      'prefersChallenges': prefersChallenges,
      'prefersExploration': prefersExploration,
      'hintsUsedCount': hintsUsedCount,
      'challengesCompletedCount': challengesCompletedCount,
      'interactionCounts': interactionCounts,
      'additionalPreferences': additionalPreferences,
    };
  }

  /// Create from JSON
  factory LearningStylePreferences.fromJson(Map<String, dynamic> json) {
    return LearningStylePreferences(
      prefersVisual: json['prefersVisual'] ?? true,
      prefersStories: json['prefersStories'] ?? true,
      prefersChallenges: json['prefersChallenges'] ?? false,
      prefersExploration: json['prefersExploration'] ?? false,
      hintsUsedCount: json['hintsUsedCount'] ?? 0,
      challengesCompletedCount: json['challengesCompletedCount'] ?? 0,
      interactionCounts: json['interactionCounts'] != null
          ? Map<String, int>.from(json['interactionCounts'])
          : {},
      additionalPreferences: json['additionalPreferences'] ?? {},
    );
  }

  /// Create a copy with some properties changed
  LearningStylePreferences copyWith({
    bool? prefersVisual,
    bool? prefersStories,
    bool? prefersChallenges,
    bool? prefersExploration,
    int? hintsUsedCount,
    int? challengesCompletedCount,
    Map<String, int>? interactionCounts,
    Map<String, dynamic>? additionalPreferences,
  }) {
    return LearningStylePreferences(
      prefersVisual: prefersVisual ?? this.prefersVisual,
      prefersStories: prefersStories ?? this.prefersStories,
      prefersChallenges: prefersChallenges ?? this.prefersChallenges,
      prefersExploration: prefersExploration ?? this.prefersExploration,
      hintsUsedCount: hintsUsedCount ?? this.hintsUsedCount,
      challengesCompletedCount: challengesCompletedCount ?? this.challengesCompletedCount,
      interactionCounts: interactionCounts ?? this.interactionCounts,
      additionalPreferences: additionalPreferences ?? this.additionalPreferences,
    );
  }
  
  /// Get the recommended narrative ratio based on preferences
  double getRecommendedNarrativeRatio(PatternDifficulty difficulty) {
    // Base ratio on difficulty
    double baseRatio;
    switch (difficulty) {
      case PatternDifficulty.basic:
        baseRatio = 0.7; // 70% narrative, 30% challenges
        break;
      case PatternDifficulty.intermediate:
        baseRatio = 0.6; // 60% narrative, 40% challenges
        break;
      case PatternDifficulty.advanced:
        baseRatio = 0.5; // 50% narrative, 50% challenges
        break;
      case PatternDifficulty.master:
        baseRatio = 0.4; // 40% narrative, 60% challenges
        break;
    }
    
    // Adjust based on preferences
    if (prefersStories) {
      baseRatio += 0.1;
    }
    
    if (prefersChallenges) {
      baseRatio -= 0.1;
    }
    
    // Ensure ratio stays within reasonable bounds
    return baseRatio.clamp(0.3, 0.8);
  }
  
  /// Get the recommended hint frequency based on preferences
  String getRecommendedHintFrequency(PatternDifficulty difficulty) {
    // Base frequency on difficulty
    String baseFrequency;
    switch (difficulty) {
      case PatternDifficulty.basic:
        baseFrequency = 'frequent';
        break;
      case PatternDifficulty.intermediate:
        baseFrequency = 'moderate';
        break;
      case PatternDifficulty.advanced:
        baseFrequency = 'minimal';
        break;
      case PatternDifficulty.master:
        baseFrequency = 'rare';
        break;
    }
    
    // Adjust based on hint usage
    if (hintsUsedCount > 10) {
      // User uses hints frequently, provide more
      if (baseFrequency == 'minimal') return 'moderate';
      if (baseFrequency == 'rare') return 'minimal';
    } else if (hintsUsedCount < 3 && challengesCompletedCount > 5) {
      // User rarely uses hints, provide fewer
      if (baseFrequency == 'frequent') return 'moderate';
      if (baseFrequency == 'moderate') return 'minimal';
    }
    
    return baseFrequency;
  }
}

/// Class representing a user's concept mastery
class ConceptMastery {
  /// Map of concept IDs to mastery levels (0.0-1.0)
  final Map<String, double> masteryLevels;
  
  /// Timestamp of last update
  final DateTime lastUpdated;
  
  /// Minimum mastery level to consider a concept mastered
  static const double masteryThreshold = 0.7;

  ConceptMastery({
    this.masteryLevels = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'masteryLevels': masteryLevels,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ConceptMastery.fromJson(Map<String, dynamic> json) {
    final masteryMap = json['masteryLevels'] as Map<String, dynamic>? ?? {};
    
    // Convert to Map<String, double>
    final typedMastery = masteryMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
    
    return ConceptMastery(
      masteryLevels: typedMastery,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  /// Create a copy with some properties changed
  ConceptMastery copyWith({
    Map<String, double>? masteryLevels,
    DateTime? lastUpdated,
  }) {
    return ConceptMastery(
      masteryLevels: masteryLevels ?? this.masteryLevels,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Get mastery level for a specific concept
  double getMasteryLevel(String conceptId) {
    return masteryLevels[conceptId] ?? 0.0;
  }
  
  /// Check if a concept is mastered
  bool isConceptMastered(String conceptId) {
    return getMasteryLevel(conceptId) >= masteryThreshold;
  }
  
  /// Get all mastered concepts
  List<String> getMasteredConcepts() {
    return masteryLevels.entries
        .where((entry) => entry.value >= masteryThreshold)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get concepts that need improvement (below threshold)
  List<String> getConceptsNeedingImprovement() {
    return masteryLevels.entries
        .where((entry) => entry.value < masteryThreshold && entry.value > 0.0)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get average mastery across all concepts
  double getAverageMastery() {
    if (masteryLevels.isEmpty) return 0.0;
    
    double total = 0.0;
    masteryLevels.values.forEach((value) => total += value);
    return total / masteryLevels.length;
  }
  
  /// Get recommended difficulty based on mastery levels
  PatternDifficulty getRecommendedDifficulty() {
    final averageMastery = getAverageMastery();
    
    if (averageMastery >= 0.9) {
      return PatternDifficulty.master;
    } else if (averageMastery >= 0.7) {
      return PatternDifficulty.advanced;
    } else if (averageMastery >= 0.4) {
      return PatternDifficulty.intermediate;
    } else {
      return PatternDifficulty.basic;
    }
  }
  
  /// Update mastery level for a concept
  ConceptMastery updateMastery(String conceptId, double newLevel) {
    final updatedLevels = Map<String, double>.from(masteryLevels);
    
    // Calculate new mastery level (weighted average with existing mastery)
    final currentLevel = updatedLevels[conceptId] ?? 0.0;
    final weightedLevel = (currentLevel * 0.7) + (newLevel * 0.3);
    
    updatedLevels[conceptId] = weightedLevel.clamp(0.0, 1.0);
    
    return copyWith(
      masteryLevels: updatedLevels,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Apply decay to mastery levels based on time since last update
  ConceptMastery applyDecay(int daysSinceLastUpdate) {
    if (daysSinceLastUpdate <= 0) return this;
    
    // Calculate decay factor (5% per day)
    final decayFactor = 0.05 * daysSinceLastUpdate;
    
    // Apply decay to each concept
    final decayedLevels = Map<String, double>.from(masteryLevels);
    
    decayedLevels.forEach((concept, level) {
      final newLevel = level * (1.0 - decayFactor);
      decayedLevels[concept] = newLevel.clamp(0.1, 1.0); // Don't go below 0.1
    });
    
    return copyWith(
      masteryLevels: decayedLevels,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Class representing a user's adaptive learning profile
class AdaptiveLearningProfile extends ChangeNotifier {
  /// User ID
  final String userId;
  
  /// Learning style preferences
  LearningStylePreferences _preferences;
  
  /// Concept mastery
  ConceptMastery _conceptMastery;
  
  /// Recent interactions for analysis
  final List<Map<String, dynamic>> _recentInteractions;
  
  /// Maximum number of recent interactions to store
  static const int _maxRecentInteractions = 50;

  AdaptiveLearningProfile({
    required this.userId,
    LearningStylePreferences? preferences,
    ConceptMastery? conceptMastery,
    List<Map<String, dynamic>>? recentInteractions,
  })  : _preferences = preferences ?? const LearningStylePreferences(),
        _conceptMastery = conceptMastery ?? ConceptMastery(),
        _recentInteractions = recentInteractions ?? [];

  /// Get learning style preferences
  LearningStylePreferences get preferences => _preferences;
  
  /// Get concept mastery
  ConceptMastery get conceptMastery => _conceptMastery;
  
  /// Get recent interactions
  List<Map<String, dynamic>> get recentInteractions => 
      List.unmodifiable(_recentInteractions);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferences': _preferences.toJson(),
      'conceptMastery': _conceptMastery.toJson(),
      'recentInteractions': _recentInteractions,
    };
  }

  /// Create from JSON
  factory AdaptiveLearningProfile.fromJson(Map<String, dynamic> json) {
    return AdaptiveLearningProfile(
      userId: json['userId'],
      preferences: json['preferences'] != null
          ? LearningStylePreferences.fromJson(json['preferences'])
          : null,
      conceptMastery: json['conceptMastery'] != null
          ? ConceptMastery.fromJson(json['conceptMastery'])
          : null,
      recentInteractions: json['recentInteractions'] != null
          ? List<Map<String, dynamic>>.from(json['recentInteractions'])
          : null,
    );
  }

  /// Update learning preferences
  void updatePreferences(LearningStylePreferences newPreferences) {
    _preferences = newPreferences;
    notifyListeners();
  }

  /// Update concept mastery
  void updateConceptMastery(ConceptMastery newMastery) {
    _conceptMastery = newMastery;
    notifyListeners();
  }

  /// Record a user interaction
  void recordInteraction(
    String interactionType,
    String elementId, {
    Map<String, dynamic>? data,
  }) {
    final interaction = {
      'type': interactionType,
      'elementId': elementId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data ?? {},
    };
    
    // Add to recent interactions
    _recentInteractions.add(interaction);
    
    // Limit the number of stored interactions
    if (_recentInteractions.length > _maxRecentInteractions) {
      _recentInteractions.removeAt(0);
    }
    
    // Update interaction counts in preferences
    final interactionCounts = Map<String, int>.from(_preferences.interactionCounts);
    interactionCounts[interactionType] = (interactionCounts[interactionType] ?? 0) + 1;
    
    // Update specific preference indicators based on interaction type
    bool? prefersVisual;
    bool? prefersStories;
    bool? prefersChallenges;
    bool? prefersExploration;
    int? hintsUsedCount;
    int? challengesCompletedCount;
    
    switch (interactionType) {
      case 'hint_used':
        hintsUsedCount = _preferences.hintsUsedCount + 1;
        break;
      case 'challenge_completed':
        challengesCompletedCount = _preferences.challengesCompletedCount + 1;
        break;
      case 'story_skipped':
        prefersStories = false;
        break;
      case 'story_engaged':
        prefersStories = true;
        break;
      case 'visual_aid_used':
        prefersVisual = true;
        break;
      case 'exploration_chosen':
        prefersExploration = true;
        break;
      case 'direct_solution_chosen':
        prefersExploration = false;
        break;
    }
    
    // Update preferences
    _preferences = _preferences.copyWith(
      prefersVisual: prefersVisual,
      prefersStories: prefersStories,
      prefersChallenges: prefersChallenges,
      prefersExploration: prefersExploration,
      hintsUsedCount: hintsUsedCount,
      challengesCompletedCount: challengesCompletedCount,
      interactionCounts: interactionCounts,
    );
    
    notifyListeners();
  }

  /// Update mastery level for a concept
  void updateConceptMasteryLevel(String conceptId, double newLevel) {
    _conceptMastery = _conceptMastery.updateMastery(conceptId, newLevel);
    notifyListeners();
  }

  /// Apply decay to mastery levels
  void applyMasteryDecay(int daysSinceLastUpdate) {
    _conceptMastery = _conceptMastery.applyDecay(daysSinceLastUpdate);
    notifyListeners();
  }
  
  /// Get personalized story parameters
  Map<String, dynamic> getPersonalizedStoryParams() {
    // Determine focus concepts (concepts with lowest mastery)
    final masteryLevels = _conceptMastery.masteryLevels;
    final sortedConcepts = masteryLevels.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final focusConcepts = sortedConcepts
        .take(3)
        .map((e) => e.key)
        .toList();
    
    // Determine recommended difficulty
    final difficulty = _conceptMastery.getRecommendedDifficulty();
    
    // Calculate narrative ratio
    final narrativeRatio = _preferences.getRecommendedNarrativeRatio(difficulty);
    
    // Get hint frequency
    final hintFrequency = _preferences.getRecommendedHintFrequency(difficulty);
    
    // Build personalized parameters
    return {
      'difficulty': difficulty.toString().split('.').last,
      'focusConcepts': focusConcepts,
      'narrativeRatio': narrativeRatio,
      'prefersVisual': _preferences.prefersVisual,
      'prefersExploration': _preferences.prefersExploration,
      'hintFrequency': hintFrequency,
      'challengeComplexity': _getChallengeComplexity(difficulty),
      'guidanceLevel': _getGuidanceLevel(difficulty),
    };
  }
  
  /// Get appropriate challenge complexity based on difficulty
  String _getChallengeComplexity(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 'low';
      case PatternDifficulty.intermediate:
        return 'moderate';
      case PatternDifficulty.advanced:
        return 'high';
      case PatternDifficulty.master:
        return 'expert';
    }
  }
  
  /// Get appropriate guidance level based on difficulty
  String _getGuidanceLevel(PatternDifficulty difficulty) {
    // Adjust based on exploration preference
    final prefersExploration = _preferences.prefersExploration;
    
    switch (difficulty) {
      case PatternDifficulty.basic:
        return prefersExploration ? 'medium' : 'high';
      case PatternDifficulty.intermediate:
        return prefersExploration ? 'low' : 'medium';
      case PatternDifficulty.advanced:
        return prefersExploration ? 'minimal' : 'low';
      case PatternDifficulty.master:
        return 'minimal';
    }
  }
}
