import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Enum representing different types of content blocks in a story
enum ContentBlockType {
  /// Regular narrative text
  narration,
  
  /// Character dialogue with attribution
  dialogue,
  
  /// Environmental or scene description
  description,
  
  /// Instructions for the user
  instruction,
  
  /// Cultural context information
  culturalContext,
  
  /// Introduction of a challenge
  challengeIntro,
  
  /// User choice point
  choicePoint,
  
  /// UI feedback or prompts
  feedback,
  
  /// Educational content
  educational,
}

/// Enum for emotional tones to guide text-to-speech
enum EmotionalTone {
  neutral,
  happy,
  excited,
  concerned,
  thoughtful,
  curious,
  wise,
  confused,
  surprised,
  proud,
}

/// Class for text-to-speech settings for content blocks
class TTSSettings {
  /// Rate of speech (0.0 to 2.0, where 1.0 is normal speed)
  final double rate;
  
  /// Pitch of voice (0.0 to 2.0, where 1.0 is normal pitch)
  final double pitch;
  
  /// Volume level (0.0 to 1.0)
  final double volume;
  
  /// Emotional tone for expressive TTS
  final EmotionalTone tone;
  
  /// Language code (e.g., "en-US", "tw-GH")
  final String? languageCode;
  
  /// Voice name (if supported by TTS engine)
  final String? voiceName;
  
  /// Any special pronunciation guidance
  final Map<String, String>? pronunciationGuide;
  
  /// Duration of pause after this block (in milliseconds)
  final int pauseAfter;

  const TTSSettings({
    this.rate = 1.0,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.tone = EmotionalTone.neutral,
    this.languageCode,
    this.voiceName,
    this.pronunciationGuide,
    this.pauseAfter = 500,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'tone': tone.toString().split('.').last,
      'languageCode': languageCode,
      'voiceName': voiceName,
      'pronunciationGuide': pronunciationGuide,
      'pauseAfter': pauseAfter,
    };
  }

  /// Create from JSON
  factory TTSSettings.fromJson(Map<String, dynamic> json) {
    return TTSSettings(
      rate: (json['rate'] ?? 1.0).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 1.0).toDouble(),
      tone: _toneFromString(json['tone'] ?? 'neutral'),
      languageCode: json['languageCode'],
      voiceName: json['voiceName'],
      pronunciationGuide: json['pronunciationGuide'] != null
          ? Map<String, String>.from(json['pronunciationGuide'])
          : null,
      pauseAfter: json['pauseAfter'] ?? 500,
    );
  }

  /// Parse tone from string
  static EmotionalTone _toneFromString(String toneString) {
    try {
      return EmotionalTone.values.firstWhere(
        (tone) => tone.toString().split('.').last == toneString,
      );
    } catch (_) {
      return EmotionalTone.neutral;
    }
  }

  /// Create a copy with some properties changed
  TTSSettings copyWith({
    double? rate,
    double? pitch,
    double? volume,
    EmotionalTone? tone,
    String? languageCode,
    String? voiceName,
    Map<String, String>? pronunciationGuide,
    int? pauseAfter,
  }) {
    return TTSSettings(
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      tone: tone ?? this.tone,
      languageCode: languageCode ?? this.languageCode,
      voiceName: voiceName ?? this.voiceName,
      pronunciationGuide: pronunciationGuide ?? this.pronunciationGuide,
      pauseAfter: pauseAfter ?? this.pauseAfter,
    );
  }
}

/// Character information for dialogue attribution
class Character {
  /// Unique identifier for the character
  final String id;
  
  /// Character's display name
  final String name;
  
  /// Brief description of the character
  final String? description;
  
  /// TTS settings for this character's voice
  final TTSSettings voiceSettings;
  
  /// Path to character avatar image
  final String? avatarPath;
  
  /// Character role (e.g., "mentor", "friend", "guide")
  final String? role;
  
  /// Age of the character (for voice appropriateness)
  final int? age;
  
  /// Character gender (for TTS voice selection)
  final String? gender;
  
  /// Additional character information
  final Map<String, dynamic>? metadata;

