import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:google_generative_ai/google_generative_ai.dart' hide Content;
import '../models/block_model.dart' as blocks;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/pattern_difficulty.dart';
import 'package:flutter/foundation.dart';
import '../models/learning_progress_model.dart';
import 'logging_service.dart';
import 'storage_service.dart';

/// A service for interacting with Google's Gemini AI model
/// 
/// This service provides methods for generating AI-powered content,
/// including pattern analysis, mentoring hints, personalized learning paths,
/// and challenge validation.
class GeminiService {
  static const String _modelName = 'gemini-pro';
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  late final GenerativeModel _mentorModel;
  final gemini.Gemini _gemini;
  final LoggingService _loggingService;
  final StorageService? _storageService;
  
  // Cache for responses to reduce API calls with timestamp for expiration
  final Map<String, Map<String, dynamic>> _responseCache = {};
  
  // Cache expiration time (24 hours in milliseconds)
  static const int _cacheExpirationTime = 24 * 60 * 60 * 1000;
  
  // Singleton pattern
  static GeminiService? _instance;
  
  /// Private constructor to enforce singleton pattern
  GeminiService._({
    required LoggingService loggingService,
    StorageService? storageService,
  }) : _loggingService = loggingService,
       _storageService = storageService,
       _gemini = gemini.Gemini.instance;
  
  /// Factory constructor to get the singleton instance
  factory GeminiService({
    required LoggingService loggingService,
    StorageService? storageService,
  }) {
    _instance ??= GeminiService._(
      loggingService: loggingService,
      storageService: storageService,
    );
    return _instance!;
  }
  
