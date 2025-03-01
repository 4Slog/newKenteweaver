import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioType {
  buttonTap,
  cancelTap,
  confirmationTap,
  navigationTap,
  mainTheme,
  menuTheme,
  learningTheme,
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Map<AudioType, AudioPlayer> _soundEffectPlayers = {};
  final Map<AudioType, AudioPlayer> _musicPlayers = {};
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;
  
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  
  // Initialize the audio service
  Future<void> initialize() async {
    // Load settings
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
    
    // Preload music
    await _preloadMusic(AudioType.mainTheme, 'assets/music/main_theme.mp3');
    await _preloadMusic(AudioType.menuTheme, 'assets/music/menu_theme.mp3');
    await _preloadMusic(AudioType.learningTheme, 'assets/music/learning_theme.mp3');
  }
  
  Future<void> _preloadSoundEffect(AudioType type, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      await player.setVolume(_soundVolume);
      _soundEffectPlayers[type] = player;
    } catch (e) {
      debugPrint('Error preloading sound effect: $e');
    }
  }
  
  Future<void> _preloadMusic(AudioType type, String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      await player.setVolume(_musicVolume);
      await player.setLoopMode(LoopMode.all);
      _musicPlayers[type] = player;
    } catch (e) {
      debugPrint('Error preloading music: $e');
    }
  }
  
  // Play a sound effect
  Future<void> playSoundEffect(AudioType type) async {
    if (!_soundEnabled) return;
    
    final player = _soundEffectPlayers[type];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
      } catch (e) {
        debugPrint('Error playing sound effect: $e');
      }
    }
  }
  
  // Play background music
  Future<void> playMusic(AudioType type) async {
    if (!_musicEnabled) return;
    
    // Stop any currently playing music
    await stopAllMusic();
    
    final player = _musicPlayers[type];
    if (player != null) {
      try {
        await player.seek(Duration.zero);
        await player.play();
      } catch (e) {
        debugPrint('Error playing music: $e');
      }
    }
  }
  
  // Stop all music
  Future<void> stopAllMusic() async {
    for (final player in _musicPlayers.values) {
      await player.stop();
    }
  }
  
  // Toggle sound effects
  Future<void> toggleSound(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }
  
  // Toggle background music
  Future<void> toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
    
    if (!enabled) {
      await stopAllMusic();
    }
  }
  
  // Set sound volume
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', volume);
    
    for (final player in _soundEffectPlayers.values) {
      await player.setVolume(volume);
    }
  }
  
  // Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', volume);
    
    for (final player in _musicPlayers.values) {
      await player.setVolume(volume);
    }
  }
  
  // Dispose all players
  Future<void> dispose() async {
    for (final player in _soundEffectPlayers.values) {
      await player.dispose();
    }
    for (final player in _musicPlayers.values) {
      await player.dispose();
    }
  }
}