  const Character({
    required this.id,
    required this.name,
    this.description,
    required this.voiceSettings,
    this.avatarPath,
    this.role,
    this.age,
    this.gender,
    this.metadata,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'voiceSettings': voiceSettings.toJson(),
      'avatarPath': avatarPath,
      'role': role,
      'age': age,
      'gender': gender,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      voiceSettings: TTSSettings.fromJson(json['voiceSettings'] ?? {}),
      avatarPath: json['avatarPath'],
      role: json['role'],
      age: json['age'],
      gender: json['gender'],
      metadata: json['metadata'],
    );
  }

  /// Create a copy with some properties changed
  Character copyWith({
    String? name,
    String? description,
    TTSSettings? voiceSettings,
    String? avatarPath,
    String? role,
    int? age,
    String? gender,
    Map<String, dynamic>? metadata,
  }) {
    return Character(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      voiceSettings: voiceSettings ?? this.voiceSettings,
      avatarPath: avatarPath ?? this.avatarPath,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Predefined character: Kwaku
  factory Character.kwaku() {
    return Character(
      id: 'kwaku',
      name: 'Kwaku',
      description: 'A 9-10 year old Ghanaian boy who connects traditional Kente weaving with modern coding',
      voiceSettings: TTSSettings(
        pitch: 1.2,
        rate: 1.1,
        tone: EmotionalTone.curious,
      ),
      avatarPath: 'assets/images/characters/kwaku.png',
      role: 'protagonist',
      age: 10,
      gender: 'male',
    );
  }

  /// Predefined character: Nana Yaw (Grandfather)
  factory Character.nanaYaw() {
    return Character(
      id: 'nana_yaw',
      name: 'Nana Yaw',
      description: 'Kwaku\'s grandfather and a master Kente weaver',
      voiceSettings: TTSSettings(
        pitch: 0.8,
        rate: 0.9,
        tone: EmotionalTone.wise,
      ),
      avatarPath: 'assets/images/characters/nana_yaw.png',
      role: 'mentor',
      age: 75,
      gender: 'male',
    );
  }

  /// Predefined character: Auntie Efua (Teacher)
  factory Character.auntieEfua() {
    return Character(
      id: 'auntie_efua',
      name: 'Auntie Efua',
      description: 'Computer science teacher who guides Kwaku',
      voiceSettings: TTSSettings(
        pitch: 1.1,
        rate: 1.0,
        tone: EmotionalTone.thoughtful,
      ),
      avatarPath: 'assets/images/characters/auntie_efua.png',
      role: 'tech_mentor',
      age: 35,
      gender: 'female',
    );
  }

  /// Predefined character: Ama (Friend)
  factory Character.ama() {
    return Character(
      id: 'ama',
      name: 'Ama',
      description: 'Kwaku\'s friend who shares his interest in technology',
      voiceSettings: TTSSettings(
        pitch: 1.3,
        rate: 1.1,
        tone: EmotionalTone.excited,
      ),
      avatarPath: 'assets/images/characters/ama.png',
      role: 'peer',
      age: 10,
      gender: 'female',
    );
  }

  /// Predefined character: Narrator
  factory Character.narrator() {
    return Character(
      id: 'narrator',
      name: 'Narrator',
      description: 'Storyteller narrator voice',
      voiceSettings: TTSSettings(
        pitch: 1.0,
        rate: 1.0,
        tone: EmotionalTone.neutral,
      ),
      role: 'narrator',
    );
  }
}

/// Main content block class for story content
class ContentBlock {
  /// Unique identifier for the block
  final String id;
  
  /// Type of content in this block
  final ContentBlockType type;
  
  /// The main text content
  final String text;
  
  /// Character speaking (for dialogue type)
  final Character? speaker;
  
  /// Text-to-speech settings
  final TTSSettings ttsSettings;
  
  /// Background image path for this block
  final String? backgroundImagePath;
  
  /// Animation to play with this block
  final String? animationPath;
  
  /// Sound effect to play with this block
  final String? soundEffectPath;
  
  /// Delay before showing this block (in milliseconds)
  final int delay;
  
  /// Duration to display this block (in milliseconds, 0 for manual advance)
  final int displayDuration;
  
  /// Indicates if this block should wait for user interaction
  final bool waitForInteraction;
  
  /// Additional metadata for specialized block types
  final Map<String, dynamic>? metadata;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.text,
    this.speaker,
    this.ttsSettings = const TTSSettings(),
    this.backgroundImagePath,
    this.animationPath,
    this.soundEffectPath,
    this.delay = 0,
    this.displayDuration = 0,
    this.waitForInteraction = false,
    this.metadata,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'text': text,
      'speaker': speaker?.toJson(),
      'ttsSettings': ttsSettings.toJson(),
      'backgroundImagePath': backgroundImagePath,
      'animationPath': animationPath,
      'soundEffectPath': soundEffectPath,
      'delay': delay,
      'displayDuration': displayDuration,
      'waitForInteraction': waitForInteraction,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id'],
      type: _typeFromString(json['type'] ?? 'narration'),
      text: json['text'],
      speaker: json['speaker'] != null ? Character.fromJson(json['speaker']) : null,
      ttsSettings: json['ttsSettings'] != null
          ? TTSSettings.fromJson(json['ttsSettings'])
          : const TTSSettings(),
      backgroundImagePath: json['backgroundImagePath'],
      animationPath: json['animationPath'],
      soundEffectPath: json['soundEffectPath'],
      delay: json['delay'] ?? 0,
      displayDuration: json['displayDuration'] ?? 0,
      waitForInteraction: json['waitForInteraction'] ?? false,
      metadata: json['metadata'],
    );
  }

