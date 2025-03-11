import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/pattern_difficulty.dart';

class AnalyticsService {
  final SharedPreferences _prefs;

  // Cache for analytics data
  final Map<String, int> _blockUsage = {};
  final Map<String, int> _patternUsage = {};
  final Map<String, int> _timeSpent = {};
  final Set<String> _featuresUsed = {};
  Map<String, int> _difficultyDistribution = {};
  final Map<String, Map<String, dynamic>> _lessonEngagement = {};

  // Keys for persistent storage
  static const String _prefsKeyBlockUsage = 'analytics_block_usage';
  static const String _prefsKeyPatternUsage = 'analytics_pattern_usage';
  static const String _prefsKeyTimeSpent = 'analytics_time_spent';
  static const String _prefsKeyFeaturesUsed = 'analytics_features_used';
  static const String _prefsKeyDifficultyDistribution = 'analytics_difficulty_distribution';
  static const String _prefsKeyLessonEngagement = 'analytics_lesson_engagement';

  AnalyticsService(this._prefs) {
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Load block usage
      final blockUsageStr = _prefs.getString(_prefsKeyBlockUsage);
      if (blockUsageStr != null) {
        _blockUsage.addAll(Map<String, int>.from(json.decode(blockUsageStr) as Map));
      }

      // Load pattern usage
      final patternUsageStr = _prefs.getString(_prefsKeyPatternUsage);
      if (patternUsageStr != null) {
        _patternUsage.addAll(Map<String, int>.from(json.decode(patternUsageStr) as Map));
      }

      // Load time spent
      final timeSpentStr = _prefs.getString(_prefsKeyTimeSpent);
      if (timeSpentStr != null) {
        _timeSpent.addAll(Map<String, int>.from(json.decode(timeSpentStr) as Map));
      }

      // Load features used
      final featuresUsedList = _prefs.getStringList(_prefsKeyFeaturesUsed);
      if (featuresUsedList != null) {
        _featuresUsed.addAll(featuresUsedList);
      }

      // Load difficulty distribution
      final difficultyStr = _prefs.getString(_prefsKeyDifficultyDistribution);
      if (difficultyStr != null) {
        _difficultyDistribution = Map<String, int>.from(json.decode(difficultyStr) as Map);
      }

      // Load lesson engagement
      final lessonEngagementStr = _prefs.getString(_prefsKeyLessonEngagement);
      if (lessonEngagementStr != null) {
        final decoded = json.decode(lessonEngagementStr) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _lessonEngagement[key] = Map<String, dynamic>.from(value as Map);
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _saveAnalytics() async {
    try {
      // Save block usage
      await _prefs.setString(_prefsKeyBlockUsage, json.encode(_blockUsage));

      // Save pattern usage
      await _prefs.setString(_prefsKeyPatternUsage, json.encode(_patternUsage));

      // Save time spent
      await _prefs.setString(_prefsKeyTimeSpent, json.encode(_timeSpent));

      // Save features used
      await _prefs.setStringList(_prefsKeyFeaturesUsed, _featuresUsed.toList());

      // Save difficulty distribution
      await _prefs.setString(_prefsKeyDifficultyDistribution, json.encode(_difficultyDistribution));

      // Save lesson engagement
      await _prefs.setString(_prefsKeyLessonEngagement, json.encode(_lessonEngagement));
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  void recordBlockUsage(String blockType) {
    _blockUsage[blockType] = (_blockUsage[blockType] ?? 0) + 1;
    _saveAnalytics();
  }

  void recordPatternCreated(String patternType) {
    _patternUsage[patternType] = (_patternUsage[patternType] ?? 0) + 1;
    _saveAnalytics();
  }

  void recordTimeSpent(String section, int seconds) {
    _timeSpent[section] = (_timeSpent[section] ?? 0) + seconds;
    _saveAnalytics();
  }

  void recordFeatureUsed(String feature) {
    _featuresUsed.add(feature);
    _saveAnalytics();
  }

  void recordDifficultyUsed(PatternDifficulty difficulty) {
    final difficultyName = difficulty.toString().split('.').last;
    _difficultyDistribution[difficultyName] = (_difficultyDistribution[difficultyName] ?? 0) + 1;
    _saveAnalytics();
  }

  void recordLessonEngagement({
    required String lessonId,
    required PatternDifficulty difficulty,
    Map<String, dynamic>? additionalData,
  }) {
    final engagement = _lessonEngagement[lessonId] ?? {};
    engagement['last_accessed'] = DateTime.now().toIso8601String();
    engagement['difficulty'] = difficulty.toString().split('.').last;
    engagement['access_count'] = (engagement['access_count'] ?? 0) + 1;
    
    if (additionalData != null) {
      engagement.addAll(additionalData);
    }

    _lessonEngagement[lessonId] = engagement;
    _saveAnalytics();
    
    debugPrint('Lesson engagement recorded for: $lessonId');
  }

  // Analytics retrieval methods
  Map<String, int> getBlockUsageStats() => Map.from(_blockUsage);
  Map<String, int> getPatternUsageStats() => Map.from(_patternUsage);
  Map<String, int> getTimeSpentStats() => Map.from(_timeSpent);
  Set<String> getFeaturesUsed() => Set.from(_featuresUsed);
  Map<String, int> getDifficultyDistribution() => Map.from(_difficultyDistribution);
  Map<String, Map<String, dynamic>> getLessonEngagementStats() => Map.from(_lessonEngagement);

  void endSession() {
    _saveAnalytics();
    debugPrint('Analytics session ended and data saved.');
  }

  Future<void> clearAnalytics() async {
    _blockUsage.clear();
    _patternUsage.clear();
    _timeSpent.clear();
    _featuresUsed.clear();
    _difficultyDistribution.clear();
    _lessonEngagement.clear();

    await _prefs.remove(_prefsKeyBlockUsage);
    await _prefs.remove(_prefsKeyPatternUsage);
    await _prefs.remove(_prefsKeyTimeSpent);
    await _prefs.remove(_prefsKeyFeaturesUsed);
    await _prefs.remove(_prefsKeyDifficultyDistribution);
    await _prefs.remove(_prefsKeyLessonEngagement);
  }

  // Export analytics data
  Map<String, dynamic> exportAnalytics() {
    return {
      'blockUsage': _blockUsage,
      'patternUsage': _patternUsage,
      'timeSpent': _timeSpent,
      'featuresUsed': _featuresUsed.toList(),
      'difficultyDistribution': _difficultyDistribution,
      'lessonEngagement': _lessonEngagement,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
}
