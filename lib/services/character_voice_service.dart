import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Create a copy with some properties changed
  CharacterVoiceSettings copyWith({
    String? characterId,
    String? displayName,
    double? pitch,
    double? rate,
    double? volume,
    String? languageCode,
    String? voiceName,
    String? description,
    int? age,
    String? gender,
    List<String>? personalityTraits,
    EmotionalTone? defaultTone,
  }) {
    return CharacterVoiceSettings(
      characterId: characterId ?? this.characterId,
      displayName: displayName ?? this.displayName,
      pitch: pitch ?? this.pitch,
      rate: rate ?? this.rate,
      volume: volume ?? this.volume,
      languageCode: languageCode ?? this.languageCode,
      voiceName: voiceName ?? this.voiceName,
      description: description ?? this.description,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      defaultTone: defaultTone ?? this.defaultTone,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'displayName': displayName,
      'pitch': pitch,
      'rate': rate,
      'volume': volume,
      'languageCode': languageCode,
      'voiceName': voiceName,
      'description': description,
      'age': age,
      'gender': gender,
      'personalityTraits': personalityTraits,
      'defaultTone': defaultTone.toString().split('.').last,
    };
  }

  /// Create from JSON
  factory CharacterVoiceSettings.fromJson(Map<String, dynamic> json) {
    final toneStr = json['defaultTone'] as String? ?? 'neutral';
    EmotionalTone tone;
    
    try {
      tone = EmotionalTone.values.firstWhere(
        (t) => t.toString().split('.').last == toneStr,
        orElse: () => EmotionalTone.neutral,
      );
    } catch (_) {
      tone = EmotionalTone.neutral;
    }
    
    return CharacterVoiceSettings(
      characterId: json['characterId'] as String,
      displayName: json['displayName'] as String? ?? json['characterId'] as String,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      languageCode: json['languageCode'] as String?,
      voiceName: json['voiceName'] as String?,
      description: json['description'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      personalityTraits: json['personalityTraits'] != null
          ? List<String>.from(json['personalityTraits'] as List)
          : const [],
      defaultTone: tone,
    );
  }
}

/// Service for managing character voices
class CharacterVoiceService extends ChangeNotifier {
  static final CharacterVoiceService _instance = CharacterVoiceService._internal();
  factory CharacterVoiceService() => _instance;
  CharacterVoiceService._internal();

  /// Map of character ID to voice settings
  final Map<String, CharacterVoiceSettings> _characterVoices = {};
  
  /// Whether the service is initialized
  bool _isInitialized = false;
  
  /// Get all character voices
  Map<String, CharacterVoiceSettings> get characterVoices => 
      Map.unmodifiable(_characterVoices);
  
  /// Get a specific character's voice settings
  CharacterVoiceSettings? getCharacterVoice(String characterId) {
    return _characterVoices[characterId.toLowerCase()];
  }
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load saved character voices
    await _loadCharacterVoices();
    
    // If no voices are loaded, initialize with defaults
    if (_characterVoices.isEmpty) {
      _initializeDefaultVoices();
    }
    
