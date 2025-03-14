import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  bool _isMuted = false;
  double _volume = 1.0;
  String? _currentBackgroundMusic;

  bool get isMuted => _isMuted;
  double get volume => _volume;
  String? get currentBackgroundMusic => _currentBackgroundMusic;

  Future<void> playBackgroundMusic(String assetPath) async {
    if (_currentBackgroundMusic == assetPath && _backgroundMusicPlayer.state == PlayerState.playing) {
      return;
    }

    try {
      await _backgroundMusicPlayer.stop();
      await _backgroundMusicPlayer.setSource(AssetSource(assetPath));
      await _backgroundMusicPlayer.setVolume(_isMuted ? 0 : _volume);
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.resume();
      _currentBackgroundMusic = assetPath;
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.stop();
      _currentBackgroundMusic = null;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  Future<void> playSoundEffect(String assetPath) async {
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.setSource(AssetSource(assetPath));
      await _effectsPlayer.setVolume(_isMuted ? 0 : _volume);
      await _effectsPlayer.resume();
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _backgroundMusicPlayer.setVolume(_volume);
      await _effectsPlayer.setVolume(_volume);
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    final effectiveVolume = _isMuted ? 0.0 : _volume;
    await _backgroundMusicPlayer.setVolume(effectiveVolume);
    await _effectsPlayer.setVolume(effectiveVolume);
  }

  Future<void> dispose() async {
    await _backgroundMusicPlayer.dispose();
    await _effectsPlayer.dispose();
  }
} 