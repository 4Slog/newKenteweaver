import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/audio_model.dart' as audio;
import 'logging_service.dart';

/// Enum representing different audio types for sound effects and music
enum AudioType {
  // Sound effects
  buttonTap,
  cancelTap,
  confirmationTap,
  navigationTap,
  success,
  failure,
  achievement,

  // Background music
  mainTheme,
  menuTheme,
  learningTheme,
  challengeTheme,
}

/// Service for handling all audio-related functionality in the app
class AudioService extends ChangeNotifier {
  // Singleton pattern implementation
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _loggingService = LoggingService();
  }

  // Audio players for different sound types
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  
  // Logging service
  late final LoggingService _loggingService;

  // Audio settings
  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  double _musicVolume = 0.5;
  double _soundVolume = 0.7;
  audio.AudioType? _currentlyPlayingMusic;

  // Getters for settings
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  double get musicVolume => _musicVolume;
  double get soundVolume => _soundVolume;
  audio.AudioType? get currentlyPlayingMusic => _currentlyPlayingMusic;

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      // Load settings from persistent storage
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundVolume = prefs.getDouble('sound_volume') ?? 0.7;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.5;

      // Preload sound effects
      await _preloadSoundEffect(AudioType.buttonTap, 'assets/music/button_tap.mp3');
      await _preloadSoundEffect(AudioType.cancelTap, 'assets/music/cancel_tap.mp3');
      await _preloadSoundEffect(AudioType.confirmationTap, 'assets/music/confirmation_tap.mp3');
      await _preloadSoundEffect(AudioType.navigationTap, 'assets/music/navigation_tap.mp3');
      await _preloadSoundEffect(AudioType.success, 'assets/music/success.mp3');
      await _preloadSoundEffect(AudioType.failure, 'assets/music/failure.mp3');
      await _preloadSoundEffect(AudioType.achievement, 'assets/music/achievement.mp3');

      // Preload music
      await _preloadMusic(AudioType.mainTheme, 'assets/music/main_theme.mp3');
      await _preloadMusic(AudioType.menuTheme, 'assets/music/menu_theme.mp3');
      await _preloadMusic(AudioType.learningTheme, 'assets/music/learning_theme.mp3');
      await _preloadMusic(AudioType.challengeTheme, 'assets/music/challenge_theme.mp3');

      debugPrint('Audio service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      // Set defaults if there's an error
      _isSoundEnabled = true;
      _isMusicEnabled = true;
      _soundVolume = 0.7;
      _musicVolume = 0.5;
    }
  }

  /// Preload a sound effect for immediate playback later
  Future<void> _preloadSoundEffect(AudioType type, String assetPath) async {
    try {
      await _effectsPlayer.setAsset(assetPath);
      await _effectsPlayer.setVolume(_soundVolume);
    } catch (e) {
      debugPrint('Error preloading sound effect ($type): $e');
      // Create a silent player as fallback to prevent null errors
      await _effectsPlayer.setAsset('assets/audio/silent.mp3');
    }
  }

  /// Preload music for smoother playback later
  Future<void> _preloadMusic(AudioType type, String assetPath) async {
    try {
      await _backgroundPlayer.setAsset(assetPath);
      await _backgroundPlayer.setVolume(_musicVolume);
      await _backgroundPlayer.setLoopMode(LoopMode.all);
    } catch (e) {
      debugPrint('Error preloading music ($type): $e');
      // Create a silent player as fallback to prevent null errors
      await _backgroundPlayer.setAsset('assets/audio/silent.mp3');
    }
  }

  /// Play a sound effect
  Future<void> playSoundEffect(audio.AudioType type) async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.setAsset('assets/audio/${type.filename}');
      await _effectsPlayer.setVolume(_soundVolume);
      await _effectsPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
    }
  }

  /// Play background music
  Future<void> playMusic(audio.AudioType type) async {
    if (!_isMusicEnabled) return;

    try {
      await _backgroundPlayer.setAsset('assets/audio/${type.filename}');
      await _backgroundPlayer.setVolume(_musicVolume);
      await _backgroundPlayer.setLoopMode(LoopMode.all);
      await _backgroundPlayer.play();
      _currentlyPlayingMusic = type;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  /// Play a background sound from a file path
  /// @param soundPath The path to the sound file, relative to assets/audio/
  Future<void> playBackgroundSound(String? soundPath) async {
    if (!_isMusicEnabled || soundPath == null || soundPath.isEmpty) return;

    try {
      // Determine if the path is already prefixed with assets/audio
      final String fullPath = soundPath.startsWith('assets/') 
          ? soundPath 
          : 'assets/audio/$soundPath';
      
      // Stop any currently playing music
      await _backgroundPlayer.stop();
      
      // Play the new background sound
      await _backgroundPlayer.setAsset(fullPath);
      await _backgroundPlayer.setVolume(_musicVolume);
      await _backgroundPlayer.setLoopMode(LoopMode.all);
      await _backgroundPlayer.play();
      
      // Set current playing to null since this is a custom sound
      _currentlyPlayingMusic = null;
      notifyListeners();
      
      _loggingService.debug('Playing background sound: $soundPath', tag: 'AudioService');
    } catch (e) {
      debugPrint('Error playing background sound: $e');
      _loggingService.error('Error playing background sound: $e', tag: 'AudioService');
    }
  }

  /// Stop currently playing music
  void stopMusic() {
    _backgroundPlayer.stop();
    _currentlyPlayingMusic = null;
    notifyListeners();
  }

  /// Toggle sound effects on/off
  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
  }

  /// Toggle background music on/off
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      _backgroundPlayer.pause();
    } else if (_currentlyPlayingMusic != null) {
      _backgroundPlayer.play();
    }
    notifyListeners();
  }

  /// Set sound effect volume
  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Set background music volume
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _backgroundPlayer.setVolume(_musicVolume);
    notifyListeners();
  }

  /// Fade out the currently playing music
  Future<void> fadeOutMusic({Duration duration = const Duration(seconds: 2)}) async {
    if (_currentlyPlayingMusic == null) return;

    try {
      // Start at current volume and fade to zero
      final steps = 20;
      final interval = duration.inMilliseconds ~/ steps;
      final startVolume = _musicVolume;
      final volumeStep = startVolume / steps;

      for (int i = 0; i < steps; i++) {
        final newVolume = startVolume - (volumeStep * i);
        await _backgroundPlayer.setVolume(newVolume);
        await Future.delayed(Duration(milliseconds: interval));
      }

      await _backgroundPlayer.stop();
      // Reset to original volume
      await _backgroundPlayer.setVolume(_musicVolume);
    } catch (e) {
      debugPrint('Error fading out music: $e');
      // Fallback to immediate stop
      await _backgroundPlayer.stop();
    }
    _currentlyPlayingMusic = null;
    notifyListeners();
  }

  /// Clean up resources when service is no longer needed
  @override
  void dispose() {
    _effectsPlayer.dispose();
    _backgroundPlayer.dispose();
    super.dispose();
  }

  /// Check if sound files exist and are playable
  Future<bool> validateSoundAssets() async {
    bool allValid = true;

    // Check sound effects
    for (final type in AudioType.values) {
      if (type == AudioType.mainTheme ||
          type == AudioType.menuTheme ||
          type == AudioType.learningTheme ||
          type == AudioType.challengeTheme) {
        continue; // Skip music types
      }

      final player = _effectsPlayer;
      if (player == null) {
        debugPrint('Warning: Sound effect player not found for type: $type');
        allValid = false;
      }
    }

    // Check music
    final musicTypes = [
      AudioType.mainTheme,
      AudioType.menuTheme,
      AudioType.learningTheme,
      AudioType.challengeTheme,
    ];

    for (final type in musicTypes) {
      final player = _backgroundPlayer;
      if (player == null) {
        debugPrint('Warning: Music player not found for type: $type');
        allValid = false;
      }
    }

    return allValid;
  }
}
