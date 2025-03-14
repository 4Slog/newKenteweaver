import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pattern_difficulty.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Audio settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;

  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;

  // Notification settings
  bool _notificationsEnabled = true;

  // Difficulty settings
  PatternDifficulty _defaultDifficulty = PatternDifficulty.basic;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  ThemeMode get themeMode => _themeMode;
  bool get highContrastEnabled => _highContrastEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get notificationsEnabled => _notificationsEnabled;
  PatternDifficulty get defaultDifficulty => _defaultDifficulty;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Load settings from SharedPreferences
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _musicEnabled = _prefs.getBool('music_enabled') ?? true;
    _soundVolume = _prefs.getDouble('sound_volume') ?? 1.0;
    _musicVolume = _prefs.getDouble('music_volume') ?? 0.5;
    _themeMode = ThemeMode.values[_prefs.getInt('theme_mode') ?? 0];
    _highContrastEnabled = _prefs.getBool('high_contrast') ?? false;
    _textScaleFactor = _prefs.getDouble('text_scale') ?? 1.0;
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _defaultDifficulty = PatternDifficulty.values[_prefs.getInt('default_difficulty') ?? 0];
    
    _isInitialized = true;
    notifyListeners();
  }

  // Setters with persistence
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _prefs.setBool('music_enabled', value);
    notifyListeners();
  }

  Future<void> setSoundVolume(double value) async {
    _soundVolume = value;
    await _prefs.setDouble('sound_volume', value);
    notifyListeners();
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value;
    await _prefs.setDouble('music_volume', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrastEnabled = value;
    await _prefs.setBool('high_contrast', value);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double value) async {
    _textScaleFactor = value;
    await _prefs.setDouble('text_scale', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setDefaultDifficulty(PatternDifficulty difficulty) async {
    _defaultDifficulty = difficulty;
    await _prefs.setInt('default_difficulty', difficulty.index);
    notifyListeners();
  }

  // Reset settings to defaults
  Future<void> resetToDefaults() async {
    _soundEnabled = true;
    _musicEnabled = true;
    _soundVolume = 1.0;
    _musicVolume = 0.5;
    _themeMode = ThemeMode.system;
    _highContrastEnabled = false;
    _textScaleFactor = 1.0;
    _notificationsEnabled = true;
    _defaultDifficulty = PatternDifficulty.basic;

    await Future.wait([
      _prefs.setBool('sound_enabled', true),
      _prefs.setBool('music_enabled', true),
      _prefs.setDouble('sound_volume', 1.0),
      _prefs.setDouble('music_volume', 0.5),
      _prefs.setInt('theme_mode', 0),
      _prefs.setBool('high_contrast', false),
      _prefs.setDouble('text_scale', 1.0),
      _prefs.setBool('notifications_enabled', true),
      _prefs.setInt('default_difficulty', 0),
    ]);

    notifyListeners();
  }
} 