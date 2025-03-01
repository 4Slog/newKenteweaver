import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pattern_difficulty.dart';
import '../models/lesson_model.dart';

class GeminiStoryService {
  static const String _modelName = 'gemini-pro';
  late GenerativeModel _model;
  
  // Singleton pattern
  static GeminiStoryService? _instance;
  
  GeminiStoryService._();

  static Future<GeminiStoryService> getInstance() async {
    if (_instance == null) {
      _instance = GeminiStoryService._();
      await _instance!._initializeModel();
    }
    return _instance!;
  }

  Future<void> _initializeModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('Gemini API key not found in .env file');
    }
    _model = GenerativeModel(model: _modelName, apiKey: apiKey);
  }

  Future<List<Map<String, dynamic>>> generateStorySteps({
    required LessonModel lesson,
    required String language,
    int stepsCount = 5,
  }) async {
    try {
      final prompt = _buildStoryPrompt(
        lesson: lesson,
        language: language,
        stepsCount: stepsCount,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      return _parseStoryResponse(responseText);
    } catch (e) {
      return _generateFallbackStory(lesson, stepsCount);
    }
  }

  String _buildStoryPrompt({
    required LessonModel lesson,
    required String language,
    required int stepsCount,
  }) {
    return '''
Generate an interactive educational story for a children's coding app in $language.

Lesson Title: ${lesson.title}
Lesson Description: ${lesson.description}
Difficulty Level: ${lesson.difficulty.displayName}
Number of Story Steps: $stepsCount

The story should feature Kwaku Ananse, the clever spider from Ghanaian folklore, as a tech-savvy mentor teaching children about coding through Kente weaving patterns.

For each story step, provide a JSON object with the following structure:
{
  "title": "Step Title",
  "content": "Step narrative content",
  "image": "Suggested image description",
  "hasChoice": true/false,
  "choices": [
    {"text": "Choice text", "nextStep": next step number},
    {"text": "Alternative choice", "nextStep": alternative next step number}
  ]
}

If hasChoice is false, don't include the choices array.

The story should:
1. Introduce coding concepts through Kente weaving metaphors
2. Include cultural context about Kente patterns and their meanings
3. Present challenges that require logical thinking
4. Be engaging and educational for children aged 7-12
5. Include branching paths based on choices

Return the response as a JSON array of story step objects.
''';
  }

  List<Map<String, dynamic>> _parseStoryResponse(String response) {
    try {
      // Extract JSON array from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == -1) {
        throw FormatException('Invalid JSON format in response');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = jsonDecode(jsonString) as List<dynamic>;
      
      return parsed.map((step) => Map<String, dynamic>.from(step as Map)).toList();
    } catch (e) {
      print('Error parsing story response: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _generateFallbackStory(
    LessonModel lesson,
    int stepsCount,
  ) {
    final List<Map<String, dynamic>> fallbackStory = [
      {
        'title': 'The Beginning',
        'content': 'Kwaku Ananse, the clever spider of Ghanaian folklore, has taken on a new role in the digital age. As a master weaver and coding expert, he has decided to teach the art of Kente weaving through code.',
        'image': 'assets/images/characters/ananse_teaching.png',
        'hasChoice': false,
      },
      {
        'title': 'The Challenge',
        'content': 'Ananse presents you with your first challenge: to create a simple pattern using the basic weaving blocks. "Every great weaver starts with the fundamentals," he explains.',
        'image': 'assets/images/tutorial/basic_pattern_explanation.png',
        'hasChoice': true,
        'choices': [
          {'text': 'Accept the challenge', 'nextStep': 2},
          {'text': 'Ask for more information', 'nextStep': 3},
        ],
      },
      {
        'title': 'Your First Pattern',
        'content': 'You decide to accept Ananse\'s challenge. He shows you how to use the basic blocks to create a simple checker pattern, explaining how each block represents a piece of code.',
        'image': 'assets/images/tutorial/loop_explanation.png',
        'hasChoice': false,
      },
      {
        'title': 'Learning More',
        'content': 'Ananse explains that Kente patterns are not just beautiful designs but also carry deep cultural meanings. Each color and pattern tells a story about Ghanaian history and values.',
        'image': 'assets/images/tutorial/color_meaning_diagram.png',
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
          {'text': 'Learn about pattern meanings', 'nextStep': 4},
        ],
      },
      {
        'title': 'The Meaning of Patterns',
        'content': 'Ananse explains that the checker pattern (Dame-Dame) represents strategy and wisdom, while the zigzag pattern (Nkyinkyim) symbolizes life\'s journey and adaptability.',
        'image': 'assets/images/tutorial/color_meaning_diagram.png',
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
        ],
      },
    ];

    // Return only the requested number of steps
    return fallbackStory.take(stepsCount).toList();
  }

  Future<String> translateStoryContent({
    required String content,
    required String targetLanguage,
  }) async {
    try {
      final prompt = '''
Translate the following story content to $targetLanguage, maintaining:
1. Educational value for children
2. Cultural context about Kente weaving
3. Coding concepts and terminology

Content:
$content
''';

      final aiContent = [Content.text(prompt)];
      final response = await _model.generateContent(aiContent);
      return response.text ?? content;
    } catch (e) {
      return content;
    }
  }
}
