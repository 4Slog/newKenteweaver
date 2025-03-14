import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pattern_difficulty.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/logging_service.dart';

/// Service for adaptive learning features
class AdaptiveLearningService extends ChangeNotifier {
  final GeminiService _geminiService;
  final StorageService _storageService;
  final LoggingService _loggingService;
  
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
        'Understand loop concept',
        'Create basic loops',
        'Nest loops for complex patterns',
        'Optimize loop efficiency',
      ],
      benchmarks: {
        'basic': 0.3,
        'intermediate': 0.6,
        'advanced': 0.8,
        'master': 0.95,
      },
      prerequisites: ['sequences'],
    ),
    'conditions': LearningObjective(
      id: 'conditions',
      name: 'Conditional Logic',
      description: 'Using conditions to create dynamic patterns',
      levels: [
        'Understand conditional statements',
        'Apply simple conditions',
        'Combine multiple conditions',
        'Create complex conditional logic',
      ],
      benchmarks: {
        'basic': 0.3,
        'intermediate': 0.6,
        'advanced': 0.8,
        'master': 0.95,
      },
      prerequisites: ['loops'],
    ),
  };
  
  // Singleton pattern with dependency injection
  static AdaptiveLearningService? _instance;
  
  /// Private constructor to enforce singleton pattern
  AdaptiveLearningService._({
    required GeminiService geminiService,
    required StorageService storageService,
    required LoggingService loggingService,
  }) : _geminiService = geminiService,
       _storageService = storageService,
       _loggingService = loggingService {
    _loadUserData();
  }
  
  /// Factory constructor to get the singleton instance
  factory AdaptiveLearningService({
    required GeminiService geminiService,
    required StorageService storageService,
    required LoggingService loggingService,
  }) {
    _instance ??= AdaptiveLearningService._(
      geminiService: geminiService,
      storageService: storageService,
      loggingService: loggingService,
    );
    return _instance!;
  }
  
  /// Get the user's current difficulty level
  PatternDifficulty get currentDifficulty => _currentDifficulty;
  
  /// Get the user's concept mastery levels
  Map<String, double> get conceptMastery => Map.unmodifiable(_conceptMastery);
  
  /// Get the user's preferences
  Map<String, dynamic> get preferences => Map.unmodifiable(_preferences);
  
  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      // Load concept mastery
      final conceptData = await _storageService.read('concept_mastery');
      if (conceptData != null) {
        _conceptMastery = Map<String, double>.from(jsonDecode(conceptData));
      }
      
      // Load interaction history
      final historyData = await _storageService.read('interaction_history');
      if (historyData != null) {
        _interactionHistory = List<Map<String, dynamic>>.from(jsonDecode(historyData));
      }
      
      // Load difficulty level
      final difficultyData = await _storageService.read('current_difficulty');
      if (difficultyData != null) {
        _currentDifficulty = PatternDifficulty.values.firstWhere(
          (d) => d.toString() == difficultyData,
          orElse: () => PatternDifficulty.basic,
        );
      }
      
      // Load preferences
      final prefsData = await _storageService.read('learning_preferences');
      if (prefsData != null) {
        _preferences = jsonDecode(prefsData);
      }
      
      notifyListeners();
    } catch (e) {
      _loggingService.log('Failed to load user data: $e');
    }
  }
  
  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      await _storageService.write('concept_mastery', jsonEncode(_conceptMastery));
      await _storageService.write('interaction_history', jsonEncode(_interactionHistory));
      await _storageService.write('current_difficulty', _currentDifficulty.toString());
      await _storageService.write('learning_preferences', jsonEncode(_preferences));
    } catch (e) {
      _loggingService.log('Failed to save user data: $e');
    }
  }
  
  /// Get the mastery level for a specific concept
  double getConceptMastery(String conceptId) {
    return _conceptMastery[conceptId] ?? 0.0;
  }
  
  /// Update the mastery level for a specific concept
  Future<void> updateConceptMastery({
    required String conceptId,
    required double performance,
    double learningRate = 0.1,
  }) async {
    // Get current mastery level
    double currentMastery = _conceptMastery[conceptId] ?? 0.0;
    
    // Calculate mastery update
    double masteryUpdate = learningRate * performance;
    
    // Apply diminishing returns for higher mastery levels
    if (currentMastery > 0.7) {
      masteryUpdate *= (1.0 - currentMastery);
    }
    
    // Update mastery level
    double newMastery = (currentMastery + masteryUpdate).clamp(0.0, 1.0);
    _conceptMastery[conceptId] = newMastery;
    
    // Record interaction
    _interactionHistory.add({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'conceptId': conceptId,
      'performance': performance,
      'masteryBefore': currentMastery,
      'masteryAfter': newMastery,
    });
    
    // Check for difficulty adjustment
    _checkDifficultyAdjustment();
    
    // Save user data
    await _saveUserData();
    
    notifyListeners();
  }
  
  /// Check if difficulty level should be adjusted
  void _checkDifficultyAdjustment() {
    // Get average mastery level for current difficulty
    final conceptsForDifficulty = _getConceptsForDifficulty(_currentDifficulty);
    if (conceptsForDifficulty.isEmpty) return;
    
    double totalMastery = 0.0;
    int count = 0;
    
    for (final conceptId in conceptsForDifficulty) {
      final mastery = _conceptMastery[conceptId] ?? 0.0;
      totalMastery += mastery;
      count++;
    }
    
    final averageMastery = count > 0 ? totalMastery / count : 0.0;
    
    // Adjust difficulty if needed
    if (averageMastery >= 0.8 && _currentDifficulty != PatternDifficulty.expert) {
      // Increase difficulty
      _currentDifficulty = PatternDifficulty.values[
        math.min(_currentDifficulty.index + 1, PatternDifficulty.values.length - 1)
      ];
    } else if (averageMastery <= 0.2 && _currentDifficulty != PatternDifficulty.basic) {
      // Decrease difficulty
      _currentDifficulty = PatternDifficulty.values[
        math.max(_currentDifficulty.index - 1, 0)
      ];
    }
  }
  
  /// Get concepts for a specific difficulty level
  List<String> _getConceptsForDifficulty(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return ['sequences'];
      case PatternDifficulty.intermediate:
        return ['sequences', 'loops'];
      case PatternDifficulty.advanced:
        return ['sequences', 'loops', 'conditions'];
      case PatternDifficulty.expert:
        return ['sequences', 'loops', 'conditions'];
      default:
        return ['sequences'];
    }
  }
  
  /// Generate a personalized learning path
  Future<List<String>> generatePersonalizedPath() async {
    try {
      // Generate path using Gemini API
      final response = await _geminiService.generateLearningPath(
        conceptMastery: _conceptMastery,
        difficulty: _currentDifficulty,
        preferences: _preferences,
      );
      
      return List<String>.from(response['path']);
    } catch (e) {
      _loggingService.log('Failed to generate learning path: $e');
      
      // Fallback to default path
      return _getDefaultPath();
    }
  }
  
  /// Get a default learning path
  List<String> _getDefaultPath() {
    final availableConcepts = _getConceptsForDifficulty(_currentDifficulty);
    
    // Sort concepts by mastery level (lowest first)
    availableConcepts.sort((a, b) => 
      (_conceptMastery[a] ?? 0.0).compareTo(_conceptMastery[b] ?? 0.0)
    );
    
    return availableConcepts;
  }
  
  /// Set user preference
  Future<void> setPreference(String key, dynamic value) async {
    _preferences[key] = value;
    await _saveUserData();
    notifyListeners();
  }
  
  /// Get available blocks based on user's progress
  Future<List<String>> getAvailableBlocks() async {
    final blocks = <String>[];
    
    // Basic blocks always available
    blocks.add('color');
    blocks.add('move');
    
    // Add blocks based on concept mastery
    if ((_conceptMastery['sequences'] ?? 0.0) >= 0.3) {
      blocks.add('repeat');
    }
    
    if ((_conceptMastery['loops'] ?? 0.0) >= 0.3) {
      blocks.add('for_loop');
      blocks.add('while_loop');
    }
    
    if ((_conceptMastery['conditions'] ?? 0.0) >= 0.3) {
      blocks.add('if');
      blocks.add('if_else');
    }
    
    return blocks;
  }
  
  /// Reset user progress
  Future<void> resetProgress() async {
    _conceptMastery.clear();
    _interactionHistory.clear();
    _currentDifficulty = PatternDifficulty.basic;
    
    await _saveUserData();
    notifyListeners();
  }
}

/// Learning objective model
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
