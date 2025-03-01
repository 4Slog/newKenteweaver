import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pattern_difficulty.dart';

class GeminiService {
  static const String _modelName = 'models/gemini-1.0-pro';
  late GenerativeModel _model;
  
  GeminiService._();

  static Future<GeminiService> initialize() async {
    final service = GeminiService._();
    await service._initializeModel();
    return service;
  }

  Future<void> _initializeModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('Gemini API key not found in .env file');
    }
    _model = GenerativeModel(model: _modelName, apiKey: apiKey);
  }

  Future<Map<String, dynamic>> analyzePattern({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
  }) async {
    try {
      // Convert blocks to a descriptive format for the AI
      final patternDescription = _generatePatternDescription(blocks);
      
      // Create prompt for pattern analysis
      final prompt = '''
Analyze this Kente pattern design:
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

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;
      
      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

      // Parse JSON response
      return _parseAnalysisResponse(responseText);
    } catch (e) {
      return _generateFallbackAnalysis(blocks, difficulty);
    }
  }

  Future<String> generateMentoringHint({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
    required List<String> previousHints,
  }) async {
    try {
      final context = '''
Current Pattern:
${_generatePatternDescription(blocks)}

Difficulty Level: ${difficulty.toString().split('.').last}
Previous Hints: ${previousHints.join(', ')}

Provide a helpful, culturally-informed hint for the next step in creating this Kente pattern. 
Focus on both technical aspects and cultural significance.
''';

      final content = [Content.text(context)];
      final response = await _model.generateContent(content);
      return response.text ?? _getFallbackHint(blocks, difficulty);
    } catch (e) {
      return _getFallbackHint(blocks, difficulty);
    }
  }

  Future<Map<String, dynamic>> suggestPersonalizedPath({
    required List<Map<String, dynamic>> completedPatterns,
    required PatternDifficulty currentLevel,
    required Map<String, dynamic> userProgress,
  }) async {
    try {
      final context = '''
User Progress:
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

  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Clean the response string to ensure it's valid JSON
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

  String _getFallbackHint(List<Map<String, dynamic>> blocks, PatternDifficulty difficulty) {
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

  String _describeCompletedPatterns(List<Map<String, dynamic>> patterns) {
    return patterns.map((p) => p['type']).join(', ');
  }

  String _formatUserProgress(Map<String, dynamic> progress) {
    return progress.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
