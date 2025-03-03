import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing different audio types for sound effects and music
enum AudioType {
  // Sound effects
  buttonTap,
  cancelTap,
  confirmationTap,
  navigationTap,
  success,    // Added success sound type
  failure,    // Added failure sound type
  achievement, // Added achievement sound type

  // Background music
  mainTheme,
  menuTheme,
  learningTheme,
  challengeTheme, // Added challenge theme music
}

/// Service for handling all audio-related functionality in the app
class AudioService {
  // Singleton pattern implementation
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players for different sound types
  final Map<AudioType, AudioPlayer> _soundEffectPlayers = {};
  final Map<AudioType, AudioPlayer> _musicPlayers = {};

  // Audio settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;
  AudioType? _currentlyPlayingMusic;

  // Getters for settings
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  AudioType? get currentlyPlayingMusic => _currentlyPlayingMusic;

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      // Load settings from persistent storage
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _soundVolume = prefs.getDouble('sound_volume') ?? 1.0;
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
      _soundEnabled = true;
      _musicEnabled = true;
      _soundVolume = 1.0;
      _musicVolume = 0.5;
    }
  }

  /// Preload a sound effect for immediate playback later
  Future<void> _preloadSoundEffect(AudioType type, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      await player.setVolume(_soundVolume);
      _soundEffectPlayers[type] = player;
    } catch (e) {
      debugPrint('Error preloading sound effect ($type): $e');
      // Create a silent player as fallback to prevent null errors
      final player = AudioPlayer();
      _soundEffectPlayers[type] = player;
    }
  }

  /// Preload music for smoother playback later
  Future<void> _preloadMusic(AudioType type, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      await player.setVolume(_musicVolume);
      await player.setLoopMode(LoopMode.all);
      _musicPlayers[type] = player;
    } catch (e) {
      debugPrint('Error preloading music ($type): $e');
      // Create a silent player as fallback to prevent null errors
      final player = AudioPlayer();
      _musicPlayers[type] = player;
    }
  }

  /// Play a sound effect
  Future<void> playSoundEffect(AudioType type) async {
    if (!_soundEnabled) return;

    final player = _soundEffectPlayers[type];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
      } catch (e) {
        debugPrint('Error playing sound effect ($type): $e');
      }
    } else {
      debugPrint('Warning: Sound effect player not found for type: $type');
    }
  }

  /// Play background music
  Future<void> playMusic(AudioType type) async {
    if (!_musicEnabled) return;

    // Don't restart if same music is already playing
    if (_currentlyPlayingMusic == type &&
        _musicPlayers[type]?.playing == true) {
      return;
    }

    // Stop any currently playing music
    await stopAllMusic();

    final player = _musicPlayers[type];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
        _currentlyPlayingMusic = type;
      } catch (e) {
        debugPrint('Error playing music ($type): $e');
      }
    } else {
      debugPrint('Warning: Music player not found for type: $type');
    }
  }

  /// Stop currently playing music
  Future<void> stopCurrentMusic() async {
    if (_currentlyPlayingMusic != null) {
      final player = _musicPlayers[_currentlyPlayingMusic!];
      if (player != null) {
        try {
          await player.stop();
        } catch (e) {
          debugPrint('Error stopping music: $e');
        }
      }
      _currentlyPlayingMusic = null;
    }
  }

  /// Stop all background music
  Future<void> stopAllMusic() async {
    for (final player in _musicPlayers.values) {
      try {
        await player.stop();
      } catch (e) {
        debugPrint('Error stopping music: $e');
      }
    }
    _currentlyPlayingMusic = null;
  }

  /// Pause currently playing music
  Future<void> pauseMusic() async {
    if (_currentlyPlayingMusic != null) {
      final player = _musicPlayers[_currentlyPlayingMusic!];
      if (player != null && player.playing) {
        try {
          await player.pause();
        } catch (e) {
          debugPrint('Error pausing music: $e');
        }
      }
    }
  }

  /// Resume previously paused music
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;

    if (_currentlyPlayingMusic != null) {
      final player = _musicPlayers[_currentlyPlayingMusic!];
      if (player != null && !player.playing) {
        try {
          await player.play();
        } catch (e) {
          debugPrint('Error resuming music: $e');
        }
      }
    }
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  /// Toggle background music on/off
  Future<void> toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);

    if (!enabled) {
      await stopAllMusic();
    } else if (_currentlyPlayingMusic != null) {
      // Resume the last playing music if we're turning music back on
      await playMusic(_currentlyPlayingMusic!);
    }
  }

  /// Set sound effect volume
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', volume);

    // Update all sound effect players with new volume
    for (final player in _soundEffectPlayers.values) {
      try {
        await player.setVolume(volume);
      } catch (e) {
        debugPrint('Error setting sound volume: $e');
      }
    }
  }

  /// Set background music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', volume);

    // Update all music players with new volume
    for (final player in _musicPlayers.values) {
      try {
        await player.setVolume(volume);
      } catch (e) {
        debugPrint('Error setting music volume: $e');
      }
    }
  }

  /// Fade out the currently playing music
  Future<void> fadeOutMusic({Duration duration = const Duration(seconds: 2)}) async {
    if (_currentlyPlayingMusic == null) return;

    final player = _musicPlayers[_currentlyPlayingMusic!];
    if (player != null && player.playing) {
      try {
        // Start at current volume and fade to zero
        final steps = 20;
        final interval = duration.inMilliseconds ~/ steps;
        final startVolume = _musicVolume;
        final volumeStep = startVolume / steps;

        for (int i = 0; i < steps; i++) {
          final newVolume = startVolume - (volumeStep * i);
          await player.setVolume(newVolume);
          await Future.delayed(Duration(milliseconds: interval));
        }

        await player.stop();
        // Reset to original volume
        await player.setVolume(_musicVolume);
      } catch (e) {
        debugPrint('Error fading out music: $e');
        // Fallback to immediate stop
        await player.stop();
      }
    }
    _currentlyPlayingMusic = null;
  }

  /// Play a sound effect for a specific event type
  Future<void> playSoundForEvent(String eventType) async {
    switch (eventType) {
      case 'button':
        await playSoundEffect(AudioType.buttonTap);
        break;
      case 'confirm':
        await playSoundEffect(AudioType.confirmationTap);
        break;
      case 'cancel':
        await playSoundEffect(AudioType.cancelTap);
        break;
      case 'navigate':
        await playSoundEffect(AudioType.navigationTap);
        break;
      case 'success':
        await playSoundEffect(AudioType.success);
        break;
      case 'failure':
        await playSoundEffect(AudioType.failure);
        break;
      case 'achievement':
        await playSoundEffect(AudioType.achievement);
        break;
      default:
        await playSoundEffect(AudioType.buttonTap);
        break;
    }
  }

  /// Clean up resources when service is no longer needed
  Future<void> dispose() async {
    for (final player in _soundEffectPlayers.values) {
      await player.dispose();
    }
    for (final player in _musicPlayers.values) {
      await player.dispose();
    }
    _soundEffectPlayers.clear();
    _musicPlayers.clear();
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

      final player = _soundEffectPlayers[type];
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
      final player = _musicPlayers[type];
      if (player == null) {
        debugPrint('Warning: Music player not found for type: $type');
        allValid = false;
      }
    }

    return allValid;
  }
}