import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_block_model.dart' hide EmotionalTone;
import '../models/emotional_tone.dart';

/// Voice settings for a character
class CharacterVoiceSettings {
  /// Character identifier
  final String characterId;
  
  /// Display name
  final String displayName;
  
  /// Voice pitch (0.5-2.0)
  final double pitch;
  
  /// Voice rate (0.25-2.0)
  final double rate;
  
  /// Voice volume (0.0-1.0)
  final double volume;
  
  /// Language code (e.g., 'en-US')
  final String? languageCode;
  
  /// Voice name (if platform supports specific voices)
  final String? voiceName;
  
  /// Character description
  final String description;
  
  /// Character age
  final int? age;
  
  /// Character gender
  final String? gender;
  
  /// Character personality traits
  final List<String> personalityTraits;
  
  /// Default emotional tone
  final EmotionalTone defaultTone;

  const CharacterVoiceSettings({
    required this.characterId,
    required this.displayName,
    this.pitch = 1.0,
    this.rate = 0.5,
    this.volume = 1.0,
    this.languageCode,
    this.voiceName,
    this.description = '',
    this.age,
    this.gender,
    this.personalityTraits = const [],
    this.defaultTone = EmotionalTone.neutral,
  });
}

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
  
  /// Character voice settings
  final Map<String, CharacterVoiceSettings> _characterVoices = {};
  
  /// Current character
  String? _currentCharacter;
  
  /// Current emotional tone
  EmotionalTone _currentTone = EmotionalTone.neutral;
  
  /// Initialize the TTS service
  Future<void> initialize() async {
    _flutterTts = FlutterTts();
    
    // Set default settings
    await _flutterTts.setVolume(_ttsVolume);
    await _flutterTts.setPitch(_ttsPitch);
    await _flutterTts.setRate(_ttsRate);
    await _flutterTts.setLanguage(_ttsLanguage);
    
    // Set completion callback
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _completionController.add(true);
    });
    
    // Set error callback
    _flutterTts.setErrorHandler((error) {
      _isSpeaking = false;
      debugPrint('TTS Error: $error');
    });
    
    // Initialize character voices
    await _initializeCharacterVoices();
    
    // Initialize pronunciation guide
    _initializePronunciationGuide();
    
    // Load settings from shared preferences
    await _loadSettings();
  }
  
  /// Initialize character voices
  Future<void> _initializeCharacterVoices() async {
    // Add Kweku Ananse voice
    _characterVoices['kweku'] = CharacterVoiceSettings(
      characterId: 'kweku',
      displayName: 'Kweku Ananse',
      pitch: 1.2,  // Slightly higher pitch for younger character
      rate: 0.5,   // Moderate speaking rate
      volume: 1.0,
      languageCode: 'en-US',
      description: 'Tech-savvy modern Ananse descendant',
      age: 10,
      gender: 'male',
      personalityTraits: ['enthusiastic', 'helpful', 'witty'],
      defaultTone: EmotionalTone.enthusiastic,
    );
    
    // Add Narrator voice
    _characterVoices['narrator'] = CharacterVoiceSettings(
      characterId: 'narrator',
      displayName: 'Narrator',
      pitch: 1.0,  // Standard pitch
      rate: 0.45,  // Slightly slower for clarity
      volume: 1.0,
      languageCode: 'en-US',
      description: 'Storyteller voice',
      personalityTraits: ['calm', 'clear', 'engaging'],
      defaultTone: EmotionalTone.neutral,
    );
    
    // Add Elder voice
    _characterVoices['elder'] = CharacterVoiceSettings(
      characterId: 'elder',
      displayName: 'Elder',
      pitch: 0.8,  // Lower pitch for older character
      rate: 0.4,   // Slower speaking rate
      volume: 1.0,
      languageCode: 'en-US',
      description: 'Wise elder who shares cultural knowledge',
      age: 70,
      gender: 'male',
      personalityTraits: ['wise', 'patient', 'knowledgeable'],
      defaultTone: EmotionalTone.thoughtful,
    );
  }
  
  /// Initialize pronunciation guide for cultural terms
  void _initializePronunciationGuide() {
    _pronunciationGuide = {
      'Kente': 'Ken-tay',
      'Ananse': 'Ah-nahn-say',
      'Kweku': 'Kway-koo',
      'Adinkra': 'Ah-dink-rah',
      'Asante': 'Ah-sahn-tay',
      'Ewe': 'Eh-way',
      'Akan': 'Ah-kahn',
    };
  }
  
  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _ttsVolume = prefs.getDouble('tts_volume') ?? 1.0;
      _ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
      _ttsRate = prefs.getDouble('tts_rate') ?? 0.5;
      _ttsLanguage = prefs.getString('tts_language') ?? 'en-US';
      _currentVoice = prefs.getString('tts_voice');
      
      // Apply settings
      if (_ttsEnabled) {
        await _flutterTts.setVolume(_ttsVolume);
        await _flutterTts.setPitch(_ttsPitch);
        await _flutterTts.setRate(_ttsRate);
        await _flutterTts.setLanguage(_ttsLanguage);
        if (_currentVoice != null) {
          await _flutterTts.setVoice({"name": _currentVoice});
        }
      }
    } catch (e) {
      debugPrint('Error loading TTS settings: $e');
    }
  }
  
  /// Save settings to shared preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tts_enabled', _ttsEnabled);
      await prefs.setDouble('tts_volume', _ttsVolume);
      await prefs.setDouble('tts_pitch', _ttsPitch);
      await prefs.setDouble('tts_rate', _ttsRate);
      await prefs.setString('tts_language', _ttsLanguage);
      if (_currentVoice != null) {
        await prefs.setString('tts_voice', _currentVoice!);
      }
    } catch (e) {
      debugPrint('Error saving TTS settings: $e');
    }
  }
  
  /// Speak text with the current settings
  Future<void> speak(String text) async {
    if (!_ttsEnabled) return;
    
    // Apply pronunciation guide
    final processedText = _applyPronunciationGuide(text);
    
    _isSpeaking = true;
    await _flutterTts.speak(processedText);
  }
  
  /// Speak as a specific character
  Future<void> speakAsCharacter({
    required String text,
    required String characterId,
    EmotionalTone? tone,
  }) async {
    if (!_ttsEnabled) return;
    
    // Get character settings
    final character = _characterVoices[characterId] ?? _characterVoices['narrator']!;
    
    // Set voice parameters
    await _flutterTts.setPitch(character.pitch);
    await _flutterTts.setRate(character.rate);
    await _flutterTts.setVolume(character.volume);
    
    // Apply emotional tone adjustments
    final emotionalTone = tone ?? character.defaultTone;
    await _applyEmotionalTone(emotionalTone);
    
    // Apply pronunciation guide
    final processedText = _applyPronunciationGuide(text);
    
    // Speak the text
    _currentCharacter = characterId;
    _currentTone = emotionalTone;
    _isSpeaking = true;
    await _flutterTts.speak(processedText);
  }
  
  /// Apply emotional tone adjustments
  Future<void> _applyEmotionalTone(EmotionalTone tone) async {
    double pitchMultiplier = 1.0;
    double rateMultiplier = 1.0;
    
    switch (tone) {
      case EmotionalTone.excited:
        pitchMultiplier = 1.2;
        rateMultiplier = 1.3;
        break;
      case EmotionalTone.sad:
        pitchMultiplier = 0.9;
        rateMultiplier = 0.8;
        break;
      case EmotionalTone.angry:
        pitchMultiplier = 1.1;
        rateMultiplier = 1.2;
        break;
      case EmotionalTone.scared:
        pitchMultiplier = 1.15;
        rateMultiplier = 1.4;
        break;
      case EmotionalTone.thoughtful:
        pitchMultiplier = 0.95;
        rateMultiplier = 0.85;
        break;
      case EmotionalTone.enthusiastic:
        pitchMultiplier = 1.15;
        rateMultiplier = 1.1;
        break;
      case EmotionalTone.neutral:
      default:
        pitchMultiplier = 1.0;
        rateMultiplier = 1.0;
        break;
    }
    
    // Get the base settings for the current character
    final character = _currentCharacter != null ? 
        _characterVoices[_currentCharacter] : null;
    
    final basePitch = character?.pitch ?? _ttsPitch;
    final baseRate = character?.rate ?? _ttsRate;
    
    // Apply the multipliers
    await _flutterTts.setPitch(basePitch * pitchMultiplier);
    await _flutterTts.setRate(baseRate * rateMultiplier);
  }
  
  /// Apply pronunciation guide for cultural terms
  String _applyPronunciationGuide(String text) {
    String processedText = text;
    
    _pronunciationGuide.forEach((term, pronunciation) {
      final regex = RegExp(r'\b' + term + r'\b', caseSensitive: false);
      processedText = processedText.replaceAll(regex, pronunciation);
    });
    
    return processedText;
  }
  
  /// Stop speaking
  Future<void> stop() async {
    if (_isSpeaking) {
      _isSpeaking = false;
      await _flutterTts.stop();
    }
  }
  
  /// Pause speaking
  Future<void> pause() async {
    if (_isSpeaking) {
      await _flutterTts.pause();
    }
  }
  
  /// Set TTS enabled state
  Future<void> setEnabled(bool enabled) async {
    _ttsEnabled = enabled;
    await _saveSettings();
    
    if (!enabled && _isSpeaking) {
      await stop();
    }
  }
  
  /// Set TTS volume
  Future<void> setVolume(double volume) async {
    _ttsVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_ttsVolume);
    await _saveSettings();
  }
  
  /// Set TTS pitch
  Future<void> setPitch(double pitch) async {
    _ttsPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_ttsPitch);
    await _saveSettings();
  }
  
  /// Set TTS rate
  Future<void> setRate(double rate) async {
    _ttsRate = rate.clamp(0.25, 2.0);
    await _flutterTts.setRate(_ttsRate);
    await _saveSettings();
  }
  
  /// Set TTS language
  Future<void> setLanguage(String language) async {
    _ttsLanguage = language;
    await _flutterTts.setLanguage(_ttsLanguage);
    await _saveSettings();
  }
  
  /// Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      debugPrint('Error getting available voices: $e');
      return [];
    }
  }
  
  /// Set voice by name
  Future<void> setVoice(String voiceName) async {
    try {
      await _flutterTts.setVoice({"name": voiceName});
      _currentVoice = voiceName;
      await _saveSettings();
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }
  
  /// Get available character voices
  Map<String, CharacterVoiceSettings> getAvailableCharacterVoices() {
    return Map.unmodifiable(_characterVoices);
  }
  
  /// Add a custom character voice
  void addCharacterVoice(CharacterVoiceSettings settings) {
    _characterVoices[settings.characterId] = settings;
  }
  
  /// Remove a character voice
  void removeCharacterVoice(String characterId) {
    if (characterId != 'narrator' && characterId != 'kweku' && characterId != 'elder') {
      _characterVoices.remove(characterId);
    }
  }
  
  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
    _completionController.close();
  }
}
