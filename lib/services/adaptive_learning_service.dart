import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pattern_difficulty.dart';

/// Service for adaptive learning features
class AdaptiveLearningService extends ChangeNotifier {
  static final AdaptiveLearningService _instance = AdaptiveLearningService._internal();
  factory AdaptiveLearningService() => _instance;
  
  AdaptiveLearningService._internal();
  
  // User's concept mastery levels (0.0 to 1.0)
  Map<String, double> _conceptMastery = {};
  
  // User's interaction history
  List<Map<String, dynamic>> _interactionHistory = [];
  
  // User's difficulty level
  PatternDifficulty _currentDifficulty = PatternDifficulty.basic;
  
  // User's preferences
  Map<String, dynamic> _preferences = {};
  
  // Learning objectives and benchmarks
  static final Map<String, LearningObjective> _learningObjectives = {
    'sequences': LearningObjective(
      id: 'sequences',
      name: 'Pattern Sequences',
      description: 'Understanding and creating basic pattern sequences',
      levels: [
        'Recognize basic patterns',
        'Create simple sequences',
        'Modify existing patterns',
        'Optimize pattern sequences',
      ],
      benchmarks: {
        'basic': 0.3,
        'intermediate': 0.6,
        'advanced': 0.8,
        'master': 0.95,
      },
      prerequisites: [],
    ),
    'loops': LearningObjective(
      id: 'loops',
      name: 'Pattern Repetition',
      description: 'Using loops to create repeated patterns',
      levels: [
        'Identify repeated elements',
        'Use basic loops',
        'Nest multiple loops',
        'Optimize loop structures',
      ],
      benchmarks: {
        'basic': 0.4,
        'intermediate': 0.7,
        'advanced': 0.85,
        'master': 0.95,
      },
      prerequisites: ['sequences'],
    ),
    'variables': LearningObjective(
      id: 'variables',
      name: 'Pattern Parameters',
      description: 'Using variables to customize patterns',
      levels: [
        'Understand pattern properties',
        'Modify pattern values',
        'Create variable patterns',
        'Dynamic pattern generation',
      ],
      benchmarks: {
        'basic': 0.35,
        'intermediate': 0.65,
        'advanced': 0.85,
        'master': 0.95,
      },
      prerequisites: ['sequences', 'loops'],
    ),
  };

  // Enhanced progress tracking
  final Map<String, LearningProgress> _learningProgress = {};
  
  // Session tracking
  DateTime? _lastSessionTime;
  int _sessionDuration = 0;
  int _challengesCompleted = 0;
  
  // Performance metrics
  final Map<String, List<double>> _performanceHistory = {};
  final Map<String, int> _attemptCounts = {};
  