  /// Initialize the Gemini service
  Future<void> initialize() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        _loggingService.error('GEMINI_API_KEY not found in environment variables', tag: 'GeminiService');
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }

      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );

      _chatModel = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );

      _mentorModel = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );

      // Initialize mentor personality
      await _initializeMentorPersonality();
      
      _loggingService.info('GeminiService initialized successfully', tag: 'GeminiService');
    } catch (e) {
      _loggingService.error('Error initializing GeminiService: $e', tag: 'GeminiService');
      rethrow;
    }
  }

  /// Initialize the mentor personality for consistent character interactions
  Future<void> _initializeMentorPersonality() async {
    final mentorPrompt = '''
    You are Kweku Anane, a 9-10 year old tech-savvy mentor who teaches coding through Kente weaving.
    You are modern, witty, and use your knowledge for good.
    You should speak in a way that is engaging and understandable for children aged 7-12.
    Keep responses concise and fun.
    Focus on encouragement and gentle guidance rather than direct solutions.
    
    Your personality traits:
    - Curious and inquisitive
    - Patient and encouraging
    - Playful but educational
    - Respectful of cultural traditions
    - Excited about both technology and art
    
    Your teaching style:
    1. Connect coding concepts to Kente weaving patterns
    2. Use storytelling to explain technical concepts
    3. Encourage experimentation and creativity
    4. Celebrate both successful attempts and learning from mistakes
    5. Keep cultural context engaging and age-appropriate
    
    When giving feedback:
    - Start with positive reinforcement
    - Offer specific suggestions for improvement
    - Connect feedback to cultural context when possible
    - End with encouragement
    '''.trim();

    try {
      await _gemini.prompt(
        parts: [gemini.Part.text(mentorPrompt)],
      );
      _loggingService.debug('Mentor personality initialized', tag: 'GeminiService');
    } catch (e) {
      _loggingService.warning('Error initializing mentor personality: $e', tag: 'GeminiService');
    }
  }
  
  /// Check if a cached response exists and is still valid
  /// 
  /// This method checks if a response is cached and not expired.
  /// Returns null if the cache is missing or expired.
  T? _getCachedResponse<T>(String cacheKey) {
    if (_responseCache.containsKey(cacheKey)) {
      final cacheEntry = _responseCache[cacheKey]!;
      final timestamp = cacheEntry['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      if (currentTime - timestamp <= _cacheExpirationTime) {
        return cacheEntry['data'] as T;
      } else {
        // Remove expired cache entry
        _responseCache.remove(cacheKey);
        _loggingService.debug('Removed expired cache for key: $cacheKey', tag: 'GeminiService');
      }
    }
    
    return null;
  }
  
  /// Cache a response with the current timestamp
  /// 
  /// This method stores a response in the cache with the current timestamp
  /// for expiration checking.
  void _cacheResponse<T>(String cacheKey, T data) {
    _responseCache[cacheKey] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _loggingService.debug('Cached response for key: $cacheKey', tag: 'GeminiService');
  }

  /// Analyze a pattern created by the user
  /// 
  /// This method sends the pattern to Gemini for analysis and returns
  /// feedback, suggestions, and cultural context.
  Future<Map<String, dynamic>> analyzePattern({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
    String language = 'en',
  }) async {
    try {
      final patternDescription = _generatePatternDescription(blocks);
      
      final prompt = '''
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

      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      final responseText = response?.output;
      
      if (responseText == null) {
        _loggingService.warning('Empty response from Gemini for pattern analysis', tag: 'GeminiService');
        throw Exception('Empty response from Gemini');
      }

      _loggingService.debug('Pattern analysis completed successfully', tag: 'GeminiService');
      return _parseAnalysisResponse(responseText);
    } catch (e) {
      _loggingService.error('Error analyzing pattern: $e', tag: 'GeminiService');
      return _generateFallbackAnalysis(blocks, difficulty);
    }
  }

  /// Generate a mentoring hint based on the user's current pattern
  /// 
  /// This method provides contextual hints to guide the user in their
  /// pattern creation process.
  Future<String> generateMentoringHint({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
    required List<String> previousHints,
    String language = 'en',
  }) async {
    try {
      final context = '''
Current Pattern in $language:
${_generatePatternDescription(blocks)}

Difficulty Level: ${difficulty.toString().split('.').last}
Previous Hints: ${previousHints.join(', ')}

Provide a helpful, culturally-informed hint for the next step in creating this Kente pattern. 
Focus on both technical aspects and cultural significance.
Keep the hint concise, engaging, and appropriate for children aged 7-12.
''';

      final response = await _gemini.prompt(parts: [gemini.Part.text(context)]);
      final hint = response?.output ?? _getFallbackHint(blocks, difficulty);
      _loggingService.debug('Generated mentoring hint successfully', tag: 'GeminiService');
      return hint;
    } catch (e) {
      _loggingService.error('Error generating mentoring hint: $e', tag: 'GeminiService');
      return _getFallbackHint(blocks, difficulty);
    }
  }

  /// Suggest a personalized learning path for the user
  /// 
  /// This method analyzes the user's progress and suggests next steps
  /// for their learning journey.
  Future<Map<String, dynamic>> suggestPersonalizedPath({
    required List<Map<String, dynamic>> completedPatterns,
    required PatternDifficulty currentLevel,
    required Map<String, dynamic> userProgress,
    String language = 'en',
  }) async {
    try {
      final context = '''
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

      final response = await _gemini.prompt(parts: [gemini.Part.text(context)]);
      final responseText = response?.output;
      
      if (responseText == null) {
        _loggingService.warning('Empty response from Gemini for personalized path', tag: 'GeminiService');
        throw Exception('Empty response from Gemini');
      }

      _loggingService.debug('Generated personalized learning path successfully', tag: 'GeminiService');
      return _parsePathSuggestion(responseText);
    } catch (e) {
      _loggingService.error('Error suggesting personalized path: $e', tag: 'GeminiService');
      return _generateFallbackPath(currentLevel);
    }
  }

  /// Validate a challenge solution
  /// 
  /// This method evaluates the user's solution to a coding challenge
  /// and provides feedback.
  Future<Map<String, dynamic>> validateChallenge({
    required blocks.BlockCollection currentBlocks,
    required String challengeId,
    required String conceptTaught,
    String? error,
    String language = 'en',
  }) async {
    try {
      final Map<String, dynamic> prompt = {
        "challenge_id": challengeId,
        "concept_taught": conceptTaught,
        "current_blocks": currentBlocks.toJson(),
        "language": language,
        if (error != null) "error": error,
        "expected_output": {
          "is_valid": "boolean",
          "feedback": "constructive feedback",
          "can_continue": "boolean",
          "next_hint": "hint for story continuation if needed"
        }
      };

      final result = await _generateResponse(prompt);
      _loggingService.debug('Challenge validation completed successfully', tag: 'GeminiService');
      return result.isNotEmpty ? result : _generateFallbackValidation();
    } catch (e) {
      _loggingService.error('Error validating challenge: $e', tag: 'GeminiService');
      return _generateFallbackValidation();
    }
  }

  /// Get a contextual hint for the current challenge
  /// 
  /// This method provides a hint that is specific to the current
  /// story context and challenge requirements.
  Future<String> getContextualHint({
    required blocks.BlockCollection currentBlocks,
    required String storyContext,
    required String currentConcept,
    required List<String> previousHints,
    required Map<String, dynamic> challengeRequirements,
    String language = 'en',
  }) async {
    try {
      final prompt = '''
      As Kweku Anane, provide a contextual hint for the student in $language:

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
      final hint = response?.output ?? _getFallbackContextualHint(currentConcept);
      _loggingService.debug('Generated contextual hint successfully', tag: 'GeminiService');
      return hint;
    } catch (e) {
      _loggingService.error('Error getting contextual hint: $e', tag: 'GeminiService');
      return _getFallbackContextualHint(currentConcept);
    }
  }

  /// Generate cultural context information for a pattern
  /// 
  /// This method provides cultural background and significance
  /// for a specific pattern or concept.
  Future<Map<String, dynamic>> generateCulturalContext({
    required String patternId,
    String language = 'en',
    bool includeColorMeanings = true,
    bool includeHistoricalContext = true,
  }) async {
    // Create a cache key based on parameters
    final cacheKey = 'cultural_context_${patternId}_${language}_$includeColorMeanings\_$includeHistoricalContext';
    
    // Check cache first to reduce API calls
    final cachedContext = _getCachedResponse<Map<String, dynamic>>(cacheKey);
    if (cachedContext != null) {
      _loggingService.debug('Using cached cultural context for pattern: $patternId', tag: 'GeminiService');
      return cachedContext;
    }
    
    // Convert pattern ID to a readable name
    final patternName = patternId
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
    
    String additionalRequests = '';
    if (includeColorMeanings) {
      additionalRequests += '''
      - Include information about the cultural significance of colors in Kente:
        - Black: Maturity, spiritual energy
        - Red: Political and spiritual significance, blood
        - Yellow/Gold: Royalty, wealth, fertility
        - Green: Growth, renewal, prosperity
        - Blue: Peace, harmony, love
      ''';
    }
    
    if (includeHistoricalContext) {
      additionalRequests += '''
      - Include a brief history of the pattern's origin
      - Mention when and where this pattern is traditionally used
      - Describe what social or cultural role the pattern plays
      ''';
    }
    
    final prompt = '''
    You are a cultural expert specializing in Ghanaian Kente cloth traditions.
    
    Please provide comprehensive cultural context about the "$patternName" pattern in Kente weaving.
    
    $additionalRequests
    
    Return your response in the following JSON format:
    ```json
    {
      "title": "Cultural title related to the pattern",
      "description": "Main description of cultural significance",
      "colorMeanings": {
        "color1": "meaning",
        "color2": "meaning"
      },
      "historicalContext": "Historical information about the pattern",
      "traditionalUse": "How the pattern is traditionally used",
      "imageDescription": "Description of what the pattern looks like"
    }
    ```
    
    Output language: $language
    
    Return ONLY the JSON data, no additional explanation.
    ''';

    try {
      // Generate content from the model
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      
      // Parse the response to a context object
      final contextData = _parseCulturalContextResponse(response?.output ?? '');
      
      // Cache the result
      _cacheResponse(cacheKey, contextData);
      
      _loggingService.debug('Generated cultural context successfully', tag: 'GeminiService');
      return contextData;
    } catch (e) {
      _loggingService.error('Error generating cultural context: $e', tag: 'GeminiService');
      // Return fallback cultural context in case of error
      return _generateFallbackCulturalContext(patternId, language);
    }
  }

  /// Generate mentor feedback based on user action
  /// 
  /// This method provides personalized feedback from the mentor character
  /// based on the user's current actions and story context.
  Future<String> getMentorFeedback({
    required blocks.BlockCollection currentBlocks,
    required String action,
    required String storyContext,
    String? error,
    String language = 'en',
  }) async {
    try {
      final Map<String, dynamic> prompt = {
        "action": action,
        "story_context": storyContext,
        "current_blocks": currentBlocks.toJson(),
        "language": language,
        if (error != null) "error": error,
        "expected_output": {
          "feedback": "constructive feedback based on action and context"
        }
      };

      final result = await _generateResponse(prompt);
      _loggingService.debug('Generated mentor feedback successfully', tag: 'GeminiService');
      return result["feedback"] as String? ?? "I'll help you with that. What would you like to know?";
    } catch (e) {
      _loggingService.error('Error getting mentor feedback: $e', tag: 'GeminiService');
      return "I'm here to help. What would you like to know?";
    }
  }

  /// Generate text based on a prompt
  /// 
  /// This is a general-purpose method for generating text from Gemini.
  Future<String> generateText(String prompt, {String language = 'en'}) async {
    try {
      final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
      _loggingService.debug('Generated text successfully', tag: 'GeminiService');
      return response?.output ?? 'No response generated';
    } catch (e) {
      _loggingService.error('Error generating text: $e', tag: 'GeminiService');
      return 'An error occurred while generating text';
    }
  }

  /// Generate an introduction for a coding challenge
  /// 
  /// This method creates an engaging introduction for a challenge
  /// based on the given context and available tools.
  Future<String> generateChallengeIntroduction({
    required Map<String, dynamic> context,
    required List<dynamic> availableTools,
    String language = 'en',
  }) async {
    final prompt = '''
    Create an engaging introduction for a coding challenge in $language with these details:
    Context: ${json.encode(context)}
    Available Tools: ${json.encode(availableTools)}
    
    Keep it concise, fun, and focused on the learning objective.
    Make it appropriate for children aged 7-12.
    ''';

    final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
    _loggingService.debug('Generated challenge introduction successfully', tag: 'GeminiService');
    return response?.output ?? 'Let\'s tackle this coding challenge!';
  }

  /// Generate completion text for a successfully completed challenge
  /// 
  /// This method creates an encouraging message when a user completes a challenge.
  Future<String> generateChallengeCompletion({
    required Map<String, dynamic> context,
    required dynamic solution,
    required Map<String, dynamic> result,
    String language = 'en',
  }) async {
    final prompt = '''
    Create an encouraging completion message in $language for a solved coding challenge:
    Context: ${json.encode(context)}
    Solution Success: ${result['success']}
    Performance: ${json.encode(result['metrics'])}
    
    Focus on celebrating achievement and connecting to the next story point.
    Make it appropriate for children aged 7-12.
    ''';

    final response = await _gemini.prompt(parts: [gemini.Part.text(prompt)]);
    _loggingService.debug('Generated challenge completion message successfully', tag: 'GeminiService');
    return response?.output ?? 'Great job completing the challenge!';
  }

  /// Generate personalized guidance based on user's learning progress
  /// 
  /// This method provides tailored guidance for the user based on their
  /// current progress and mastery of concepts.
  Future<Map<String, dynamic>> generatePersonalizedGuidance({
    required String conceptId,
    Map<String, dynamic>? mastery,
    List<Map<String, dynamic>>? history,
    required String storyContext,
    String language = 'en',
  }) async {
    try {
      // Prepare the prompt with learning context
      final prompt = {
        'conceptId': conceptId,
        'mastery': mastery,
        'history': history,
        'storyContext': storyContext,
        'language': language,
      };

      // Generate guidance using Gemini
      final response = await _generateResponse(prompt);
      _loggingService.debug('Generated personalized guidance successfully', tag: 'GeminiService');
      
      return {
        'guidance': response['guidance'] ?? '',
        'suggestions': response['suggestions'] ?? [],
        'nextSteps': response['nextSteps'] ?? [],
      };
    } catch (e) {
      _loggingService.error('Error generating personalized guidance: $e', tag: 'GeminiService');
      return {
        'guidance': 'Keep practicing to improve your skills!',
        'suggestions': [],
        'nextSteps': [],
      };
    }
  }

  /// Analyze dependencies between concepts
  /// 
  /// This method identifies which concepts are prerequisites for
  /// the given concept.
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
      _loggingService.debug('Analyzed concept dependencies successfully', tag: 'GeminiService');
      
      return (response['dependencies'] as List?)?.cast<String>() ?? [];
    } catch (e) {
      _loggingService.error('Error analyzing concept dependencies: $e', tag: 'GeminiService');
      return [];
    }
  }

  /// Generate an optimized learning path
  /// 
  /// This method creates a personalized learning path based on the user's
  /// current mastery, concept dependencies, and learning preferences.
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
      _loggingService.debug('Generated optimized learning path successfully', tag: 'GeminiService');
      
      return (response['path'] as List?)?.cast<String>() ?? [];
    } catch (e) {
      _loggingService.error('Error generating optimized path: $e', tag: 'GeminiService');
      return [];
    }
  }

  /// Generate a response from Gemini API
  /// 
  /// This is a helper method for generating structured responses.
  /// It handles JSON parsing, error recovery, and logging.
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
      // Create a cache key based on the input hash
      final cacheKey = 'response_${promptStr.hashCode}';
      
      // Check cache first
      final cachedResponse = _getCachedResponse<Map<String, dynamic>>(cacheKey);
      if (cachedResponse != null) {
        _loggingService.debug('Using cached response for prompt hash: ${promptStr.hashCode}', tag: 'GeminiService');
        return cachedResponse;
      }
      
      final response = await _gemini.prompt(
        parts: [gemini.Part.text(promptStr)],
      );

      final output = response?.output;
      if (output == null) {
        return {};
      }

      try {
        final parsedResponse = jsonDecode(output) as Map<String, dynamic>;
        // Cache the successful response
        _cacheResponse(cacheKey, parsedResponse);
        return parsedResponse;
      } catch (e) {
        _loggingService.warning('Error parsing JSON response: $e', tag: 'GeminiService');
        // Try to extract JSON from the response
        final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonPattern.firstMatch(output);
        
        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            try {
              final parsedResponse = jsonDecode(jsonStr) as Map<String, dynamic>;
              // Cache the successfully extracted response
              _cacheResponse(cacheKey, parsedResponse);
              return parsedResponse;
            } catch (e) {
              _loggingService.error('Error parsing extracted JSON: $e', tag: 'GeminiService');
            }
          }
        }
        
        return {};
      }
    } catch (e) {
      _loggingService.error('Error generating response: $e', tag: 'GeminiService');
      return {};
    }
  }
  
  /// Enhance a pattern with AI-generated improvements
  /// 
  /// This method takes a pattern JSON and suggests improvements or enhancements.
  Future<Map<String, dynamic>> enhancePattern(Map<String, dynamic> patternJson) async {
    try {
      // Create a cache key based on the pattern hash
      final cacheKey = 'enhance_pattern_${patternJson.hashCode}';
      
      // Check cache first
      final cachedResult = _getCachedResponse<Map<String, dynamic>>(cacheKey);
      if (cachedResult != null) {
        return cachedResult;
      }
      
      final result = await _generateResponse(patternJson);
      
      if (result.isNotEmpty) {
        // Cache the result
        _cacheResponse(cacheKey, result);
        return result;
      }
      
      return patternJson;
    } catch (e) {
      _loggingService.error('Error enhancing pattern: $e', tag: 'GeminiService');
      return patternJson;
    }
  }
  
  /// Clear all cached responses
  /// 
  /// This method clears the in-memory cache and can be used when
  /// fresh responses are needed or to free up memory.
  void clearCache() {
    _responseCache.clear();
    _loggingService.info('Cache cleared', tag: 'GeminiService');
  }

  /// Generate a description of a pattern from blocks
  /// 
  /// This is a helper method for creating a text description of a pattern.
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
        buffer.writeln('- ${_capitalize(type)}: $value');
      } else if (type == 'repeats') {
        buffer.writeln('- Repetitions: $value');
      }
    }
    
    return buffer.toString();
  }

  /// Helper method to capitalize a string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }

  /// Parse the analysis response from Gemini
  /// 
  /// This is a helper method for extracting structured data from the response.
  Map<String, dynamic> _parseAnalysisResponse(String response) {
    try {
      // Clean the response string to ensure it's valid JSON
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(response);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          return Map<String, dynamic>.from(
            jsonDecode(jsonStr) as Map<String, dynamic>
          );
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        return Map<String, dynamic>.from(
          jsonDecode(response) as Map<String, dynamic>
        );
      } catch (_) {
        _loggingService.warning('Failed to parse analysis response', tag: 'GeminiService');
        return _generateFallbackAnalysis([], PatternDifficulty.basic);
      }
    } catch (e) {
      _loggingService.error('Error parsing analysis response: $e', tag: 'GeminiService');
      return _generateFallbackAnalysis([], PatternDifficulty.basic);
    }
  }

  /// Parse cultural context response into a structured map
  Map<String, dynamic> _parseCulturalContextResponse(String responseText) {
    try {
      // Extract the JSON content from the response
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          return Map<String, dynamic>.from(
            jsonDecode(jsonStr) as Map<String, dynamic>
          );
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        return Map<String, dynamic>.from(
          jsonDecode(responseText) as Map<String, dynamic>
        );
      } catch (_) {
        _loggingService.warning('Failed to parse cultural context response', tag: 'GeminiService');
        return _generateFallbackCulturalContext('', '');
      }
    } catch (e) {
      _loggingService.error('Error parsing cultural context response: $e', tag: 'GeminiService');
      return _generateFallbackCulturalContext('', '');
    }
  }

  /// Generate a code hint based on the player's code and difficulty level
  Future<String> generateCodeHint({
    required String code,
    required PatternDifficulty difficulty,
  }) async {
    try {
      final prompt = '''
      Analyze this code for a Kente pattern and provide a helpful hint:
      
      Code:
      $code
      
      Difficulty: ${difficulty.toString().split('.').last}
      
      Provide a concise, encouraging hint that guides the user without giving away the solution.
      The hint should be appropriate for a 9-12 year old.
      ''';
      
      return await generateText(prompt);
    } catch (e) {
      _loggingService.log('Failed to generate code hint: $e');
      return "Try experimenting with different patterns and colors!";
    }
  }
  
  /// Generate a code explanation
  Future<String> generateCodeExplanation(String code) async {
    try {
      final prompt = '''
      Explain this code for a Kente pattern in simple terms:
      
      Code:
      $code
      
      Provide a clear explanation that a 9-12 year old would understand.
      Focus on what the code does and how it creates a pattern.
      ''';
      
      return await generateText(prompt);
    } catch (e) {
      _loggingService.log('Failed to generate code explanation: $e');
      return "This code creates a pattern using colors and shapes.";
    }
  }
  
  /// Generate a story node
  Future<String> generateStoryNode(String prompt) async {
    try {
      return await generateText(prompt);
    } catch (e) {
      _loggingService.log('Failed to generate story node: $e');
      return '{"id":"fallback","title":"The Journey Begins","content":"Let\'s start our adventure!","chapter":"introduction","nextNodes":{"continue":"next"}}';
    }
  }
  
  /// Generate a complete story
  Future<String> generateStory(String prompt) async {
    try {
      return await generateText(prompt);
    } catch (e) {
      _loggingService.log('Failed to generate story: $e');
      return '{"id":"fallback","title":"Coding Adventure","description":"A journey into coding","difficulty":"basic","nodes":[{"id":"start","title":"Beginning","content":"Let\'s start!","chapter":"introduction","nextNodes":{"continue":"end"}},{"id":"end","title":"The End","content":"Well done!","chapter":"introduction","nextNodes":{}}],"startNodeId":"start"}';
    }
  }
  
  /// Generate a learning path based on user's progress
  Future<Map<String, dynamic>> generateLearningPath({
    required Map<String, double> conceptMastery,
    required PatternDifficulty difficulty,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final prompt = '''
      Generate a personalized learning path based on the following information:
      
      Concept Mastery:
      ${jsonEncode(conceptMastery)}
      
      Difficulty Level:
      ${difficulty.toString().split('.').last}
      
      User Preferences:
      ${jsonEncode(preferences)}
      
      Return a JSON object with a 'path' array containing concept IDs in the recommended order.
      ''';
      
      final response = await generateText(prompt);
      return jsonDecode(response);
    } catch (e) {
      _loggingService.log('Failed to generate learning path: $e');
      return {
        'path': ['sequences', 'loops', 'conditions'],
      };
    }
  }
  
  /// Generate a challenge based on concept and difficulty
  Future<Map<String, dynamic>> generateChallenge({
    required String conceptId,
    required PatternDifficulty difficulty,
    required double masteryLevel,
    Map<String, dynamic>? context,
  }) async {
    try {
      final difficultyStr = difficulty.toString().split('.').last;
      final contextStr = context != null ? jsonEncode(context) : '{}';
      
      final prompt = '''
      Generate a coding challenge for the Kente Codeweaver app with the following parameters:
      
      Concept: $conceptId
      Difficulty: $difficultyStr
      User Mastery Level: $masteryLevel
      Context: $contextStr
      
      The challenge should be appropriate for a 9-12 year old learning to code through Kente patterns.
      
      Return a JSON object with the following structure:
      {
        "id": "unique_challenge_id",
        "title": "Challenge title",
        "description": "Challenge description",
        "conceptId": "$conceptId",
        "difficulty": "$difficultyStr",
        "requirements": ["requirement1", "requirement2"],
        "availableBlocks": ["block1", "block2"],
        "sampleSolution": "optional sample solution",
        "hints": ["hint1", "hint2"]
      }
      ''';
      
      final response = await generateText(prompt);
      return jsonDecode(response);
    } catch (e) {
      _loggingService.log('Failed to generate challenge: $e');
      return {
        'id': 'fallback_${conceptId}_${difficulty.toString().split('.').last}',
        'title': 'Pattern Challenge',
        'description': 'Create a pattern using the available blocks.',
        'conceptId': conceptId,
        'difficulty': difficulty.toString().split('.').last,
        'requirements': [
          'Use at least one loop',
          'Include color variation',
        ],
        'availableBlocks': [
          'loop',
          'color',
          'condition',
        ],
        'hints': [
          'Start by creating a loop to repeat your pattern.',
          'Add conditions to create variation in your pattern.',
        ],
      };
    }
  }
  
  /// Validate a challenge solution
  Future<Map<String, dynamic>> validateChallengeSolution({
    required String challengeId,
    required BlockCollection blocks,
    required PatternDifficulty difficulty,
  }) async {
    try {
      final prompt = '''
      Validate this solution for challenge $challengeId:
      
      Blocks:
      ${jsonEncode(blocks)}
      
      Difficulty: ${difficulty.toString().split('.').last}
      
      Return a JSON object with the following structure:
      {
        "success": true/false,
        "feedback": "Feedback message",
        "performance": 0.0-1.0,
        "conceptId": "concept_id",
        "hints": ["hint1", "hint2"]
      }
      ''';
      
      final response = await generateText(prompt);
      return jsonDecode(response);
    } catch (e) {
      _loggingService.log('Failed to validate challenge solution: $e');
      return {
        'success': false,
        'feedback': 'Unable to validate your solution at this time. Please try again later.',
        'performance': 0.5,
        'conceptId': challengeId.split('_')[0],
        'hints': ['Check your internet connection.'],
      };
    }
  }
  
  /// Generate a hint for a challenge
  Future<String> generateChallengeHint({
    required String challengeId,
    required BlockCollection blocks,
    required PatternDifficulty difficulty,
    required int hintLevel,
  }) async {
    try {
      final prompt = '''
      Generate a hint for challenge $challengeId:
      
      Blocks:
      ${jsonEncode(blocks)}
      
      Difficulty: ${difficulty.toString().split('.').last}
      Hint Level: $hintLevel (1=subtle, 3=more direct)
      
      Provide a helpful hint that is appropriate for the hint level.
      The hint should guide the user without giving away the complete solution.
      ''';
      
      return await generateText(prompt);
    } catch (e) {
      _loggingService.log('Failed to generate challenge hint: $e');
      switch (hintLevel) {
        case 1:
          return 'Try using a loop to create a repeating pattern.';
        case 2:
          return 'Add a condition inside your loop to create variation.';
        case 3:
          return 'Use different colors to make your pattern more interesting.';
        default:
          return 'Experiment with different combinations of blocks to solve the challenge.';
      }
    }
  }
}
