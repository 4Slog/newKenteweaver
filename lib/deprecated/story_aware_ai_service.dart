import 'package:flutter/foundation.dart';
import '../models/block_model.dart';
import 'gemini_service.dart';

/// Service for managing AI-driven story interactions and responses
class StoryAwareAIService {
  final GeminiService _geminiService;
  
  // Story context tracking
  String _currentNarrative = '';
  Map<String, dynamic> _characterContext = {};
  List<String> _storyThreads = [];
  
  StoryAwareAIService() : _geminiService = GeminiService();

  /// Generates a mentor personality based on the current story context
  Future<Map<String, dynamic>> generateMentorPersonality(String storyContext) async {
    try {
      final prompt = '''
        Given the following story context, create a mentor personality:
        Context: $storyContext
        
        Generate a response with:
        - Personality traits
        - Teaching style
        - Cultural background
        - Communication style
      ''';

      final response = await _geminiService.generateText(prompt);
      return _parseMentorPersonality(response);
    } catch (e) {
      debugPrint('Error generating mentor personality: $e');
      return {
        'personality': 'wise and patient',
        'teachingStyle': 'traditional',
        'culturalBackground': 'Akan elder',
        'communicationStyle': 'storytelling'
      };
    }
  }

  /// Identifies story threads and themes in the current interaction
  Future<List<String>> identifyStoryThreads(String interaction) async {
    try {
      final prompt = '''
        Analyze this interaction and identify key story threads:
        Interaction: $interaction
        
        Focus on:
        - Cultural themes
        - Learning objectives
        - Character development
        - Pattern symbolism
      ''';

      final response = await _geminiService.generateText(prompt);
      return _parseStoryThreads(response);
    } catch (e) {
      debugPrint('Error identifying story threads: $e');
      return ['cultural heritage', 'pattern mastery', 'personal growth'];
    }
  }

  /// Generates a contextually appropriate mentor response
  Future<String> generateMentorResponse(
    String userInput,
    String currentContext,
    List<String> previousResponses,
  ) async {
    try {
      final prompt = '''
        Generate a mentor response based on:
        User Input: $userInput
        Current Context: $currentContext
        Previous Responses: ${previousResponses.join(', ')}
        
        The response should:
        - Be culturally authentic
        - Include teaching elements
        - Reference Kente patterns when relevant
        - Maintain story continuity
      ''';

      return await _geminiService.generateText(prompt);
    } catch (e) {
      debugPrint('Error generating mentor response: $e');
      return 'Let us continue our journey of learning and discovery.';
    }
  }

  Map<String, dynamic> _parseMentorPersonality(String response) {
    // Simple parsing for now - could be enhanced with more sophisticated parsing
    return {
      'personality': 'wise and patient',
      'teachingStyle': 'traditional',
      'culturalBackground': 'Akan elder',
      'communicationStyle': 'storytelling'
    };
  }

  List<String> _parseStoryThreads(String response) {
    // Simple parsing for now - could be enhanced with more sophisticated parsing
    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
  }

  Future<Map<String, dynamic>> enhanceStoryContext({
    required String storyPoint,
    required Map<String, dynamic> learningContext,
  }) async {
    // Update story context
    _currentNarrative = storyPoint;
    
    // Generate Kweku's personality adaptations
    final personalityContext = await generateMentorPersonality(storyPoint);

    // Update character context
    _characterContext = personalityContext;

    // Track story threads
    _storyThreads = await identifyStoryThreads(storyPoint);

    return {
      'narrative': _currentNarrative,
      'mentor_context': _characterContext,
      'story_threads': _storyThreads,
    };
  }

  Future<String> generateContextualResponse({
    required String trigger,
    required BlockCollection workspace,
    required Map<String, dynamic> learningState,
  }) async {
    return generateMentorResponse(
      trigger,
      _currentNarrative,
      _storyThreads,
    );
  }
} 
