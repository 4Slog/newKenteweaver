import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_block_model.dart' hide EmotionalTone;
import '../models/emotional_tone.dart';

/// Service for text-to-speech functionality with enhanced character voice support
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
  
  /// Current voice name (if supported by platform)
  String? _currentVoice;
  
  /// Pronunciation guide for special words
  Map<String, String> _pronunciationGuide = {};
  
  /// Whether TTS is currently speaking
  bool _isSpeaking = false;
  
  /// Completion controller for async waiting
  final _completionController = StreamController<bool>.broadcast();
  
  /// Stream of TTS completion events
  Stream<bool> get onComplete => _completionController.stream;

  /// Whether TTS is enabled
  bool get ttsEnabled => _ttsEnabled;
  
  /// Current TTS volume
  double get ttsVolume => _ttsVolume;
  
  /// Current TTS pitch
  double get ttsPitch => _ttsPitch;
  
  /// Current TTS rate
  double get ttsRate => _ttsRate;
  
  /// Current TTS language
  String get ttsLanguage => _ttsLanguage;
  
  /// Whether TTS is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Initialize the TTS service
  Future<void> initialize() async {
    _flutterTts = FlutterTts();
    
    // Load settings
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _ttsVolume = prefs.getDouble('tts_volume') ?? 1.0;
    _ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
    _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
    _ttsLanguage = prefs.getString('tts_language') ?? 'en-US';
    _currentVoice = prefs.getString('tts_voice');
    
    // Initialize pronunciation guide
    _initializePronunciationGuide();
    
    // Configure TTS
    await _flutterTts.setVolume(_ttsVolume);
    await _flutterTts.setPitch(_ttsPitch);
    await _flutterTts.setSpeechRate(_ttsRate);
    await _flutterTts.setLanguage(_ttsLanguage);
    
    // Set voice if available
    if (_currentVoice != null) {
      final voiceMap = <String, String>{
        "name": _currentVoice!,
        "locale": _ttsLanguage
      };
      await _flutterTts.setVoice(voiceMap);
    }
    
    // Set completion handler
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS Completed');
      _isSpeaking = false;
      _completionController.add(true);
    });
    
    // Set start handler
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });
    
    // Set error handler
    _flutterTts.setErrorHandler((error) {
      debugPrint('TTS Error: $error');
      _isSpeaking = false;
      _completionController.add(false);
    });
  }
  
  /// Initialize pronunciation guide for special words
  void _initializePronunciationGuide() {
    _pronunciationGuide = {
      'Kente': 'KEN-tay',
      'Kwaku': 'KWAH-koo',
      'Ananse': 'ah-NAN-say',
      'Nana': 'NAH-nah',
      'Yaw': 'YAW',
      'Efua': 'eh-FOO-ah',
      'Ama': 'AH-mah',
      'Akan': 'ah-KAN',
      'Ashanti': 'ah-SHAN-tee',
      'Adinkra': 'ah-DINK-rah',
      'Babadua': 'bah-bah-DOO-ah',
      'Nkyinkyim': 'n-CHIN-chim',
      'Dame-Dame': 'DAH-may DAH-may',
    };
  }
  
  /// Add pronunciation guide entries
  void addPronunciationGuide(Map<String, String> guide) {
    _pronunciationGuide.addAll(guide);
  }
  
  /// Apply pronunciation guide to text
  String _applyPronunciationGuide(String text) {
    String processedText = text;
    
    _pronunciationGuide.forEach((word, pronunciation) {
      // Only replace whole words, not parts of words
      final regex = RegExp('\\b$word\\b', caseSensitive: false);
      if (regex.hasMatch(processedText)) {
        processedText = processedText.replaceAll(regex, '<phoneme alphabet="ipa" ph="$pronunciation">$word</phoneme>');
      }
    });
    
    return processedText;
  }
  
  /// Speak text
  Future<void> speak(String text) async {
    if (!_ttsEnabled) return;
    
    try {
      // Apply pronunciation guide
      final processedText = _applyPronunciationGuide(text);
      
      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }
      
      // Speak the text
      await _flutterTts.speak(processedText);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _isSpeaking = false;
    }
  }
  
  /// Speak text and wait for completion
  Future<bool> speakAndWait(String text) async {
    if (!_ttsEnabled) return true;
    
    final completer = Completer<bool>();
    
    // Set up listener for completion
    final subscription = onComplete.listen((success) {
      if (!completer.isCompleted) {
        completer.complete(success);
      }
    });
    
    // Speak the text
    await speak(text);
    
    // Wait for completion
    final result = await completer.future;
    
    // Clean up
    subscription.cancel();
    
    return result;
  }
  
  /// Speak a content block with appropriate voice attributes
  Future<bool> speakContentBlock(ContentBlock block) async {
    if (!_ttsEnabled) return true;
    
    try {
      // Apply voice settings based on content type and speaker
      if (block.speaker != null) {
        // Use speaker's voice settings
        await setPitch(block.speaker!.voiceSettings.pitch);
        await setRate(block.speaker!.voiceSettings.rate);
        await setVolume(block.speaker!.voiceSettings.volume);
        
        if (block.speaker!.voiceSettings.languageCode != null) {
          await setLanguage(block.speaker!.voiceSettings.languageCode!);
        }
      } else {
        // Use block's TTS settings
        await setPitch(block.ttsSettings.pitch);
        await setRate(block.ttsSettings.rate);
        await setVolume(block.ttsSettings.volume);
        
        if (block.ttsSettings.languageCode != null) {
          await setLanguage(block.ttsSettings.languageCode!);
        }
      }
      
      // Speak the text and wait for completion
      final success = await speakAndWait(block.text);
      
      // Pause after speaking if specified
      if (block.ttsSettings.pauseAfter > 0) {
        await Future.delayed(Duration(milliseconds: block.ttsSettings.pauseAfter));
      }
      
      return success;
    } catch (e) {
      debugPrint('Error speaking content block: $e');
      return false;
    }
  }
  
  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
  
  /// Toggle TTS
  Future<void> toggleTTS(bool enabled) async {
    _ttsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
    
    if (!enabled) {
      await stop();
    }
  }
  
  /// Set TTS volume
  Future<void> setVolume(double volume) async {
    _ttsVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', volume);
    await _flutterTts.setVolume(volume);
  }
  
  /// Set TTS pitch
  Future<void> setPitch(double pitch) async {
    _ttsPitch = pitch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', pitch);
    await _flutterTts.setPitch(pitch);
  }
  
  /// Set TTS rate
  Future<void> setRate(double rate) async {
    _ttsRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', rate);
    await _flutterTts.setSpeechRate(rate);
  }
  
  /// Set TTS language
  Future<void> setLanguage(String language) async {
    _ttsLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', language);
    await _flutterTts.setLanguage(language);
  }
  
  /// Set TTS voice
  Future<void> setVoice(String voice) async {
    _currentVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice', voice);
    
    final voiceMap = <String, String>{
      "name": voice,
      "locale": _ttsLanguage
    };
    await _flutterTts.setVoice(voiceMap);
  }
  
  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return ['en-US'];
    }
  }
  
  /// Get available voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      final typedVoices = <Map<String, String>>[];
      
      for (final voice in voices) {
        if (voice is Map) {
          final typedVoice = <String, String>{};
          voice.forEach((key, value) {
            if (key is String && value is String) {
              typedVoice[key] = value;
            } else if (key is String) {
              typedVoice[key] = value.toString();
            }
          });
          typedVoices.add(typedVoice);
        }
      }
      
      return typedVoices;
    } catch (e) {
      debugPrint('Error getting available voices: $e');
      return [];
    }
  }
  
  /// Speak with emotional tone
  Future<void> speakWithEmotion(String text, EmotionalTone tone) async {
    if (!_ttsEnabled) return;
    
    // Save current settings
    final savedPitch = _ttsPitch;
    final savedRate = _ttsRate;
    
    try {
      // Apply emotional tone settings
      switch (tone) {
        case EmotionalTone.happy:
          await setPitch(1.2);
          await setRate(1.1);
          break;
        case EmotionalTone.excited:
          await setPitch(1.3);
          await setRate(1.2);
          break;
        case EmotionalTone.concerned:
          await setPitch(0.9);
          await setRate(0.9);
          break;
        case EmotionalTone.thoughtful:
          await setPitch(1.0);
          await setRate(0.9);
          break;
        case EmotionalTone.curious:
          await setPitch(1.1);
          await setRate(1.0);
          break;
        case EmotionalTone.wise:
          await setPitch(0.8);
          await setRate(0.8);
          break;
        case EmotionalTone.confused:
          await setPitch(1.1);
          await setRate(0.9);
          break;
        case EmotionalTone.surprised:
          await setPitch(1.3);
          await setRate(1.1);
          break;
        case EmotionalTone.proud:
          await setPitch(1.2);
          await setRate(1.0);
          break;
        case EmotionalTone.neutral:
        default:
          await setPitch(1.0);
          await setRate(1.0);
          break;
      }
      
      // Speak the text
      await speak(text);
      
    } finally {
      // Restore original settings
      await setPitch(savedPitch);
      await setRate(savedRate);
    }
  }
  
  /// Dispose
  Future<void> dispose() async {
    await stop();
    await _completionController.close();
  }
}
