import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/pattern_difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedAIService {
  static const String _modelName = 'gemini-pro';
  late GenerativeModel _model;
  final SharedPreferences _prefs;

  // Singleton pattern
  static UnifiedAIService? _instance;

  UnifiedAIService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<UnifiedAIService> getInstance({
    required SharedPreferences prefs,
  }) async {
    if (_instance == null) {
      _instance = UnifiedAIService._(prefs: prefs);
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

  // Pattern Analysis
  Future<Map<String, dynamic>> analyzePattern({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
    required String language,
  }) async {
    try {
      final patternDescription = _generatePatternDescription(blocks);
      final prompt = await _buildAnalysisPrompt(
        patternDescription,
        difficulty,
        language,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      return _parseAnalysisResponse(responseText);
    } catch (e) {
      return _generateFallbackAnalysis(blocks, difficulty);
    }
  }

  // Mentoring and Hints
  Future<String> generateMentoringHint({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
    required List<String> previousHints,
    required String language,
  }) async {
    try {
      final context = await _buildMentoringPrompt(
        blocks,
        difficulty,
        previousHints,
        language,
      );

      final content = [Content.text(context)];
      final response = await _model.generateContent(content);
      return response.text ?? _getFallbackHint(blocks, difficulty);
    } catch (e) {
      return _getFallbackHint(blocks, difficulty);
    }
  }

  // Learning Path Generation
  Future<Map<String, dynamic>> suggestPersonalizedPath({
    required List<Map<String, dynamic>> completedPatterns,
    required PatternDifficulty currentLevel,
    required Map<String, dynamic> userProgress,
    required String language,
  }) async {
    try {
      final context = await _buildPathSuggestionPrompt(
        completedPatterns,
        currentLevel,
        userProgress,
        language,
      );

      final content = [Content.text(context)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      return _parsePathSuggestion(responseText);
    } catch (e) {
      return _generateFallbackPath(currentLevel);
    }
  }

  // Story Generation
  Future<Map<String, dynamic>> generateStoryContent({
    required String storyType,
    required PatternDifficulty difficulty,
    required String language,
    Map<String, dynamic>? context,
  }) async {
    try {
      final prompt = await _buildStoryPrompt(
        storyType,
        difficulty,
        language,
        context,
      );

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      return _parseStoryResponse(responseText);
    } catch (e) {
      return _generateFallbackStory(storyType, language);
    }
  }

  // Translation Support
  Future<String> translateContent({
    required String content,
    required String targetLanguage,
    required bool isPremium,
  }) async {
    if (_isLanguageFree(targetLanguage)) {
      return await _getLocalTranslation(content, targetLanguage);
    }

    if (!isPremium) {
      throw Exception('Premium required for this language');
    }

    try {
      final prompt = _buildTranslationPrompt(content, targetLanguage);
      final aiContent = [Content.text(prompt)];
      final response = await _model.generateContent(aiContent);
      return response.text ?? content;
    } catch (e) {
      return content;
    }
  }

  // Helper Methods
  String _generatePatternDescription(List<Map<String, dynamic>> blocks) {
    final buffer = StringBuffer();
    buffer.writeln('Pattern Components:');

    for (final block in blocks) {
      final type = block['type'] as String;
      final value = block['value'] as String?;

      if (type.contains('pattern')) {
        buffer.writeln('- Main Pattern: $value');
      } else if (type.contains('color')) {
        buffer.writeln('- Color Used: $value');
      } else if (type == 'rows' || type == 'columns') {
        buffer.writeln('- ${type.capitalize()}: $value');
      } else if (type == 'repeats') {
        buffer.writeln('- Repetitions: $value');
      }
    }

    return buffer.toString();
  }

  Future<String> _buildAnalysisPrompt(
      String patternDescription,
      PatternDifficulty difficulty,
      String language,
      ) async {
    return '''
Analyze this Kente pattern design in $language:
$patternDescription

Difficulty Level: ${difficulty.toString().split('.').last}

Provide analysis in the following JSON format:
{
  "complexity_score": <0.0-1.0>,
  "cultural_accuracy": <0.0-1.0>,
  "learning_suggestions": ["suggestion1", "suggestion2"],
  "cultural_significance": "detailed explanation",
  "technical_feedback": "specific improvements",
  "next_steps": "recommended learning path"
}
''';
  }

  Future<String> _buildMentoringPrompt(
      List<Map<String, dynamic>> blocks,
      PatternDifficulty difficulty,
      List<String> previousHints,
      String language,
      ) async {
    return '''
Current Pattern in $language:
${_generatePatternDescription(blocks)}

Difficulty Level: ${difficulty.toString().split('.').last}
Previous Hints: ${previousHints.join(', ')}

Provide a helpful, culturally-informed hint for the next step in creating this Kente pattern. 
Focus on both technical aspects and cultural significance.
''';
  }

  Future<String> _buildPathSuggestionPrompt(
      List<Map<String, dynamic>> completedPatterns,
      PatternDifficulty currentLevel,
      Map<String, dynamic> userProgress,
      String language,
      ) async {
    return '''
User Progress in $language:
- Current Level: ${currentLevel.toString().split('.').last}
- Completed Patterns: ${_describeCompletedPatterns(completedPatterns)}
- Learning Stats: ${_formatUserProgress(userProgress)}

Suggest a personalized learning path in JSON format:
{
  "recommended_patterns": ["pattern1", "pattern2"],
  "skill_focus": ["skill1", "skill2"],
  "difficulty_adjustment": "increase/maintain/decrease",
  "cultural_elements": ["element1", "element2"],
  "estimated_completion_time": "X weeks",
  "rationale": "explanation"
}
''';
  }

  Future<String> _buildStoryPrompt(
      String storyType,
      PatternDifficulty difficulty,
      String language,
      Map<String, dynamic>? context,
      ) async {
    return '''
Generate an interactive story in $language:
Type: $storyType
Difficulty: ${difficulty.toString().split('.').last}
Context: ${context?.toString() ?? 'None'}

Include:
- Cultural elements
- Technical challenges
- Learning objectives
- Interactive elements
''';
  }

  String _buildTranslationPrompt(String content, String targetLanguage) {
    return '''
Translate the following content to $targetLanguage, maintaining:
1. Technical accuracy
2. Cultural context
3. Educational value

Content:
$content
''';
  }

  bool _isLanguageFree(String language) {
    return ['tw', 'ga'].contains(language.toLowerCase());
  }

  Future<String> _getLocalTranslation(String content, String language) async {
    // In a real implementation, this would fetch from local storage or bundled translations
    return content;
  }

  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      final cleanJson = response.substring(
        response.indexOf('{'),
        response.lastIndexOf('}') + 1,
      );
      return Map<String, dynamic>.from(
          jsonDecode(cleanJson) as Map<String, dynamic>
      );
    } catch (e) {
      return _generateFallbackAnalysis([], PatternDifficulty.basic);
    }
  }

  Map<String, dynamic> _generateFallbackAnalysis(
      List<Map<String, dynamic>> blocks,
      PatternDifficulty difficulty,
      ) {
    return {
      'complexity_score': 0.5,
      'cultural_accuracy': 0.7,
      'learning_suggestions': [
        'Try adding more color variety',
        'Experiment with pattern repetition',
      ],
      'cultural_significance': 'This pattern incorporates traditional Kente elements',
      'technical_feedback': 'Consider the balance of colors and pattern spacing',
      'next_steps': 'Practice with basic pattern combinations',
    };
  }

  String _getFallbackHint(
      List<Map<String, dynamic>> blocks,
      PatternDifficulty difficulty,
      ) {
    if (blocks.isEmpty) {
      return 'Start by adding a basic pattern block to your design.';
    }

    bool hasPattern = false;
    bool hasColor = false;
    for (final block in blocks) {
      if (block['type'].toString().contains('pattern')) hasPattern = true;
      if (block['type'].toString().contains('color')) hasColor = true;
    }

    if (!hasPattern) return 'Add a pattern block to define your design.';
    if (!hasColor) return 'Choose colors that have cultural significance.';

    return 'Try adjusting the pattern spacing or adding repetitions.';
  }

  Map<String, dynamic> _generateFallbackPath(PatternDifficulty currentLevel) {
    return {
      'recommended_patterns': ['checker', 'stripes_vertical'],
      'skill_focus': ['color harmony', 'pattern spacing'],
      'difficulty_adjustment': 'maintain',
      'cultural_elements': ['basic symbolism', 'color meaning'],
      'estimated_completion_time': '2 weeks',
      'rationale': 'Focus on mastering fundamental patterns',
    };
  }

  Map<String, dynamic> _generateFallbackStory(String storyType, String language) {
    return {
      'title': 'The Journey Begins',
      'content': 'A story about learning traditional patterns...',
      'challenges': [
        {
          'type': 'pattern_creation',
          'difficulty': 'basic',
          'description': 'Create your first pattern',
        }
      ],
      'language': language,
      'type': storyType,
    };
  }

  String _describeCompletedPatterns(List<Map<String, dynamic>> patterns) {
    return patterns.map((p) => p['type']).join(', ');
  }

  String _formatUserProgress(Map<String, dynamic> progress) {
    return progress.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  Map<String, dynamic> _parsePathSuggestion(String response) {
    try {
      final cleanJson = response.substring(
        response.indexOf('{'),
        response.lastIndexOf('}') + 1,
      );
      return Map<String, dynamic>.from(
          jsonDecode(cleanJson) as Map<String, dynamic>
      );
    } catch (e) {
      return _generateFallbackPath(PatternDifficulty.basic);
    }
  }

  Map<String, dynamic> _parseStoryResponse(String response) {
    try {
      final cleanJson = response.substring(
        response.indexOf('{'),
        response.lastIndexOf('}') + 1,
      );
      final parsed = Map<String, dynamic>.from(
          jsonDecode(cleanJson) as Map<String, dynamic>
      );

      // Ensure required fields exist
      return {
        'title': parsed['title'] ?? 'Untitled Story',
        'content': parsed['content'] ?? '',
        'challenges': parsed['challenges'] ?? [],
        'cultural_elements': parsed['cultural_elements'] ?? [],
        'learning_objectives': parsed['learning_objectives'] ?? [],
        'interactive_elements': parsed['interactive_elements'] ?? {},
      };
    } catch (e) {
      return {
        'title': 'Story Generation Error',
        'content': 'Unable to generate story content.',
        'challenges': [],
        'cultural_elements': [],
        'learning_objectives': [],
        'interactive_elements': {},
      };
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
