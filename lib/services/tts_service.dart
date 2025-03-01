import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _ttsEnabled = true;
  double _ttsVolume = 1.0;
  double _ttsPitch = 1.0;
  double _ttsRate = 0.5;  // Slightly slower for better comprehension
  String _ttsLanguage = 'en-US';

  bool get ttsEnabled => _ttsEnabled;
  double get ttsVolume => _ttsVolume;
  double get ttsPitch => _ttsPitch;
  double get ttsRate => _ttsRate;
  String get ttsLanguage => _ttsLanguage;

  // Initialize the TTS service
  Future<void> initialize() async {
    _flutterTts = FlutterTts();
    
    // Load settings
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _ttsVolume = prefs.getDouble('tts_volume') ?? 1.0;
    _ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
    _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
    _ttsLanguage = prefs.getString('tts_language') ?? 'en-US';
    
    // Configure TTS
    await _flutterTts.setVolume(_ttsVolume);
    await _flutterTts.setPitch(_ttsPitch);
    await _flutterTts.setSpeechRate(_ttsRate);
    await _flutterTts.setLanguage(_ttsLanguage);
    
    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS Completed');
    });
    
    // Set error handler
    _flutterTts.setErrorHandler((error) {
      debugPrint('TTS Error: $error');
    });
  }
  
  // Speak text
  Future<void> speak(String text) async {
    if (!_ttsEnabled) return;
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }
  
  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
  
  // Toggle TTS
  Future<void> toggleTTS(bool enabled) async {
    _ttsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
    
    if (!enabled) {
      await stop();
    }
  }
  
  // Set TTS volume
  Future<void> setVolume(double volume) async {
    _ttsVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', volume);
    await _flutterTts.setVolume(volume);
  }
  
  // Set TTS pitch
  Future<void> setPitch(double pitch) async {
    _ttsPitch = pitch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', pitch);
    await _flutterTts.setPitch(pitch);
  }
  
  // Set TTS rate
  Future<void> setRate(double rate) async {
    _ttsRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', rate);
    await _flutterTts.setSpeechRate(rate);
  }
  
  // Set TTS language
  Future<void> setLanguage(String language) async {
    _ttsLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);
    await _flutterTts.setLanguage(language);
  }
  
  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return ['en-US'];
    }
  }
  
  // Dispose
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
