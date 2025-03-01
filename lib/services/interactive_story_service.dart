import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';

class StoryChoice {
  final String id;
  final String text;
  final Map<String, dynamic> consequences;
  final Map<String, dynamic>? codingChallenge;

  const StoryChoice({
    required this.id,
    required this.text,
    required this.consequences,
    this.codingChallenge,
  });
}

class StoryNode {
  final String id;
  final String title;
  final List<Map<String, String>> content;
  final List<StoryChoice> choices;
  final Map<String, dynamic>? codingChallenge;
  final Map<String, dynamic>? patternIntegration;

  const StoryNode({
    required this.id,
    required this.title,
    required this.content,
    required this.choices,
    this.codingChallenge,
    this.patternIntegration,
  });
}

class InteractiveStoryService {
  static final Map<String, dynamic> _modernAnanseTraits = {
    'tech': {
      'laptop': "Kwaku pulled out his laptop, its screen reflecting the traditional patterns he had transformed into code.",
      'smartphone': "Checking his latest pattern-generation algorithm on his phone, Kwaku smiled.",
      'tablet': "With a few quick gestures on his tablet, Kwaku demonstrated how digital tools could enhance traditional designs.",
    },
    'personality': {
      'innovative': "As a software developer with deep respect for tradition, Kwaku saw endless possibilities in combining code with Kente patterns.",
      'mentor': "Despite his young age, Kwaku had already made a name for himself teaching coding through cultural storytelling.",
      'bridge': "Kwaku represented a new generation of cultural innovators, bridging ancient wisdom with modern technology.",
    },
    'catchphrases': [
      "Let's debug this pattern together!",
      "Every bug is just an opportunity for a better algorithm.",
      "Think of code like weaving - each line contributes to the bigger picture.",
      "In both coding and Kente, patterns tell stories.",
    ],
  };

  static final Map<String, Map<String, dynamic>> _patternChallenges = {
    'checker_pattern': {
      'story': '''
        "Check this out," Kwaku said, opening his IDE. "The Dame-Dame pattern is actually a perfect 
        introduction to nested loops. Let me show you how we can generate it programmatically."
        He started typing, explaining how each line of code mapped to the traditional pattern.
      ''',
      'challenge': {
        'type': 'code_completion',
        'difficulty': 'basic',
        'description': 'Help Kwaku complete the nested loop structure to generate the Dame-Dame pattern.',
        'hints': [
          'Think about how the pattern repeats both horizontally and vertically',
          'Consider using modulo operations to alternate colors',
        ],
      },
    },
    'zigzag_pattern': {
      'story': '''
        Kwaku pulled up a visualization tool he'd built. "The Nkyinkyim pattern taught me about 
        algorithmic thinking before I even knew what that meant! See how the zigzag follows a 
        mathematical pattern? We can express that in code."
      ''',
      'challenge': {
        'type': 'pattern_algorithm',
        'difficulty': 'intermediate',
        'description': 'Work with Kwaku to implement the mathematical function for the zigzag pattern.',
        'hints': [
          'Consider using sine waves as a base',
          'Think about transformation matrices',
        ],
      },
    },
  };

  static final Map<String, List<String>> _modernColorContext = {
    'gold': [
      'Kwaku demonstrated how to represent the royal gold color in different color spaces: RGB, HSL, and even custom color algorithms.',
      'Using color theory principles in his code, Kwaku showed how digital gold could maintain its cultural significance.',
    ],
    'red': [
      'With a few lines of code, Kwaku adjusted the red values to perfectly match traditional dyes.',
      'Through his color calibration algorithm, Kwaku ensured the digital red carried the same spiritual energy as its physical counterpart.',
    ],
  };

  Future<Map<String, dynamic>> generateInteractiveStory({
    required String patternType,
    required List<String> colors,
    required PatternDifficulty difficulty,
    required String preferredLanguage,
    Map<String, dynamic>? userProgress,
    Map<String, dynamic>? previousChoices,
  }) async {
    try {
      final storyNode = _generateStoryNode(
        patternType: patternType,
        colors: colors,
        difficulty: difficulty,
        userProgress: userProgress,
        previousChoices: previousChoices,
      );

      return {
        'story_node': storyNode,
        'translations': await _generateTranslations(storyNode, preferredLanguage),
        'interactive_elements': _generateInteractiveElements(storyNode, difficulty),
        'coding_challenge': _generateCodingChallenge(patternType, difficulty),
        'meta_data': {
          'language': preferredLanguage,
          'difficulty': difficulty.toString(),
          'pattern_type': patternType,
          'has_choices': storyNode.choices.isNotEmpty,
          'requires_code': storyNode.codingChallenge != null,
        },
      };
    } catch (e) {
      debugPrint('Error generating interactive story: $e');
      return _generateFallbackStory(patternType, preferredLanguage);
    }
  }

  StoryNode _generateStoryNode({
    required String patternType,
    required List<String> colors,
    required PatternDifficulty difficulty,
    Map<String, dynamic>? userProgress,
    Map<String, dynamic>? previousChoices,
  }) {
    final content = <Map<String, String>>[];
    final techContext = _modernAnanseTraits['tech'];
    final personality = _modernAnanseTraits['personality'];

    // Introduction based on user's progress
    content.add({
      'type': 'scene',
      'text': _selectIntroduction(userProgress),
    });

    // Add tech element
    content.add({
      'type': 'action',
      'text': techContext[_selectTechTool(difficulty)],
    });

    // Add pattern-specific content
    final patternChallenge = _patternChallenges[patternType];
    if (patternChallenge != null) {
      content.add({
        'type': 'dialogue',
        'text': patternChallenge['story'],
      });
    }

    // Generate choices based on difficulty and previous choices
    final choices = _generateChoices(difficulty, previousChoices);

    return StoryNode(
      id: '${patternType}_${difficulty.toString()}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Coding with Kwaku: ${_getPatternTitle(patternType)}',
      content: content,
      choices: choices,
      codingChallenge: patternChallenge?['challenge'],
      patternIntegration: {
        'colors': colors,
        'difficulty': difficulty.toString(),
        'interactive_elements': _generateInteractiveElements(null, difficulty),
      },
    );
  }

