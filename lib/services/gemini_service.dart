import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/block_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pattern_difficulty.dart';

class GeminiService {
  static const String _modelName = 'models/gemini-1.0-pro';
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  late final GenerativeModel _mentorModel;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    _chatModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    _mentorModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    // Initialize mentor personality
    _initializeMentorPersonality();
  }

  Future<void> _initializeMentorPersonality() async {
    const mentorPrompt = '''
    You are Kweku Anane, a 9-10 year old tech-savvy mentor who teaches coding through Kente weaving.
    You are modern, witty, and use your knowledge for good.
    You should speak in a way that is engaging and understandable for children aged 7-12.
    Keep responses concise and fun.
    Focus on encouragement and gentle guidance rather than direct solutions.
    
    Your teaching style:
    1. Connect coding concepts to Kente weaving patterns
    2. Use storytelling to explain technical concepts
    3. Encourage experimentation and creativity
    4. Celebrate both successful attempts and learning from mistakes
    5. Keep cultural context engaging and age-appropriate
    ''';

    await _mentorModel.generateContent([
      Content.text(mentorPrompt),
    ]);
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

  Future<Map<String, dynamic>> validateChallenge({
    required BlockCollection currentBlocks,
    required String challengeId,
    required String conceptTaught,
    required Map<String, dynamic> challengeRequirements,
    required String storyContext,
  }) async {
    try {
      final prompt = '''
      Evaluate this student's solution for the current challenge:

      Story Context: $storyContext
      Concept Being Taught: $conceptTaught
      
      Challenge Requirements:
      ${jsonEncode(challengeRequirements)}
      
      Student's Solution:
      ${jsonEncode(currentBlocks.toJson())}
      
      Provide evaluation in JSON format:
      {
        "success": boolean,
        "score": float (0-1),
        "feedback": {
          "message": "encouraging feedback message",
          "highlights": ["what they did well"],
          "improvements": ["what they could try next"],
          "cultural_connection": "how their solution relates to Kente weaving"
        },
        "story_progression": {
          "can_continue": boolean,
          "next_hint": "hint for story continuation if needed"
        }
      }
      ''';

      final response = await _mentorModel.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null) {
        return _generateFallbackValidation();
      }

      return jsonDecode(response.text!) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error validating challenge: $e');
      return _generateFallbackValidation();
    }
  }

  Map<String, dynamic> _generateFallbackValidation() {
    return {
      "success": true,
      "score": 0.8,
      "feedback": {
        "message": "Great effort! You're getting the hang of it! 🌟",
        "highlights": ["Good pattern structure", "Nice color choices"],
        "improvements": ["Try adding more variety", "Experiment with repetition"],
        "cultural_connection": "Your pattern reminds me of the traditional Kente wisdom symbols!"
      },
      "story_progression": {
        "can_continue": true,
        "next_hint": "Now that you've mastered this pattern, let's see what other adventures await!"
      }
    };
  }

  Future<String> getContextualHint({
    required BlockCollection currentBlocks,
    required String storyContext,
    required String currentConcept,
    required List<String> previousHints,
    required Map<String, dynamic> challengeRequirements,
  }) async {
    try {
      final prompt = '''
      As Kweku Anane, provide a contextual hint for the student:

      Story Context: $storyContext
      Current Coding Concept: $currentConcept
      
      Challenge Requirements:
      ${jsonEncode(challengeRequirements)}
      
      Current Block Arrangement:
      ${jsonEncode(currentBlocks.toJson())}
      
      Previous Hints Given:
      ${previousHints.join('\n')}
      
      Provide a hint that:
      1. Connects to the current story point
      2. Links the coding concept to Kente weaving
      3. Is encouraging and age-appropriate
      4. Doesn't give away the solution
      5. Builds on previous hints without repeating them
      
      Keep the response under 2-3 sentences and make it fun!
      ''';

      final response = await _mentorModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? _getFallbackContextualHint(currentConcept);
    } catch (e) {
      debugPrint('Error getting contextual hint: $e');
      return _getFallbackContextualHint(currentConcept);
    }
  }

  String _getFallbackContextualHint(String concept) {
    return "Just like how we weave Kente patterns one thread at a time, let's build our code step by step! 🧶 Try experimenting with the blocks to see what happens! ✨";
  }

  Future<Map<String, dynamic>> enhancePattern(Map<String, dynamic> patternJson) async {
    try {
      final prompt = '''
      As Kweku Anane, analyze this pattern in the context of teaching coding through Kente weaving:
      
      ${jsonEncode(patternJson)}
      
      Enhance the pattern by:
      1. Adding cultural storytelling elements
      2. Connecting pattern structure to coding concepts
      3. Ensuring it's engaging for children aged 7-12
      4. Maintaining educational value while keeping it fun
      
      Return the enhanced pattern with additional metadata about:
      1. Cultural significance
      2. Coding concepts demonstrated
      3. Story connections
      4. Learning opportunities
      
      Keep the response in valid JSON format.
      ''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null) {
        return patternJson;
      }

      final enhancedJson = jsonDecode(response.text!) as Map<String, dynamic>;
      return enhancedJson;
    } catch (e) {
      debugPrint('Error enhancing pattern: $e');
      return patternJson;
    }
  }

  Future<String> getMentorFeedback({
    required BlockCollection currentBlocks,
    required String action,
    required String storyContext,
    String? error,
  }) async {
    try {
      final prompt = '''
      As Kweku Anane, provide feedback for the student's action in the current story context:

      Story Context: $storyContext
      Action Taken: $action
      ${error != null ? 'Error Encountered: $error' : ''}
      
      Current Blocks:
      ${jsonEncode(currentBlocks.toJson())}
      
      Provide encouraging feedback that:
      1. Ties to the current story point
      2. Acknowledges their effort
      3. Makes connections to Kente weaving
      4. Encourages further exploration
      
      Keep the response friendly, brief, and fun!
      ''';

      final response = await _mentorModel.generateContent([
        Content.text(prompt),
      ]);

      return response.text ?? _getFallbackFeedback(error != null);
    } catch (e) {
      debugPrint('Error getting mentor feedback: $e');
      return _getFallbackFeedback(error != null);
    }
  }

  String _getFallbackFeedback(bool isError) {
    if (isError) {
      return "Oops! Even master weavers make mistakes sometimes! Let's try a different approach! 🌟";
    }
    return "That's the spirit! You're weaving code like a true Kente master! 🎨";
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