  /// Parse content block type from string
  static ContentBlockType _typeFromString(String typeString) {
    try {
      return ContentBlockType.values.firstWhere(
        (type) => type.toString().split('.').last == typeString,
      );
    } catch (_) {
      return ContentBlockType.narration;
    }
  }

  /// Create a copy with some properties changed
  ContentBlock copyWith({
    ContentBlockType? type,
    String? text,
    Character? speaker,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int? delay,
    int? displayDuration,
    bool? waitForInteraction,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      ttsSettings: ttsSettings ?? this.ttsSettings,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      animationPath: animationPath ?? this.animationPath,
      soundEffectPath: soundEffectPath ?? this.soundEffectPath,
      delay: delay ?? this.delay,
      displayDuration: displayDuration ?? this.displayDuration,
      waitForInteraction: waitForInteraction ?? this.waitForInteraction,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Factory for creating narration blocks
  factory ContentBlock.narration({
    required String id,
    required String text,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = false,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.narration,
      text: text,
      speaker: Character.narrator(),
      ttsSettings: ttsSettings ?? const TTSSettings(),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }

  /// Factory for creating dialogue blocks
  factory ContentBlock.dialogue({
    required String id,
    required String text,
    required Character speaker,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = true,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.dialogue,
      text: text,
      speaker: speaker,
      ttsSettings: ttsSettings ?? speaker.voiceSettings,
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }

  /// Factory for creating description blocks
  factory ContentBlock.description({
    required String id,
    required String text,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = false,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.description,
      text: text,
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 0.9,
        tone: EmotionalTone.thoughtful,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }

  /// Factory for creating cultural context blocks
  factory ContentBlock.culturalContext({
    required String id,
    required String text,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = true,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.culturalContext,
      text: text,
      speaker: Character.narrator(),
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 0.9,
        tone: EmotionalTone.wise,
        pauseAfter: 800,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }

  /// Factory for creating instruction blocks
  factory ContentBlock.instruction({
    required String id,
    required String text,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = true,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.instruction,
      text: text,
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 1.0,
        tone: EmotionalTone.neutral,
        pauseAfter: 1000,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }

  /// Factory for creating challenge introduction blocks
  factory ContentBlock.challengeIntro({
    required String id,
    required String text,
    Character? speaker,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath = 'assets/audio/challenge_intro.mp3',
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = true,
    String? challengeId,
    Map<String, dynamic>? metadata,
  }) {
    final mergedMetadata = {
      'challengeId': challengeId,
      ...?metadata,
    };
    
    return ContentBlock(
      id: id,
      type: ContentBlockType.challengeIntro,
      text: text,
      speaker: speaker,
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 1.0,
        tone: EmotionalTone.excited,
        pauseAfter: 500,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: mergedMetadata,
    );
  }

  /// Factory for creating choice point blocks
  factory ContentBlock.choicePoint({
    required String id,
    required String text,
    Character? speaker,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 500,
    int displayDuration = 0,
    bool waitForInteraction = true,
    List<Map<String, dynamic>>? choices,
    Map<String, dynamic>? metadata,
  }) {
    final mergedMetadata = {
      'choices': choices,
      ...?metadata,
    };
    
    return ContentBlock(
      id: id,
      type: ContentBlockType.choicePoint,
      text: text,
      speaker: speaker,
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 1.0,
        tone: EmotionalTone.thoughtful,
        pauseAfter: 1000,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: mergedMetadata,
    );
  }

  /// Create content blocks from a script string with simple markup
  static List<ContentBlock> fromScript(String script, {Map<String, Character>? characters}) {
    final blocks = <ContentBlock>[];
    final lines = script.split('\n');
    final charactersMap = characters ?? {
      'Kwaku': Character.kwaku(),
      'Nana': Character.nanaYaw(),
      'Auntie': Character.auntieEfua(),
      'Ama': Character.ama(),
      'Narrator': Character.narrator(),
    };

    int blockCounter = 0;
    String currentSection = '';
    ContentBlockType currentType = ContentBlockType.narration;
    Character? currentSpeaker;
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty lines
      if (line.isEmpty) continue;
      
      // Check for section markers
      if (line.startsWith('# ')) {
        // Process previous section if any
        if (currentSection.isNotEmpty) {
          blocks.add(_createBlockFromSection(
            blockCounter.toString(),
            currentSection.trim(),
            currentType,
            currentSpeaker,
          ));
          blockCounter++;
          currentSection = '';
        }
        
        // Set type to narration for new section
        currentType = ContentBlockType.narration;
        currentSpeaker = charactersMap['Narrator'];
        currentSection = line.substring(2);
        continue;
      }
      
      // Check for dialogue markers
      if (line.contains(':')) {
        // Process previous section if any
        if (currentSection.isNotEmpty) {
          blocks.add(_createBlockFromSection(
            blockCounter.toString(),
            currentSection.trim(),
            currentType,
            currentSpeaker,
          ));
          blockCounter++;
          currentSection = '';
        }
        
        // Parse dialogue
        final parts = line.split(':');
        final speakerName = parts[0].trim();
        final dialogueText = parts.sublist(1).join(':').trim();
        
        currentType = ContentBlockType.dialogue;
        currentSpeaker = charactersMap[speakerName] ?? Character.narrator();
        currentSection = dialogueText;
        continue;
      }
      
      // Check for description markers
      if (line.startsWith('*') && line.endsWith('*')) {
        // Process previous section if any
        if (currentSection.isNotEmpty) {
          blocks.add(_createBlockFromSection(
            blockCounter.toString(),
            currentSection.trim(),
            currentType,
            currentSpeaker,
          ));
          blockCounter++;
          currentSection = '';
        }
        
        // Set type to description
        currentType = ContentBlockType.description;
        currentSpeaker = null;
        currentSection = line.substring(1, line.length - 1).trim();
        continue;
      }
      
      // Check for cultural context markers
      if (line.startsWith('> ') && !line.startsWith('>> ')) {
        // Process previous section if any
        if (currentSection.isNotEmpty) {
          blocks.add(_createBlockFromSection(
            blockCounter.toString(),
            currentSection.trim(),
            currentType,
            currentSpeaker,
          ));
          blockCounter++;
          currentSection = '';
        }
        
        // Set type to cultural context
        currentType = ContentBlockType.culturalContext;
        currentSpeaker = null;
        currentSection = line.substring(2);
        continue;
      }
      
      // Check for instruction markers
      if (line.startsWith('>> ')) {
        // Process previous section if any
        if (currentSection.isNotEmpty) {
          blocks.add(_createBlockFromSection(
            blockCounter.toString(),
            currentSection.trim(),
            currentType,
            currentSpeaker,
          ));
          blockCounter++;
          currentSection = '';
        }
        
        // Set type to instruction
        currentType = ContentBlockType.instruction;
        currentSpeaker = null;
        currentSection = line.substring(3);
        continue;
      }
      
      // Append to current section
      if (currentSection.isNotEmpty) {
        currentSection += ' ' + line;
      } else {
        currentSection = line;
      }
    }
    
    // Process final section if any
    if (currentSection.isNotEmpty) {
      blocks.add(_createBlockFromSection(
        blockCounter.toString(),
        currentSection.trim(),
        currentType,
        currentSpeaker,
      ));
    }
    
    return blocks;
  }
  
  /// Helper to create a block from a section of text
  static ContentBlock _createBlockFromSection(
    String id,
    String text,
    ContentBlockType type,
    Character? speaker,
  ) {
    switch (type) {
      case ContentBlockType.dialogue:
        return ContentBlock.dialogue(
          id: 'block_$id',
          text: text,
          speaker: speaker ?? Character.narrator(),
        );
      case ContentBlockType.description:
        return ContentBlock.description(
          id: 'block_$id',
          text: text,
        );
      case ContentBlockType.culturalContext:
        return ContentBlock.culturalContext(
          id: 'block_$id',
          text: text,
        );
      case ContentBlockType.instruction:
        return ContentBlock.instruction(
          id: 'block_$id',
          text: text,
        );
      default:
        return ContentBlock.narration(
          id: 'block_$id',
          text: text,
        );
    }
  }
}

/// Helper class to convert between story formats
class ContentBlockConverter {
  /// Convert simple markdown to content blocks
  static List<ContentBlock> fromMarkdown(String markdown, {Map<String, Character>? characters}) {
    return ContentBlock.fromScript(markdown, characters: characters);
  }
  
  /// Convert content blocks to simple markdown
  static String toMarkdown(List<ContentBlock> blocks) {
    final buffer = StringBuffer();
    
    for (final block in blocks) {
      switch (block.type) {
        case ContentBlockType.narration:
          buffer.writeln('# ${block.text}');
          buffer.writeln();
          break;
        case ContentBlockType.dialogue:
          final speakerName = block.speaker?.name ?? 'Narrator';
          buffer.writeln('$speakerName: ${block.text}');
          buffer.writeln();
          break;
        case ContentBlockType.description:
          buffer.writeln('*${block.text}*');
          buffer.writeln();
          break;
        case ContentBlockType.culturalContext:
          buffer.writeln('> ${block.text}');
          buffer.writeln();
          break;
        case ContentBlockType.instruction:
          buffer.writeln('>> ${block.text}');
          buffer.writeln();
          break;
        default:
          buffer.writeln(block.text);
          buffer.writeln();
          break;
      }
    }
    
    return buffer.toString();
  }
  
  /// Export content blocks to JSON string
  static String toJsonString(List<ContentBlock> blocks) {
    final List<Map<String, dynamic>> blockMaps = 
        blocks.map((block) => block.toJson()).toList();
    return jsonEncode(blockMaps);
  }
  
  /// Import content blocks from JSON string
  static List<ContentBlock> fromJsonString(String jsonString) {
    final List<dynamic> blockMaps = jsonDecode(jsonString);
    return blockMaps
        .map((map) => ContentBlock.fromJson(map))
        .toList();
  }
}

/// Helper class to provide character voices for the app
class CharacterVoiceLibrary {
  /// Map of character ID to character object
  static final Map<String, Character> _characters = {
    'kwaku': Character.kwaku(),
    'nana_yaw': Character.nanaYaw(),
    'auntie_efua': Character.auntieEfua(),
    'ama': Character.ama(),
    'narrator': Character.narrator(),
  };
  
  /// Get a character by ID
  static Character? getCharacter(String id) {
    return _characters[id];
  }
  
  /// Get all available characters
  static Map<String, Character> getAllCharacters() {
    return Map.unmodifiable(_characters);
  }
  
  /// Add a custom character
  static void addCharacter(Character character) {
    _characters[character.id] = character;
  }
  
  /// Create a character with specific TTS settings
  static Character createCustomCharacter({
    required String id,
    required String name,
    String? description,
    double pitch = 1.0,
    double rate = 1.0,
    EmotionalTone tone = EmotionalTone.neutral,
    String? avatarPath,
    String? role,
    int? age,
    String? gender,
    Map<String, dynamic>? metadata,
  }) {
    return Character(
      id: id,
      name: name,
      description: description,
      voiceSettings: TTSSettings(
        pitch: pitch,
        rate: rate,
        tone: tone,
      ),
      avatarPath: avatarPath,
      role: role,
      age: age,
      gender: gender,
      metadata: metadata,
    );
  }
}

/// Helper class for educational concepts in story blocks
class ConceptHelper {
  /// Map of concept IDs to their descriptions
  static final Map<String, String> _conceptDescriptions = {
    'sequence': 'A set of instructions executed one after another',
    'loop': 'A structure that repeats a block of code',
    'pattern': 'A reusable structure that can be repeated',
    'variables': 'Named storage locations for data values',
    'conditionals': 'Decision-making structures that execute code based on conditions',
    'functions': 'Reusable blocks of code that perform specific tasks',
    'debug': 'The process of finding and fixing errors in code',
  };
  
  /// Map of concepts to related Kente elements
  static final Map<String, String> _conceptToKenteMapping = {
    'sequence': 'Warp and weft threads in Kente weaving',
    'loop': 'Repeated patterns in traditional Kente cloth',
    'pattern': 'Named patterns like Dame-Dame in Kente',
    'variables': 'Different colors and their cultural meanings',
    'conditionals': 'Color selection based on the pattern section',
    'functions': 'Standard techniques used across different Kente patterns',
    'debug': 'Fixing mistakes in the pattern during weaving',
  };
  
  /// Get description of a concept
  static String getConceptDescription(String conceptId) {
    return _conceptDescriptions[conceptId] ?? 'Unknown concept';
  }
  
  /// Get the Kente mapping for a coding concept
  static String getKenteMapping(String conceptId) {
    return _conceptToKenteMapping[conceptId] ?? 'No direct mapping available';
  }
  
  /// Get educational content block for a concept
  static ContentBlock getConceptExplanation(String conceptId, {String? id}) {
    final conceptName = conceptId.split('_').map((word) => 
      word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
    
    final description = getConceptDescription(conceptId);
    final kenteMapping = getKenteMapping(conceptId);
    
    return ContentBlock.educational(
      id: id ?? 'concept_${conceptId}_explanation',
      text: 'In coding, $conceptName is $description. In Kente weaving, this relates to $kenteMapping.',
      metadata: {
        'conceptId': conceptId,
        'conceptName': conceptName,
      },
    );
  }
}

/// Extension for ContentBlock to add educational block factory
extension EducationalContentBlock on ContentBlock {
  /// Factory for creating educational content blocks
  static ContentBlock educational({
    required String id,
    required String text,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 0,
    bool waitForInteraction = true,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      id: id,
      type: ContentBlockType.educational,
      text: text,
      speaker: Character.narrator(),
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 0.95,
        tone: EmotionalTone.thoughtful,
        pauseAfter: 1000,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath,
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: metadata,
    );
  }
}

/// Extension for ContentBlock to add feedback block factory
extension FeedbackContentBlock on ContentBlock {
  /// Factory for creating feedback content blocks
  static ContentBlock feedback({
    required String id,
    required String text,
    bool isPositive = true,
    Character? speaker,
    TTSSettings? ttsSettings,
    String? backgroundImagePath,
    String? animationPath,
    String? soundEffectPath,
    int delay = 0,
    int displayDuration = 3000,
    bool waitForInteraction = false,
    Map<String, dynamic>? metadata,
  }) {
    final mergedMetadata = {
      'isPositive': isPositive,
      ...?metadata,
    };
    
    return ContentBlock(
      id: id,
      type: ContentBlockType.feedback,
      text: text,
      speaker: speaker,
      ttsSettings: ttsSettings ?? TTSSettings(
        rate: 1.0,
        tone: isPositive ? EmotionalTone.happy : EmotionalTone.concerned,
        pauseAfter: 300,
      ),
      backgroundImagePath: backgroundImagePath,
      animationPath: animationPath,
      soundEffectPath: soundEffectPath ?? (isPositive ? 
        'assets/audio/success.mp3' : 'assets/audio/failure.mp3'),
      delay: delay,
      displayDuration: displayDuration,
      waitForInteraction: waitForInteraction,
      metadata: mergedMetadata,
    );
  }
}