import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_type.dart';
import '../models/pattern_difficulty.dart';
import '../services/lesson_service.dart';

class AppStateProvider extends ChangeNotifier {
  final LessonService _lessonService = LessonService();
  bool _isInitialized = false;
  String? _userName;
  String? _userId;
  PatternDifficulty _currentDifficulty = PatternDifficulty.basic;
  LessonType _selectedLessonType = LessonType.tutorial;
  ThemeMode _themeMode = ThemeMode.system;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;

  bool get isInitialized => _isInitialized;
  String? get userName => _userName;
  PatternDifficulty get currentDifficulty => _currentDifficulty;
  LessonType get selectedLessonType => _selectedLessonType;
  LessonService get lessonService => _lessonService;
  ThemeMode get themeMode => _themeMode;
  bool get highContrastEnabled => _highContrastEnabled;
  double get textScaleFactor => _textScaleFactor;

  Future<String> getCurrentUserId() async {
    if (_userId == null) {
      // In a real app, this would load from secure storage
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    return _userId!;
  }

  Future<void> initialize() async {
    // Load user data from storage
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme settings
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    _highContrastEnabled = prefs.getBool('high_contrast_enabled') ?? false;
    _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;
    
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay
    _isInitialized = true;
    notifyListeners();
  }
  
  // Theme mode methods
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }
  
  Future<void> setHighContrast(bool enabled) async {
    _highContrastEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_enabled', enabled);
    notifyListeners();
  }
  
  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale_factor', factor);
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setDifficulty(PatternDifficulty difficulty) {
    _currentDifficulty = difficulty;
    notifyListeners();
  }

  void setLessonType(LessonType type) {
    _selectedLessonType = type;
    notifyListeners();
  }

  Future<void> recordProgress({
    required String lessonId,
    required double score,
    required Map<String, dynamic> data,
  }) async {
    // Save progress to storage
    await Future.delayed(const Duration(milliseconds: 500)); // Simulated delay
    
    // Update difficulty if needed
    if (score > 0.8 && _currentDifficulty != PatternDifficulty.expert) {
      final difficulties = PatternDifficulty.values;
      final currentIndex = difficulties.indexOf(_currentDifficulty);
      if (currentIndex < difficulties.length - 1) {
        _currentDifficulty = difficulties[currentIndex + 1];
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> getLessonProgress(String lessonId) async {
    // Get progress from storage
    await Future.delayed(const Duration(milliseconds: 500)); // Simulated delay
    return {
      'bestScore': 0.0,
      'attempts': 0,
      'isCompleted': false,
      'lastAttempt': DateTime.now().toIso8601String(),
    };
  }
}
