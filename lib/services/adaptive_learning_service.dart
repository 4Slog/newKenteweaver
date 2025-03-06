import 'dart:convert';
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
  
  // Getters
  Map<String, double> get conceptMastery => _conceptMastery;
  List<Map<String, dynamic>> get interactionHistory => _interactionHistory;
  PatternDifficulty get currentDifficulty => _currentDifficulty;
  Map<String, dynamic> get preferences => _preferences;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _loadData();
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
        return PatternDifficulty.master;
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
      _currentDifficulty = PatternDifficulty.master;
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
}
