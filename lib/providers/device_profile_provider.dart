import 'package:flutter/foundation.dart';
import '../models/device_profile.dart';
import '../models/pattern_difficulty.dart';
import '../services/device_profile_service.dart';

/// Provider for managing device profile state
class DeviceProfileProvider extends ChangeNotifier {
  final DeviceProfileService _service;
  
  /// Current device profile
  DeviceProfile? _profile;
  
  /// Loading state
  bool _isLoading = true;
  
  /// Error state
  String? _error;
  
  DeviceProfileProvider(this._service) {
    _initialize();
  }
  
  /// Get the current profile
  DeviceProfile? get profile => _profile;
  
  /// Get whether the provider is loading
  bool get isLoading => _isLoading;
  
  /// Get any error message
  String? get error => _error;
  
  /// Get whether a profile exists
  bool get hasProfile => _profile != null;
  
  /// Initialize the provider
  Future<void> _initialize() async {
    try {
      await _service.initialize();
      _profile = _service.currentProfile;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize profile: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update the profile
  Future<void> updateProfile(DeviceProfile newProfile) async {
    try {
      await _service.updateProfile(newProfile);
      _profile = newProfile;
      _error = null;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint(_error);
    }
    notifyListeners();
  }
  
  /// Update progress data
  Future<void> updateProgress(DeviceProfileProgress newProgress) async {
    try {
      await _service.updateProgress(newProgress);
      _profile = _profile?.copyWith(progress: newProgress);
      _error = null;
    } catch (e) {
      _error = 'Failed to update progress: $e';
      debugPrint(_error);
    }
    notifyListeners();
  }
  
  /// Update settings
  Future<void> updateSettings(DeviceProfileSettings newSettings) async {
    try {
      await _service.updateSettings(newSettings);
      _profile = _profile?.copyWith(settings: newSettings);
      _error = null;
    } catch (e) {
      _error = 'Failed to update settings: $e';
      debugPrint(_error);
    }
    notifyListeners();
  }
  
  /// Update difficulty level
  Future<void> updateDifficulty(PatternDifficulty newDifficulty) async {
    try {
      await _service.updateDifficulty(newDifficulty);
      _profile = _profile?.copyWith(difficulty: newDifficulty);
      _error = null;
    } catch (e) {
      _error = 'Failed to update difficulty: $e';
      debugPrint(_error);
    }
    notifyListeners();
  }
  
  /// Reset the profile
  Future<void> resetProfile() async {
    try {
      await _service.resetProfile();
      _profile = _service.currentProfile;
      _error = null;
    } catch (e) {
      _error = 'Failed to reset profile: $e';
      debugPrint(_error);
    }
    notifyListeners();
  }
  
  /// Add a completed lesson
  Future<void> addCompletedLesson(String lessonId) async {
    if (_profile == null) return;
    
    final currentProgress = _profile!.progress;
    if (currentProgress.completedLessons.contains(lessonId)) return;
    
    final newProgress = DeviceProfileProgress(
      completedLessons: [...currentProgress.completedLessons, lessonId],
      completedChallenges: currentProgress.completedChallenges,
      masteredConcepts: currentProgress.masteredConcepts,
      currentStoryId: currentProgress.currentStoryId,
      unlockedPatterns: currentProgress.unlockedPatterns,
    );
    
    await updateProgress(newProgress);
  }
  
  /// Add a completed challenge
  Future<void> addCompletedChallenge(String challengeId) async {
    if (_profile == null) return;
    
    final currentProgress = _profile!.progress;
    if (currentProgress.completedChallenges.contains(challengeId)) return;
    
    final newProgress = DeviceProfileProgress(
      completedLessons: currentProgress.completedLessons,
      completedChallenges: [...currentProgress.completedChallenges, challengeId],
      masteredConcepts: currentProgress.masteredConcepts,
      currentStoryId: currentProgress.currentStoryId,
      unlockedPatterns: currentProgress.unlockedPatterns,
    );
    
    await updateProgress(newProgress);
  }
  
  /// Add a mastered concept
  Future<void> addMasteredConcept(String conceptId) async {
    if (_profile == null) return;
    
    final currentProgress = _profile!.progress;
    if (currentProgress.masteredConcepts.contains(conceptId)) return;
    
    final newProgress = DeviceProfileProgress(
      completedLessons: currentProgress.completedLessons,
      completedChallenges: currentProgress.completedChallenges,
      masteredConcepts: [...currentProgress.masteredConcepts, conceptId],
      currentStoryId: currentProgress.currentStoryId,
      unlockedPatterns: currentProgress.unlockedPatterns,
    );
    
    await updateProgress(newProgress);
  }
  
  /// Set current story
  Future<void> setCurrentStory(String? storyId) async {
    if (_profile == null) return;
    
    final currentProgress = _profile!.progress;
    if (currentProgress.currentStoryId == storyId) return;
    
    final newProgress = DeviceProfileProgress(
      completedLessons: currentProgress.completedLessons,
      completedChallenges: currentProgress.completedChallenges,
      masteredConcepts: currentProgress.masteredConcepts,
      currentStoryId: storyId,
      unlockedPatterns: currentProgress.unlockedPatterns,
    );
    
    await updateProgress(newProgress);
  }
  
  /// Add an unlocked pattern
  Future<void> addUnlockedPattern(String patternId) async {
    if (_profile == null) return;
    
    final currentProgress = _profile!.progress;
    if (currentProgress.unlockedPatterns.contains(patternId)) return;
    
    final newProgress = DeviceProfileProgress(
      completedLessons: currentProgress.completedLessons,
      completedChallenges: currentProgress.completedChallenges,
      masteredConcepts: currentProgress.masteredConcepts,
      currentStoryId: currentProgress.currentStoryId,
      unlockedPatterns: [...currentProgress.unlockedPatterns, patternId],
    );
    
    await updateProgress(newProgress);
  }
  
  /// Toggle a setting
  Future<void> toggleSetting(String setting) async {
    if (_profile == null) return;
    
    final currentSettings = _profile!.settings;
    late final DeviceProfileSettings newSettings;
    
    switch (setting) {
      case 'sound':
        newSettings = currentSettings.copyWith(
          soundEnabled: !currentSettings.soundEnabled,
        );
        break;
      case 'music':
        newSettings = currentSettings.copyWith(
          musicEnabled: !currentSettings.musicEnabled,
        );
        break;
      case 'tts':
        newSettings = currentSettings.copyWith(
          textToSpeechEnabled: !currentSettings.textToSpeechEnabled,
        );
        break;
      case 'highContrast':
        newSettings = currentSettings.copyWith(
          highContrastMode: !currentSettings.highContrastMode,
        );
        break;
      default:
        return;
    }
    
    await updateSettings(newSettings);
  }
  
  /// Update language setting
  Future<void> updateLanguage(String languageCode) async {
    if (_profile == null) return;
    
    final currentSettings = _profile!.settings;
    if (currentSettings.language == languageCode) return;
    
    final newSettings = currentSettings.copyWith(
      language: languageCode,
    );
    
    await updateSettings(newSettings);
  }
  
  /// Update font size setting
  Future<void> updateFontSize(String fontSize) async {
    if (_profile == null) return;
    
    final currentSettings = _profile!.settings;
    if (currentSettings.fontSize == fontSize) return;
    
    final newSettings = currentSettings.copyWith(
      fontSize: fontSize,
    );
    
    await updateSettings(newSettings);
  }
} 