  String _selectIntroduction(Map<String, dynamic>? userProgress) {
    if (userProgress == null || userProgress['lessons_completed'] == 0) {
      return '''
        In his modern tech hub, decorated with both traditional Kente cloths and cutting-edge displays,
        Kwaku Ananse adjusted his dual monitors. The young software developer had found his calling
        in bridging the gap between traditional weaving patterns and modern programming.
      ''';
    }

    return '''
        "Welcome back!" Kwaku's voice carried the same enthusiasm he'd inherited from his 
        storytelling ancestors. His workspace hummed with the energy of both tradition and innovation,
        multiple screens displaying both ancient patterns and modern code.
      ''';
  }

  String _selectTechTool(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 'tablet'; // More approachable for beginners
      case PatternDifficulty.intermediate:
        return 'smartphone'; // Mobile development concepts
      case PatternDifficulty.advanced:
      case PatternDifficulty.master:
        return 'laptop'; // Professional development setup
    }
  }

  List<StoryChoice> _generateChoices(
    PatternDifficulty difficulty,
    Map<String, dynamic>? previousChoices,
  ) {
    final choices = <StoryChoice>[];

    // Add coding approach choice
    choices.add(StoryChoice(
      id: 'approach_visual',
      text: 'Ask Kwaku to explain using visual programming blocks',
      consequences: {
        'learning_style': 'visual',
        'next_challenge': 'block_based',
      },
      codingChallenge: {
        'type': 'blocks',
        'difficulty': difficulty.toString(),
      },
    ));

    choices.add(StoryChoice(
      id: 'approach_code',
      text: 'Ask Kwaku to show the raw code implementation',
      consequences: {
        'learning_style': 'technical',
        'next_challenge': 'code_based',
      },
      codingChallenge: {
        'type': 'code',
        'difficulty': difficulty.toString(),
      },
    ));

    // Add cultural learning choice
    choices.add(StoryChoice(
      id: 'cultural_context',
      text: 'Ask about the cultural significance of the pattern',
      consequences: {
        'learning_style': 'cultural',
        'unlocks': 'pattern_story',
      },
    ));

    return choices;
  }

  Map<String, dynamic> _generateInteractiveElements(
    StoryNode? node,
    PatternDifficulty difficulty,
  ) {
    return {
      'animations': {
        'kwaku_typing': 'assets/animations/kwaku_typing.json',
        'pattern_generation': 'assets/animations/pattern_gen.json',
      },
      'clickable_elements': [
        {
          'id': 'laptop_screen',
          'type': 'code_preview',
          'position': {'x': 0.3, 'y': 0.4},
        },
        {
          'id': 'pattern_display',
          'type': 'pattern_preview',
          'position': {'x': 0.7, 'y': 0.4},
        },
      ],
      'sound_effects': {
        'typing': 'assets/audio/keyboard_typing.mp3',
        'success': 'assets/audio/challenge_complete.mp3',
      },
    };
  }

  Map<String, dynamic> _generateCodingChallenge(
    String patternType,
    PatternDifficulty difficulty,
  ) {
    final challenge = _patternChallenges[patternType]?['challenge'];
    if (challenge == null) return {};

    return {
      ...challenge,
      'interactive_elements': {
        'code_editor': true,
        'pattern_preview': true,
        'real_time_feedback': true,
      },
      'completion_criteria': {
        'pattern_matches': true,
        'code_efficiency': difficulty.index >= PatternDifficulty.intermediate.index,
        'cultural_accuracy': true,
      },
    };
  }

  Future<Map<String, String>> _generateTranslations(
    StoryNode node,
    String baseLanguage,
  ) async {
    // In a real implementation, this would connect to a translation service
    // For now, we'll return a mock structure
    return {
      'en': _flattenContent(node.content),
      'fr': 'French translation would go here',
      'es': 'Spanish translation would go here',
      'tw': 'Twi translation would go here',
    };
  }

  String _flattenContent(List<Map<String, String>> content) {
    return content.map((c) => c['text']).join('\n\n');
  }

  String _getPatternTitle(String patternType) {
    switch (patternType) {
      case 'checker_pattern':
        return 'Digital Dame-Dame';
      case 'zigzag_pattern':
        return 'Coding Nkyinkyim';
      default:
        return 'Pattern Programming';
    }
  }

  Map<String, dynamic> _generateFallbackStory(
    String patternType,
    String language,
  ) {
    return {
      'story_node': StoryNode(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Coding with Kwaku',
        content: [{
          'type': 'dialogue',
          'text': 'Kwaku Ananse opened his laptop, ready to share another coding adventure.',
        }],
        choices: [],
      ),
      'translations': {
        'en': 'Kwaku Ananse opened his laptop, ready to share another coding adventure.',
      },
      'meta_data': {
        'language': language,
        'pattern_type': patternType,
        'is_fallback': true,
      },
    };
  }
}
