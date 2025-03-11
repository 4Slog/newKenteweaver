import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:google_generative_ai/google_generative_ai.dart' hide Content;
import '../models/block_model.dart' as blocks;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pattern_difficulty.dart';
import 'package:flutter/foundation.dart';
import '../models/learning_progress_model.dart';

class GeminiService {
  static const String _modelName = 'models/gemini-1.0-pro';
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  late final GenerativeModel _mentorModel;
  final gemini.Gemini _gemini;
  
  GeminiService() : _gemini = gemini.Gemini.instance {
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
    final mentorPrompt = '''
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
    '''.trim();

    try {
      await _gemini.prompt(
        parts: [gemini.Part.text(mentorPrompt)],
      );
    } catch (e) {
      debugPrint('Error initializing mentor personality: $e');
    }
  }

  Future<Map<String, dynamic>> analyzePattern({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
  }) async {
    try {
      final patternDescription = _generatePatternDescription(blocks);
      
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

      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      final responseText = response?.output;
      
      if (responseText == null) {
        throw Exception('Empty response from Gemini');
      }

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

      final response = await _gemini.prompt(parts: [gemini.Part.text(context)]);
      return response?.output ?? _getFallbackHint(blocks, difficulty);
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

      final response = await _gemini.prompt(parts: [gemini.Part.text(context)]);
      final responseText = response?.output;
      
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
    required blocks.BlockCollection currentBlocks,
    required String challengeId,
    required String conceptTaught,
    String? error,
  }) async {
    try {
      final Map<String, dynamic> prompt = {
        "challenge_id": challengeId,
        "concept_taught": conceptTaught,
        "current_blocks": currentBlocks.toJson(),
        if (error != null) "error": error,
        "expected_output": {
          "is_valid": "boolean",
          "feedback": "constructive feedback",
          "can_continue": "boolean",
          "next_hint": "hint for story continuation if needed"
        }
      };

      final result = await _generateResponse(prompt);
      return result.isNotEmpty ? result : _generateFallbackValidation();
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
    required blocks.BlockCollection currentBlocks,
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

      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      return response?.output ?? _getFallbackContextualHint(currentConcept);
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
      final result = await _generateResponse(patternJson);
      return result.isNotEmpty ? result : patternJson;
    } catch (e) {
      debugPrint('Error enhancing pattern: $e');
      return patternJson;
    }
  }

  Future<String> getMentorFeedback({
    required blocks.BlockCollection currentBlocks,
    required String action,
    required String storyContext,
    String? error,
  }) async {
    try {
      final Map<String, dynamic> prompt = {
        "action": action,
        "story_context": storyContext,
        "current_blocks": currentBlocks.toJson(),
        if (error != null) "error": error,
        "expected_output": {
          "feedback": "constructive feedback based on action and context"
        }
      };

      final result = await _generateResponse(prompt);
      return result["feedback"] as String? ?? "I'll help you with that. What would you like to know?";
    } catch (e) {
      debugPrint('Error getting mentor feedback: $e');
      return "I'm here to help. What would you like to know?";
    }
  }

  Future<String> generateText(String prompt) async {
    try {
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      return response?.output ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating text: $e');
      return 'An error occurred while generating text';
    }
  }

  /// Generates an introduction for a coding challenge based on the given context
  Future<String> generateChallengeIntroduction({
    required Map<String, dynamic> context,
    required List<dynamic> availableTools,
  }) async {
    final prompt = '''
    Create an engaging introduction for a coding challenge with these details:
    Context: ${json.encode(context)}
    Available Tools: ${json.encode(availableTools)}
    
    Keep it concise, fun, and focused on the learning objective.
    ''';

    final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
    return response?.output ?? 'Let\'s tackle this coding challenge!';
  }

  /// Generates completion text for a successfully completed challenge
  Future<String> generateChallengeCompletion({
    required Map<String, dynamic> context,
    required dynamic solution,
    required Map<String, dynamic> result,
  }) async {
    final prompt = '''
    Create an encouraging completion message for a solved coding challenge:
    Context: ${json.encode(context)}
    Solution Success: ${result['success']}
    Performance: ${json.encode(result['metrics'])}
    
    Focus on celebrating achievement and connecting to the next story point.
    ''';

    final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
    return response?.output ?? 'Great job completing the challenge!';
  }

  /// Generates personalized guidance based on user's learning progress
  Future<Map<String, dynamic>> generatePersonalizedGuidance({
    required String conceptId,
    Map<String, dynamic>? mastery,
    List<Map<String, dynamic>>? history,
    required String storyContext,
  }) async {
    try {
      // Prepare the prompt with learning context
      final prompt = {
        'conceptId': conceptId,
        'mastery': mastery,
        'history': history,
        'storyContext': storyContext,
      };

      // Generate guidance using Gemini
      final response = await _generateResponse(prompt);
      
      return {
        'guidance': response['guidance'] ?? '',
        'suggestions': response['suggestions'] ?? [],
        'nextSteps': response['nextSteps'] ?? [],
      };
    } catch (e) {
      debugPrint('Error generating personalized guidance: $e');
      return {
        'guidance': 'Keep practicing to improve your skills!',
        'suggestions': [],
        'nextSteps': [],
      };
    }
  }

  /// Analyzes dependencies between concepts
  Future<List<String>> analyzeConceptDependencies(
    String concept,
    Map<String, dynamic> mastery,
  ) async {
    try {
      // Prepare the prompt for dependency analysis
      final prompt = {
        'concept': concept,
        'mastery': mastery,
      };

      // Generate analysis using Gemini
      final response = await _generateResponse(prompt);
      
      return (response['dependencies'] as List?)?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error analyzing concept dependencies: $e');
      return [];
    }
  }

  /// Generates an optimized learning path
  Future<List<String>> generateOptimizedPath(
    Map<String, Map<String, dynamic>> mastery,
    Map<String, List<String>> dependencies,
    Map<String, double> weights,
  ) async {
    try {
      // Prepare the prompt for path optimization
      final prompt = {
        'mastery': mastery,
        'dependencies': dependencies,
        'weights': weights,
      };

      // Generate path using Gemini
      final response = await _generateResponse(prompt);
      
      return (response['path'] as List?)?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error generating optimized path: $e');
      return [];
    }
  }

  /// Generates a response from Gemini API
  Future<Map<String, dynamic>> _generateResponse(dynamic input) async {
    if (input == null) {
      return {};
    }

    String promptStr;
    if (input is Map) {
      promptStr = jsonEncode(input);
    } else if (input is String) {
      promptStr = input;
    } else {
      return {};
    }

    try {
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(promptStr)],
      );

      final output = response?.output;
      if (output == null) {
        return {};
      }

      return jsonDecode(output) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error generating response: $e');
      return {};
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
