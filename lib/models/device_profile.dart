import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';

/// Model class representing a device-based profile
class DeviceProfile {
  /// Unique device identifier
  final String deviceId;
  
  /// When the profile was created
  final DateTime createdAt;
  
  /// Current difficulty level
  final PatternDifficulty difficulty;
  
  /// Learning progress data
  final DeviceProfileProgress progress;
  
  /// User settings
  final DeviceProfileSettings settings;
  
  const DeviceProfile({
    required this.deviceId,
    required this.createdAt,
    required this.difficulty,
    required this.progress,
    required this.settings,
  });
  
  /// Create from JSON
  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      deviceId: json['deviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      difficulty: PatternDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => PatternDifficulty.basic,
      ),
      progress: DeviceProfileProgress.fromJson(json['progress'] as Map<String, dynamic>),
      settings: DeviceProfileSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty.toString(),
      'progress': progress.toJson(),
      'settings': settings.toJson(),
    };
  }
  
  /// Create a copy with some fields replaced
  DeviceProfile copyWith({
    String? deviceId,
    DateTime? createdAt,
    PatternDifficulty? difficulty,
    DeviceProfileProgress? progress,
    DeviceProfileSettings? settings,
  }) {
    return DeviceProfile(
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      progress: progress ?? this.progress,
      settings: settings ?? this.settings,
    );
  }
}

/// Model class representing learning progress
class DeviceProfileProgress {
  /// Completed lesson IDs
  final List<String> completedLessons;
  
  /// Completed challenge IDs
  final List<String> completedChallenges;
  
  /// Mastered concept IDs
  final List<String> masteredConcepts;
  
  /// Current story ID
  final String? currentStoryId;
  
  /// Unlocked pattern IDs
  final List<String> unlockedPatterns;
  
  const DeviceProfileProgress({
    required this.completedLessons,
    required this.completedChallenges,
    required this.masteredConcepts,
    this.currentStoryId,
    required this.unlockedPatterns,
  });
  
  /// Create from JSON
  factory DeviceProfileProgress.fromJson(Map<String, dynamic> json) {
    return DeviceProfileProgress(
      completedLessons: List<String>.from(json['completedLessons'] as List),
      completedChallenges: List<String>.from(json['completedChallenges'] as List),
      masteredConcepts: List<String>.from(json['masteredConcepts'] as List),
      currentStoryId: json['currentStoryId'] as String?,
      unlockedPatterns: List<String>.from(json['unlockedPatterns'] as List),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'completedLessons': completedLessons,
      'completedChallenges': completedChallenges,
      'masteredConcepts': masteredConcepts,
      'currentStoryId': currentStoryId,
      'unlockedPatterns': unlockedPatterns,
    };
  }
  
  /// Create a copy with some fields replaced
  DeviceProfileProgress copyWith({
    List<String>? completedLessons,
    List<String>? completedChallenges,
    List<String>? masteredConcepts,
    String? currentStoryId,
    List<String>? unlockedPatterns,
  }) {
    return DeviceProfileProgress(
      completedLessons: completedLessons ?? this.completedLessons,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      masteredConcepts: masteredConcepts ?? this.masteredConcepts,
      currentStoryId: currentStoryId ?? this.currentStoryId,
      unlockedPatterns: unlockedPatterns ?? this.unlockedPatterns,
    );
  }
}

/// Model class representing user settings
class DeviceProfileSettings {
  /// Whether sound effects are enabled
  final bool soundEnabled;
  
  /// Whether background music is enabled
  final bool musicEnabled;
  
  /// Interface language code
  final String language;
  
  /// Whether text-to-speech is enabled
  final bool textToSpeechEnabled;
  
  /// Whether high contrast mode is enabled
  final bool highContrastMode;
  
  /// Font size preference
  final String fontSize;
  
  const DeviceProfileSettings({
    required this.soundEnabled,
    required this.musicEnabled,
    required this.language,
    required this.textToSpeechEnabled,
    required this.highContrastMode,
    required this.fontSize,
  });
  
  /// Create from JSON
  factory DeviceProfileSettings.fromJson(Map<String, dynamic> json) {
    return DeviceProfileSettings(
      soundEnabled: json['soundEnabled'] as bool,
      musicEnabled: json['musicEnabled'] as bool,
      language: json['language'] as String,
      textToSpeechEnabled: json['textToSpeechEnabled'] as bool,
      highContrastMode: json['highContrastMode'] as bool,
      fontSize: json['fontSize'] as String,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'language': language,
      'textToSpeechEnabled': textToSpeechEnabled,
      'highContrastMode': highContrastMode,
      'fontSize': fontSize,
    };
  }
  
  /// Create a copy with some fields replaced
  DeviceProfileSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    String? language,
    bool? textToSpeechEnabled,
    bool? highContrastMode,
    String? fontSize,
  }) {
    return DeviceProfileSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      language: language ?? this.language,
      textToSpeechEnabled: textToSpeechEnabled ?? this.textToSpeechEnabled,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }
} 