  // Getters
  Map<String, double> get conceptMastery => _conceptMastery;
  List<Map<String, dynamic>> get interactionHistory => _interactionHistory;
  PatternDifficulty get currentDifficulty => _currentDifficulty;
  Map<String, dynamic> get preferences => _preferences;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _loadData();
    await initializeProgress();
  }
  
  /// Load data from persistent storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load concept mastery
      final conceptMasteryJson = prefs.getString('concept_mastery');
      if (conceptMasteryJson != null) {
        final Map<String, dynamic> data = json.decode(conceptMasteryJson);
        _conceptMastery = data.map((key, value) => MapEntry(key, value.toDouble()));
      } else {
        _initializeDefaultConceptMastery();
      }
      
      // Load interaction history
      final historyJson = prefs.getString('interaction_history');
      if (historyJson != null) {
        final List<dynamic> data = json.decode(historyJson);
        _interactionHistory = data.cast<Map<String, dynamic>>();
      }
      
      // Load difficulty level
      final difficultyStr = prefs.getString('current_difficulty');
      if (difficultyStr != null) {
        _currentDifficulty = _parseDifficulty(difficultyStr);
      }
      
      // Load preferences
      final preferencesJson = prefs.getString('learning_preferences');
      if (preferencesJson != null) {
        _preferences = json.decode(preferencesJson);
      } else {
        _initializeDefaultPreferences();
      }
      
      debugPrint('Adaptive learning service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing adaptive learning service: $e');
      // Set defaults if there's an error
      _initializeDefaultConceptMastery();
      _initializeDefaultPreferences();
    }
  }
  
  /// Initialize default concept mastery levels
  void _initializeDefaultConceptMastery() {
    _conceptMastery = {
      'pattern_creation': 0.0,
      'color_selection': 0.0,
      'loop_usage': 0.0,
      'row_column_usage': 0.0,
      'cultural_understanding': 0.0,
    };
  }
  
  /// Initialize default preferences
  void _initializeDefaultPreferences() {
    _preferences = {
      'hint_frequency': 'normal', // 'frequent', 'normal', 'minimal'
      'preferred_learning_style': 'visual', // 'visual', 'interactive', 'reading'
      'cultural_context_level': 'detailed', // 'minimal', 'basic', 'detailed'
      'challenge_difficulty': 'adaptive', // 'easy', 'moderate', 'hard', 'adaptive'
    };
  }
  
  /// Parse difficulty string to enum
  PatternDifficulty _parseDifficulty(String difficultyStr) {
    switch (difficultyStr.toLowerCase()) {
      case 'basic':
        return PatternDifficulty.basic;
      case 'intermediate':
        return PatternDifficulty.intermediate;
      case 'advanced':
        return PatternDifficulty.advanced;
      case 'master':
        return PatternDifficulty.expert;
      default:
        return PatternDifficulty.basic;
    }
  }
  
  /// Save data to persistent storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save concept mastery
      await prefs.setString('concept_mastery', json.encode(_conceptMastery));
      
      // Save interaction history (limit to last 100 interactions)
      if (_interactionHistory.length > 100) {
        _interactionHistory = _interactionHistory.sublist(_interactionHistory.length - 100);
      }
      await prefs.setString('interaction_history', json.encode(_interactionHistory));
      
      // Save difficulty level
      await prefs.setString('current_difficulty', _currentDifficulty.toString().split('.').last);
      
      // Save preferences
      await prefs.setString('learning_preferences', json.encode(_preferences));
    } catch (e) {
      debugPrint('Error saving adaptive learning data: $e');
    }
  }
  
  /// Update concept mastery level
  Future<void> updateConceptMastery(String concept, double increment) async {
    if (!_conceptMastery.containsKey(concept)) {
      _conceptMastery[concept] = 0.0;
    }
    
    // Update mastery level (clamped between 0.0 and 1.0)
    _conceptMastery[concept] = (_conceptMastery[concept]! + increment).clamp(0.0, 1.0);
    
    // Save data
    await _saveData();
    
    // Check if difficulty level should be updated
    _checkDifficultyProgression();
    
    notifyListeners();
  }
  
  /// Record user interaction
  Future<void> recordInteraction(String type, String itemId, {Map<String, dynamic>? data}) async {
    final interaction = {
      'type': type,
      'itemId': itemId,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data ?? {},
    };
    
    _interactionHistory.add(interaction);
    
    // Save data
    await _saveData();
  }
  
  /// Set user preference
  Future<void> setPreference(String key, dynamic value) async {
    _preferences[key] = value;
    
    // Save data
    await _saveData();
    
    notifyListeners();
  }
  
  /// Check if difficulty level should be updated
  void _checkDifficultyProgression() {
    // Calculate average mastery level
    double avgMastery = 0.0;
    _conceptMastery.forEach((_, value) {
      avgMastery += value;
    });
    avgMastery /= _conceptMastery.length;
    
    // Update difficulty based on mastery level
    if (_currentDifficulty == PatternDifficulty.basic && avgMastery >= 0.7) {
      _currentDifficulty = PatternDifficulty.intermediate;
      notifyListeners();
    } else if (_currentDifficulty == PatternDifficulty.intermediate && avgMastery >= 0.8) {
      _currentDifficulty = PatternDifficulty.advanced;
      notifyListeners();
    } else if (_currentDifficulty == PatternDifficulty.advanced && avgMastery >= 0.9) {
      _currentDifficulty = PatternDifficulty.expert;
      notifyListeners();
    }
  }
  
  /// Set difficulty level manually
  Future<void> setDifficulty(PatternDifficulty difficulty) async {
    _currentDifficulty = difficulty;
    
    // Save data
    await _saveData();
    
    notifyListeners();
  }
  
  /// Get recommended hint frequency based on user performance
  String getRecommendedHintFrequency() {
    // Calculate average mastery level
    double avgMastery = 0.0;
    _conceptMastery.forEach((_, value) {
      avgMastery += value;
    });
    avgMastery /= _conceptMastery.length;
    
    // Recommend hint frequency based on mastery level
    if (avgMastery < 0.3) {
      return 'frequent';
    } else if (avgMastery < 0.7) {
      return 'normal';
    } else {
      return 'minimal';
    }
  }
  
  /// Get recommended challenge difficulty based on user performance
  String getRecommendedChallengeDifficulty() {
    // Calculate average mastery level
    double avgMastery = 0.0;
    _conceptMastery.forEach((_, value) {
      avgMastery += value;
    });
    avgMastery /= _conceptMastery.length;
    
    // Recommend challenge difficulty based on mastery level
    if (avgMastery < 0.3) {
      return 'easy';
    } else if (avgMastery < 0.6) {
      return 'moderate';
    } else {
      return 'hard';
    }
  }
  
  /// Get personalized hint based on user performance
  String getPersonalizedHint(String conceptKey, String defaultHint) {
    // Get mastery level for the concept
    final masteryLevel = _conceptMastery[conceptKey] ?? 0.0;
    
    // Return personalized hint based on mastery level
    if (masteryLevel < 0.3) {
      return defaultHint; // Detailed hint for beginners
    } else if (masteryLevel < 0.7) {
      // Simplified hint for intermediate users
      return defaultHint.split('.').first + '.';
    } else {
      // Minimal hint for advanced users
      return 'You\'ve got this!';
    }
  }
  
  /// Reset all data (for testing)
  Future<void> resetData() async {
    _initializeDefaultConceptMastery();
    _interactionHistory = [];
    _currentDifficulty = PatternDifficulty.basic;
    _initializeDefaultPreferences();
    
    // Save data
    await _saveData();
    
    notifyListeners();
  }

  // Initialize progress tracking
  Future<void> initializeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved progress
    final progressJson = prefs.getString('learning_progress');
    if (progressJson != null) {
      final Map<String, dynamic> data = jsonDecode(progressJson);
      _learningProgress.clear();
      data.forEach((key, value) {
        _learningProgress[key] = LearningProgress.fromJson(value);
      });
    } else {
      // Initialize default progress
      _learningObjectives.forEach((key, objective) {
        _learningProgress[key] = LearningProgress(
          objectiveId: key,
          currentLevel: 0,
          mastery: 0.0,
          lastPracticed: DateTime.now(),
        );
      });
    }
    
    notifyListeners();
  }

  // Enhanced progress update
  Future<void> updateProgress(String conceptId, double performance, {
    String? challengeType,
    int? completionTime,
    bool wasHintUsed = false,
  }) async {
    if (!_learningProgress.containsKey(conceptId)) {
      _learningProgress[conceptId] = LearningProgress(
        objectiveId: conceptId,
        currentLevel: 0,
        mastery: 0.0,
        lastPracticed: DateTime.now(),
      );
    }

    final progress = _learningProgress[conceptId]!;
    final objective = _learningObjectives[conceptId]!;
    
    // Update performance history
    _performanceHistory[conceptId] ??= [];
    _performanceHistory[conceptId]!.add(performance);
    
    // Track attempts
    _attemptCounts[conceptId] = (_attemptCounts[conceptId] ?? 0) + 1;
    
    // Calculate mastery increase based on multiple factors
    double masteryIncrease = _calculateMasteryIncrease(
      performance: performance,
      currentMastery: progress.mastery,
      wasHintUsed: wasHintUsed,
      completionTime: completionTime,
      attemptCount: _attemptCounts[conceptId]!,
    );
    
    // Update progress
    progress.mastery = (progress.mastery + masteryIncrease).clamp(0.0, 1.0);
    progress.lastPracticed = DateTime.now();
    
    // Check for level advancement
    _checkLevelAdvancement(progress, objective);
    
    // Save progress
    await _saveProgress();
    
    // Update difficulty if needed
    _checkDifficultyProgression();
    
    notifyListeners();
  }

  double _calculateMasteryIncrease({
    required double performance,
    required double currentMastery,
    required bool wasHintUsed,
    int? completionTime,
    required int attemptCount,
  }) {
    // Base increase from performance
    double increase = performance * 0.1;
    
    // Adjust based on hint usage
    if (wasHintUsed) {
      increase *= 0.8; // Reduced mastery gain when using hints
    }
    
    // Adjust based on completion time if available
    if (completionTime != null) {
      final timeBonus = _calculateTimeBonus(completionTime);
      increase *= timeBonus;
    }
    
    // Adjust based on current mastery (harder to improve at higher levels)
    increase *= (1.0 - (currentMastery * 0.5));
    
    // Adjust based on attempt count (diminishing returns)
    increase *= (1.0 / math.sqrt(attemptCount));
    
    return increase;
  }

  double _calculateTimeBonus(int completionTime) {
    // Example time bonus calculation
    // Faster completion = higher bonus, up to 1.5x
    const int targetTime = 300; // 5 minutes in seconds
    final ratio = targetTime / completionTime;
    return math.min(ratio, 1.5);
  }

  void _checkLevelAdvancement(LearningProgress progress, LearningObjective objective) {
    final currentBenchmark = objective.benchmarks.entries
        .firstWhere((entry) => progress.mastery < entry.value,
            orElse: () => objective.benchmarks.entries.last);
            
    final newLevel = objective.benchmarks.keys.toList().indexOf(currentBenchmark.key);
    if (newLevel > progress.currentLevel) {
      progress.currentLevel = newLevel;
      // Could trigger level-up celebration or rewards here
    }
  }

  // Get recommended next concept
  String? getRecommendedNextConcept() {
    // Filter concepts that have prerequisites met
    final availableConcepts = _learningObjectives.entries
        .where((entry) => _arePrerequisitesMet(entry.value))
        .map((entry) => entry.key)
        .toList();
    
    if (availableConcepts.isEmpty) return null;
    
    // Sort by various factors
    availableConcepts.sort((a, b) {
      final scoreA = _calculateConceptPriority(a);
      final scoreB = _calculateConceptPriority(b);
      return scoreB.compareTo(scoreA);
    });
    
    return availableConcepts.first;
  }

  bool _arePrerequisitesMet(LearningObjective objective) {
    return objective.prerequisites.every((prereq) {
      final progress = _learningProgress[prereq];
      return progress != null && progress.mastery >= 0.6; // 60% mastery required
    });
  }

  double _calculateConceptPriority(String conceptId) {
    final progress = _learningProgress[conceptId]!;
    final timeSinceLastPractice = DateTime.now().difference(progress.lastPracticed).inHours;
    
    // Combine factors:
    // 1. Current mastery (lower = higher priority)
    // 2. Time since last practice (longer = higher priority)
    // 3. Prerequisites mastery (higher = higher priority)
    // 4. Concept difficulty (matched to user level = higher priority)
    
    double priority = 0.0;
    
    // Mastery factor (inverse)
    priority += (1.0 - progress.mastery) * 0.4;
    
    // Time factor (normalized to max 1 week)
    priority += math.min(timeSinceLastPractice / (24 * 7), 1.0) * 0.3;
    
    // Prerequisites factor
    final prereqMastery = _calculatePrerequisitesMastery(conceptId);
    priority += prereqMastery * 0.2;
    
    // Difficulty match factor
    priority += _calculateDifficultyMatch(conceptId) * 0.1;
    
    return priority;
  }

  double _calculatePrerequisitesMastery(String conceptId) {
    final objective = _learningObjectives[conceptId]!;
    if (objective.prerequisites.isEmpty) return 1.0;
    
    double totalMastery = 0.0;
    for (final prereq in objective.prerequisites) {
      totalMastery += _learningProgress[prereq]?.mastery ?? 0.0;
    }
    return totalMastery / objective.prerequisites.length;
  }

  double _calculateDifficultyMatch(String conceptId) {
    final objective = _learningObjectives[conceptId]!;
    final userLevel = _currentDifficulty.index;
    final conceptLevel = objective.benchmarks.length - 1;
    
    // Return 1.0 for perfect match, decreasing for larger differences
    final difference = (userLevel - conceptLevel).abs();
    return 1.0 - (difference / 3).clamp(0.0, 1.0);
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert progress to JSON
      final progressData = _learningProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      
      // Save to SharedPreferences
      await prefs.setString('learning_progress', jsonEncode(progressData));
    } catch (e) {
      debugPrint('Error saving learning progress: $e');
    }
  }

  /// Get contextual blocks based on user's progress and current challenge
  Future<List<Map<String, dynamic>>> getContextualBlocks({
    required String conceptId,
    required String challengeType,
  }) async {
    final progress = _learningProgress[conceptId];
    final masteryLevel = progress?.mastery ?? 0.0;
    
    // Basic blocks always available
    final blocks = <Map<String, dynamic>>[
      {
        'type': 'basic_pattern',
        'difficulty': 'basic',
        'description': 'Simple repeating pattern block',
      },
      {
        'type': 'color_block',
        'difficulty': 'basic',
        'description': 'Basic color selection block',
      },
    ];
    
    // Add intermediate blocks if mastery is sufficient
    if (masteryLevel >= 0.4) {
      blocks.addAll([
        {
          'type': 'loop_block',
          'difficulty': 'intermediate',
          'description': 'Pattern repetition block',
        },
        {
          'type': 'variable_block',
          'difficulty': 'intermediate',
          'description': 'Pattern customization block',
        },
      ]);
    }
    
    // Add advanced blocks for high mastery
    if (masteryLevel >= 0.7) {
      blocks.addAll([
        {
          'type': 'nested_loop_block',
          'difficulty': 'advanced',
          'description': 'Complex pattern generation block',
        },
        {
          'type': 'dynamic_pattern_block',
          'difficulty': 'advanced',
          'description': 'Dynamic pattern modification block',
        },
      ]);
    }
    
    // Filter blocks based on challenge type
    return blocks.where((block) {
      switch (challengeType) {
        case 'pattern':
          return block['type'].toString().contains('pattern');
        case 'color':
          return block['type'].toString().contains('color');
        case 'loop':
          return block['type'].toString().contains('loop');
        default:
          return true;
      }
    }).toList();
  }
}

/// Model for learning objectives
class LearningObjective {
  final String id;
  final String name;
  final String description;
  final List<String> levels;
  final Map<String, double> benchmarks;
  final List<String> prerequisites;

  const LearningObjective({
    required this.id,
    required this.name,
    required this.description,
    required this.levels,
    required this.benchmarks,
    required this.prerequisites,
  });
}

/// Model for tracking progress
class LearningProgress {
  final String objectiveId;
  int currentLevel;
  double mastery;
  DateTime lastPracticed;

  LearningProgress({
    required this.objectiveId,
    required this.currentLevel,
    required this.mastery,
    required this.lastPracticed,
  });

  Map<String, dynamic> toJson() => {
    'objectiveId': objectiveId,
    'currentLevel': currentLevel,
    'mastery': mastery,
    'lastPracticed': lastPracticed.toIso8601String(),
  };

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      objectiveId: json['objectiveId'],
      currentLevel: json['currentLevel'],
      mastery: json['mastery'],
      lastPracticed: DateTime.parse(json['lastPracticed']),
    );
  }
}