    _isInitialized = true;
  }
  
  /// Load character voices from shared preferences
  Future<void> _loadCharacterVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voicesJson = prefs.getString('character_voices');
      
      if (voicesJson != null) {
        final Map<String, dynamic> voicesMap = 
            Map<String, dynamic>.from(jsonDecode(voicesJson));
        
        voicesMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final voice = CharacterVoiceSettings.fromJson(value);
            _characterVoices[key.toLowerCase()] = voice;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading character voices: $e');
    }
  }
  
  /// Initialize default character voices
  void _initializeDefaultVoices() {
    final defaultVoices = [
      const CharacterVoiceSettings(
        characterId: 'narrator',
        displayName: 'Narrator',
        pitch: 1.0,
        rate: 0.5,
        volume: 1.0,
        description: 'The main storyteller voice',
        personalityTraits: ['clear', 'engaging', 'neutral'],
        defaultTone: EmotionalTone.neutral,
      ),
      const CharacterVoiceSettings(
        characterId: 'kwaku',
        displayName: 'Kwaku',
        pitch: 1.2,
        rate: 0.5,
        volume: 1.0,
        description: 'A 9-year-old Ghanaian boy, curious and enthusiastic',
        age: 9,
        gender: 'male',
        personalityTraits: ['curious', 'enthusiastic', 'clever'],
        defaultTone: EmotionalTone.curious,
      ),
      const CharacterVoiceSettings(
        characterId: 'nana_yaw',
        displayName: 'Nana Yaw',
        pitch: 0.8,
        rate: 0.4,
        volume: 1.0,
        description: 'Kwaku\'s grandfather, a wise elder and master weaver',
        age: 75,
        gender: 'male',
        personalityTraits: ['wise', 'patient', 'traditional'],
        defaultTone: EmotionalTone.wise,
      ),
      const CharacterVoiceSettings(
        characterId: 'auntie_efua',
        displayName: 'Auntie Efua',
        pitch: 1.1,
        rate: 0.45,
        volume: 1.0,
        description: 'A computer science teacher at Kwaku\'s school',
        age: 35,
        gender: 'female',
        personalityTraits: ['knowledgeable', 'encouraging', 'structured'],
        defaultTone: EmotionalTone.thoughtful,
      ),
      const CharacterVoiceSettings(
        characterId: 'ama',
        displayName: 'Ama',
        pitch: 1.3,
        rate: 0.5,
        volume: 1.0,
        description: 'Kwaku\'s friend who shares his interest in technology',
        age: 9,
        gender: 'female',
        personalityTraits: ['methodical', 'supportive', 'curious'],
        defaultTone: EmotionalTone.happy,
      ),
    ];
    
    for (final voice in defaultVoices) {
      _characterVoices[voice.characterId.toLowerCase()] = voice;
    }
  }
  
  /// Add or update a character voice
  Future<void> setCharacterVoice(CharacterVoiceSettings voice) async {
    _characterVoices[voice.characterId.toLowerCase()] = voice;
    await _saveCharacterVoices();
    notifyListeners();
  }
  
  /// Remove a character voice
  Future<void> removeCharacterVoice(String characterId) async {
    _characterVoices.remove(characterId.toLowerCase());
    await _saveCharacterVoices();
    notifyListeners();
  }
  
  /// Save character voices to shared preferences
  Future<void> _saveCharacterVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final Map<String, dynamic> voicesMap = {};
      _characterVoices.forEach((key, value) {
        voicesMap[key] = value.toJson();
      });
      
      await prefs.setString('character_voices', jsonEncode(voicesMap));
    } catch (e) {
      debugPrint('Error saving character voices: $e');
    }
  }
  
  /// Get voice settings adjusted for emotional tone
  CharacterVoiceSettings getVoiceWithEmotion(
    String characterId,
    EmotionalTone tone,
  ) {
    final baseVoice = getCharacterVoice(characterId);
    if (baseVoice == null) {
      return const CharacterVoiceSettings(
        characterId: 'default',
        displayName: 'Default',
      );
    }
    
    // Apply emotional adjustments
    double pitchAdjustment = 0.0;
    double rateAdjustment = 0.0;
    
    switch (tone) {
      case EmotionalTone.happy:
        pitchAdjustment = 0.1;
        rateAdjustment = 0.1;
        break;
      case EmotionalTone.excited:
        pitchAdjustment = 0.2;
        rateAdjustment = 0.2;
        break;
      case EmotionalTone.concerned:
        pitchAdjustment = -0.1;
        rateAdjustment = -0.1;
        break;
      case EmotionalTone.thoughtful:
        pitchAdjustment = 0.0;
        rateAdjustment = -0.1;
        break;
      case EmotionalTone.curious:
        pitchAdjustment = 0.1;
        rateAdjustment = 0.0;
        break;
      case EmotionalTone.wise:
        pitchAdjustment = -0.2;
        rateAdjustment = -0.1;
        break;
      case EmotionalTone.confused:
        pitchAdjustment = 0.1;
        rateAdjustment = -0.1;
        break;
      case EmotionalTone.surprised:
        pitchAdjustment = 0.2;
        rateAdjustment = 0.1;
        break;
      case EmotionalTone.proud:
        pitchAdjustment = 0.1;
        rateAdjustment = 0.0;
        break;
      case EmotionalTone.neutral:
      default:
        // No adjustments for neutral tone
        break;
    }
    
    return baseVoice.copyWith(
      pitch: (baseVoice.pitch + pitchAdjustment).clamp(0.5, 2.0),
      rate: (baseVoice.rate + rateAdjustment).clamp(0.25, 2.0),
    );
  }
  
  /// Reset all character voices to defaults
  Future<void> resetToDefaults() async {
    _characterVoices.clear();
    _initializeDefaultVoices();
    await _saveCharacterVoices();
    notifyListeners();
  }
}
