import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/lesson_model.dart';
import '../models/story_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/storage_service.dart';

/// Service for generating and managing story content using Google's Gemini API
class GeminiStoryService {
  /// The model name used for Gemini API
  static const String _modelName = 'gemini-pro';
  
  /// The Gemini model used for story generation
  late GenerativeModel _model;
  
  /// Singleton instance of the service
  static GeminiStoryService? _instance;
  
  /// Cache for story responses to reduce API calls
  final Map<String, dynamic> _responseCache = {};
  
  /// Keys for the shared preferences storage
  static const String _storyStepsCachePrefix = 'story_steps_cache_';
  static const String _storyModelCachePrefix = 'story_model_cache_';
  static const String _lastCacheTimePrefix = 'last_cache_time_';
  
  /// Cache expiration time (24 hours in milliseconds)
  static const int _cacheExpirationTime = 24 * 60 * 60 * 1000;
  
  /// Optional storage service for more advanced caching
  StorageService? _storageService;
  
  /// Private constructor to enforce the singleton pattern
  GeminiStoryService._();
  
  /// Gets the singleton instance of the GeminiStoryService
  /// 
  /// This method initializes the service with the provided model or gets it from the current instance
  static Future<GeminiStoryService> getInstance({StorageService? storageService}) async {
    if (_instance == null) {
      _instance = GeminiStoryService._();
      await _instance!._initializeModel();
      _instance!._storageService = storageService;
    }
    return _instance!;
  }
  
  /// Initialize the Gemini model with API key from environment
  Future<void> _initializeModel() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('Gemini API key not found in .env file');
    }
    _model = GenerativeModel(model: _modelName, apiKey: apiKey);
  }
  
  /// Generates story steps based on the lesson model and additional parameters
  /// 
  /// [lesson] The lesson model containing basic information
  /// [language] The language code for the generated content (e.g., 'en', 'fr')
  /// [stepsCount] The number of story steps to generate
  /// [previousChoices] Optional list of previous user choices for adaptive stories
  Future<List<Map<String, dynamic>>> generateStorySteps({
    required LessonModel lesson,
    required String language,
    int stepsCount = 5,
    List<Map<String, dynamic>>? previousChoices,
  }) async {
    // Create a cache key based on parameters
    final cacheKey = _createCacheKey(
      lesson.id,
      language,
      stepsCount,
      previousChoices,
    );
    
    // Check cache first to reduce API calls
    final cachedSteps = await _getCachedStorySteps(cacheKey);
    if (cachedSteps != null) {
      return cachedSteps;
    }
    
    // Build the prompt for the Gemini model
    final prompt = _buildStoryStepsPrompt(
      lesson: lesson,
      language: language,
      stepsCount: stepsCount,
      previousChoices: previousChoices,
    );
    
    try {
      // Generate content from the model
      final contents = [Content.text(prompt)];
      final response = await _model.generateContent(contents);
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      
      // Parse the response to story steps
      final storySteps = _parseStoryStepsResponse(responseText);
      
      // Cache the result
      await _cacheStorySteps(cacheKey, storySteps);
      
      return storySteps;
    } catch (e) {
      debugPrint('Error generating story steps: $e');
      // Return fallback content in case of error
      return _generateFallbackStorySteps(lesson, stepsCount);
    }
  }
  
  /// Generate a complete adaptive story with multiple nodes and choice paths
  Future<StoryModel> generateAdaptiveStory({
    required String storyTemplateId,
    required PatternDifficulty difficulty,
    required List<String> targetConcepts,
    List<Map<String, dynamic>>? previousChoices,
    Map<String, dynamic>? userProgress,
    String language = 'en',
  }) async {
    // Create a cache key based on parameters
    final cacheKey = _createCacheKey(
      storyTemplateId,
      language,
      difficulty.index,
      targetConcepts,
      previousChoices,
      userProgress,
    );
    
    // Check cache first to reduce API calls
    final cachedStory = await _getCachedStoryModel(cacheKey);
    if (cachedStory != null) {
      return cachedStory;
    }
    
    // Build the prompt for the Gemini model
    final prompt = _buildStoryPrompt(
      storyTemplateId: storyTemplateId,
      difficulty: difficulty,
      targetConcepts: targetConcepts,
      previousChoices: previousChoices,
      userProgress: userProgress,
      language: language,
    );
    
    try {
      // Generate content from the model
      final contents = [Content.text(prompt)];
      final response = await _model.generateContent(contents);
      
      // Parse the response to StoryModel
      final storyModel = _parseStoryResponse(response.text ?? '', difficulty);
      
      // Cache the result
      await _cacheStoryModel(cacheKey, storyModel);
      
      return storyModel;
    } catch (e) {
      debugPrint('Error generating adaptive story: $e');
      // Return fallback story in case of error
      return _generateFallbackStory(storyTemplateId, difficulty, targetConcepts, language);
    }
  }
  
  /// Generate cultural context information for a specific pattern or concept
  Future<Map<String, dynamic>> generateCulturalContext({
    required String patternId,
    String language = 'en',
    bool includeColorMeanings = true,
    bool includeHistoricalContext = true,
  }) async {
    // Create a cache key based on parameters
    final cacheKey = 'cultural_context_${patternId}_${language}_$includeColorMeanings\_$includeHistoricalContext';
    
    // Check cache first to reduce API calls
    final cachedContext = _responseCache[cacheKey];
    if (cachedContext != null) {
      return cachedContext;
    }
    
    // Build the prompt for the Gemini model
    final prompt = _buildCulturalContextPrompt(
      patternId: patternId,
      language: language,
      includeColorMeanings: includeColorMeanings,
      includeHistoricalContext: includeHistoricalContext,
    );
    
    try {
      // Generate content from the model
      final contents = [Content.text(prompt)];
      final response = await _model.generateContent(contents);
      
      // Parse the response to a context object
      final contextData = _parseCulturalContextResponse(response.text ?? '');
      
      // Cache the result
      _responseCache[cacheKey] = contextData;
      
      return contextData;
    } catch (e) {
      debugPrint('Error generating cultural context: $e');
      // Return fallback cultural context in case of error
      return _generateFallbackCulturalContext(patternId, language);
    }
  }
  
  /// Generates challenge content based on difficulty and concepts
  Future<Map<String, dynamic>> generateChallenge({
    required PatternDifficulty difficulty,
    required List<String> concepts,
    String language = 'en',
  }) async {
    // Create a cache key based on parameters
    final cacheKey = 'challenge_${difficulty.toString()}_${concepts.join('_')}_$language';
    
    // Check cache first to reduce API calls
    final cachedChallenge = _responseCache[cacheKey];
    if (cachedChallenge != null) {
      return cachedChallenge;
    }
    
    // Build the prompt for the Gemini model
    final prompt = _buildChallengePrompt(
      difficulty: difficulty,
      concepts: concepts,
      language: language,
    );
    
    try {
      // Generate content from the model
      final contents = [Content.text(prompt)];
      final response = await _model.generateContent(contents);
      
      // Parse the response to a challenge object
      final challengeData = _parseChallengeResponse(response.text ?? '');
      
      // Cache the result
      _responseCache[cacheKey] = challengeData;
      
      return challengeData;
    } catch (e) {
      debugPrint('Error generating challenge: $e');
      // Return fallback challenge in case of error
      return _generateFallbackChallenge(difficulty, concepts, language);
    }
  }
  
  /// Translates story content to the specified language
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
      debugPrint('Error translating content: $e');
      return content;
    }
  }
  
  /// Builds a prompt for generating story steps based on lesson and parameters
  String _buildStoryStepsPrompt({
    required LessonModel lesson,
    required String language,
    required int stepsCount,
    List<Map<String, dynamic>>? previousChoices,
  }) {
    // Build difficulty-specific part of the prompt
    String difficultyGuidance = '';
    switch (lesson.difficulty) {
      case PatternDifficulty.basic:
        difficultyGuidance = '''
        - Make the story suitable for ages 7-8
        - Keep language simple and sentences short
        - Focus on concrete, visual descriptions
        - Include frequent encouragement and guidance
        - Ensure 70% narrative content, 30% interactive challenge content
        - Add a simple cultural context about Kente patterns
        ''';
        break;
      case PatternDifficulty.intermediate:
        difficultyGuidance = '''
        - Make the story suitable for ages 8-10
        - Use moderate vocabulary and sentence complexity
        - Include some abstract concepts with concrete examples
        - Balance guidance with discovery opportunities
        - Ensure 60% narrative content, 40% interactive challenge content
        - Add cultural context about pattern significance and color meanings
        ''';
        break;
      case PatternDifficulty.advanced:
        difficultyGuidance = '''
        - Make the story suitable for ages 10-11
        - Use richer vocabulary and more complex sentences
        - Present abstract concepts and encourage critical thinking
        - Provide minimal guidance, allowing for exploration
        - Ensure 50% narrative content, 50% interactive challenge content
        - Add deep cultural context including historical significance
        ''';
        break;
      case PatternDifficulty.master:
        difficultyGuidance = '''
        - Make the story suitable for ages 11-12
        - Use sophisticated vocabulary and complex sentence structures
        - Focus on conceptual understanding and creative applications
        - Provide challenges with minimal guidance
        - Ensure 40% narrative content, 60% interactive challenge content
        - Include comprehensive cultural, historical, and philosophical context
        ''';
        break;
    }
    
    // Add information about previous choices if available
    String choicesContext = '';
    if (previousChoices != null && previousChoices.isNotEmpty) {
      choicesContext = 'Previous user choices:\n';
      for (final choice in previousChoices) {
        choicesContext += '- In "${choice['stepId']}", chose: "${choice['choice']}"\n';
      }
    }
    
    // Extract lesson concepts if available
    String conceptsText = '';
    if (lesson.content.containsKey('concepts') && lesson.content['concepts'] is List) {
      conceptsText = (lesson.content['concepts'] as List).join(', ');
    } else if (lesson.skills.isNotEmpty) {
      conceptsText = lesson.skills.join(', ');
    } else {
      conceptsText = 'Sequences, patterns, basic commands';
    }
    
    // Main prompt construction
    return '''
    You are a cultural education AI specializing in Ghanaian Kente weaving traditions and coding education.
    Create a structured story for a learning module with the following details:
    
    Title: ${lesson.title}
    Description: ${lesson.description}
    Difficulty: ${lesson.difficulty.toString().split('.').last}
    Coding concepts: $conceptsText
    
    Please generate a story with $stepsCount steps that teaches these concepts through a narrative about Kente weaving.
    
    $difficultyGuidance
    
    $choicesContext
    
    The story should feature these characters:
    - Kwaku: A 9-10 year old Ghanaian boy who is learning to code using traditional Kente patterns
    - Nana Yaw: Kwaku's grandfather and a master Kente weaver who shares traditional knowledge
    - Auntie Efua: Kwaku's computer science teacher who helps connect tradition to modern coding
    - Ama: Kwaku's friend who collaborates on projects
    
    For each story step, return a JSON object with the following structure:
    ```json
    [
      {
        "title": "Step title",
        "content": "Main story content",
        "image": "Description of an appropriate image",
        "contentBlocks": [
          {
            "type": "narration|dialogue|description|cultural_context",
            "text": "Text content for this block",
            "speaker": "Character name if type is dialogue" 
          }
        ],
        "hasChoice": true|false,
        "choices": [
          {
            "text": "Choice text",
            "nextStep": step_index
          }
        ],
        "challenge": {
          "title": "Challenge title",
          "description": "Challenge description",
          "type": "pattern_creation|quiz|matching",
          "difficulty": "basic|intermediate|advanced|master"
        },
        "culturalContext": {
          "title": "Context title",
          "description": "Cultural context about the pattern or concept"
        }
      }
    ]
    ```
    
    Output language: $language
    
    Important guidelines:
    - Ensure the story flows naturally and is engaging for children
    - Include cultural context that connects coding concepts to Kente traditions
    - Make at least one step include a coding challenge
    - Include 2-3 choice points where appropriate
    - End with a sense of accomplishment
    - Return ONLY the JSON array with the story steps, no additional explanation
    ''';
  }
  
  /// Parses the raw text response from Gemini into structured story steps
  List<Map<String, dynamic>> _parseStoryStepsResponse(String responseText) {
    try {
      // Extract the JSON content from the response
      final jsonPattern = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final List<dynamic> parsedData = jsonDecode(jsonStr);
          return parsedData.map((data) => data as Map<String, dynamic>).toList();
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        final List<dynamic> parsedData = jsonDecode(responseText);
        return parsedData.map((data) => data as Map<String, dynamic>).toList();
      } catch (_) {
        // If all parsing attempts fail, log and return empty list
        debugPrint('Failed to parse story steps response');
        return [];
      }
    } catch (e) {
      debugPrint('Error parsing story steps response: $e');
      return [];
    }
  }
  
  /// Builds a comprehensive prompt for generating an adaptive story
  String _buildStoryPrompt({
    required String storyTemplateId,
    required PatternDifficulty difficulty,
    required List<String> targetConcepts,
    List<Map<String, dynamic>>? previousChoices,
    Map<String, dynamic>? userProgress,
    String language = 'en',
  }) {
    // Build difficulty-specific instructions
    String difficultyGuidance = '';
    int minNodes = 5;
    int minChoices = 2;
    int challengeRatio = 0;
    
    switch (difficulty) {
      case PatternDifficulty.basic:
        difficultyGuidance = '''
        - Design for ages 7-8, with simple language and concepts
        - Focus on basic pattern creation and sequencing
        - Provide detailed step-by-step guidance
        - Include frequent encouragement and positive reinforcement
        - Use concrete examples and visual descriptions
        - Make challenges achievable with clear instructions
        ''';
        minNodes = 5;
        minChoices = 2;
        challengeRatio = 30;
        break;
      case PatternDifficulty.intermediate:
        difficultyGuidance = '''
        - Design for ages 8-10, with moderate vocabulary and concepts
        - Focus on loops, variables, and pattern combinations
        - Balance guidance with opportunities for discovery
        - Include analogies that connect coding to weaving
        - Introduce more complex cultural context
        - Include challenges that require some problem-solving
        ''';
        minNodes = 7;
        minChoices = 3;
        challengeRatio = 40;
        break;
      case PatternDifficulty.advanced:
        difficultyGuidance = '''
        - Design for ages 10-11, with rich vocabulary and concepts
        - Focus on nested loops, functions, and optimization
        - Provide minimal guidance, encouraging exploration
        - Include historical context and deeper cultural significance
        - Present challenges that require critical thinking
        - Add debugging scenarios and multiple solution paths
        ''';
        minNodes = 9;
        minChoices = 4;
        challengeRatio = 50;
        break;
      case PatternDifficulty.master:
        difficultyGuidance = '''
        - Design for ages 11-12, with sophisticated language and concepts
        - Focus on algorithms, complex logic, and pattern creation
        - Create open-ended challenges with minimal guidance
        - Include philosophical aspects of pattern design
        - Present complex problems with multiple valid approaches
        - Challenge students to create original patterns with cultural meaning
        ''';
        minNodes = 12;
        minChoices = 5;
        challengeRatio = 60;
        break;
    }
    
    // Add information about previous choices if available
    String choicesContext = '';
    if (previousChoices != null && previousChoices.isNotEmpty) {
      choicesContext = 'Previous user choices:\n';
      for (final choice in previousChoices) {
        choicesContext += '- In "${choice['nodeId'] ?? choice['stepId']}", chose: "${choice['choiceText'] ?? choice['choice']}"\n';
      }
    }
    
    // Add user progress information if available
    String progressContext = '';
    if (userProgress != null && userProgress.isNotEmpty) {
      progressContext = 'User progress information:\n';
      
      if (userProgress.containsKey('masteredConcepts')) {
        final concepts = userProgress['masteredConcepts'] as List<dynamic>;
        progressContext += '- Mastered concepts: ${concepts.join(', ')}\n';
      }
      
      if (userProgress.containsKey('completedStories')) {
        final stories = userProgress['completedStories'] as List<dynamic>;
        progressContext += '- Completed stories: ${stories.join(', ')}\n';
      }
      
      if (userProgress.containsKey('userLevel')) {
        progressContext += '- Current user level: ${userProgress['userLevel']}\n';
      }
    }
    
    // Main prompt construction with StoryModel structure
    return '''
    You are a cultural education AI specializing in Ghanaian Kente weaving traditions and coding education.
    Create a comprehensive adaptive story based on template ID: $storyTemplateId
    
    Story difficulty: ${difficulty.toString().split('.').last}
    Target concepts to teach: ${targetConcepts.join(', ')}
    
    $difficultyGuidance
    
    $choicesContext
    
    $progressContext
    
    Create a complete story with at least $minNodes nodes, including at least $minChoices choice points.
    Approximately $challengeRatio% of the story should involve interactive challenges.
    
    The story should feature these characters:
    - Kwaku: A 9-10 year old Ghanaian boy who is learning to code using traditional Kente patterns
    - Nana Yaw: Kwaku's grandfather and a master Kente weaver who shares traditional knowledge
    - Auntie Efua: Kwaku's computer science teacher who helps connect tradition to modern coding
    - Ama: Kwaku's friend who collaborates on projects
    
    Return a complete StoryModel in JSON format with the following structure:
    ```json
    {
      "id": "unique_story_id",
      "title": "Story title",
      "description": "Story description",
      "difficulty": "${difficulty.toString().split('.').last}",
      "learningConcepts": ["concept1", "concept2"],
      "startNodeId": "start_node_id",
      "nodes": {
        "node_id_1": {
          "id": "node_id_1",
          "title": "Node title",
          "content": "Main story content",
          "contentBlocks": [
            {
              "id": "block_1",
              "type": "narration",
              "text": "Text content",
              "speaker": null
            },
            {
              "id": "block_2",
              "type": "dialogue",
              "text": "Text content",
              "speaker": "Character name"
            }
          ],
          "choices": [
            {
              "id": "choice_id",
              "text": "Choice text",
              "targetNodeId": "node_id_to_navigate_to"
            }
          ],
          "challenge": {
            "id": "challenge_id",
            "title": "Challenge title",
            "description": "Challenge description",
            "type": "blockArrangement",
            "difficulty": "${difficulty.toString().split('.').last}",
            "conceptsTaught": ["concept1"],
            "parameters": {},
            "hints": ["Hint 1", "Hint 2"]
          },
          "chapter": "introduction",
          "culturalContextData": {
            "title": "Context title",
            "description": "Cultural context description"
          },
          "nextNodes": {},
          "conceptsTaught": ["concept1", "concept2"]
        }
      },
      "challenges": [],
      "metadata": {
        "author": "Gemini AI",
        "version": "1.0",
        "recommendations": ["related_story_1", "related_story_2"]
      }
    }
    ```
    
    Output language: $language
    
    Important guidelines:
    - Ensure the story flows naturally and is engaging for children
    - Include rich cultural context that connects coding concepts to Kente traditions
    - Make choices meaningful and affect the story progression
    - Include multiple paths through the story with different outcomes
    - Ensure all challenges are age-appropriate and reinforce the target concepts
    - Return ONLY the JSON StoryModel, no additional explanation
    ''';
  }
  
  /// Parses the raw response text into a StoryModel
  StoryModel _parseStoryResponse(String responseText, PatternDifficulty difficulty) {
    try {
      // Extract the JSON content from the response
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final Map<String, dynamic> storyData = jsonDecode(jsonStr);
          return StoryModel.fromJson(storyData);
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        final Map<String, dynamic> storyData = jsonDecode(responseText);
        return StoryModel.fromJson(storyData);
      } catch (_) {
        debugPrint('Failed to parse story response');
        return _generateFallbackStory('fallback_story', difficulty, ['sequence', 'pattern'], 'en');
      }
    } catch (e) {
      debugPrint('Error parsing story response: $e');
      return _generateFallbackStory('fallback_story', difficulty, ['sequence', 'pattern'], 'en');
    }
  }
  
  /// Builds a prompt for generating cultural context information
  String _buildCulturalContextPrompt({
    required String patternId,
    required String language,
    required bool includeColorMeanings,
    required bool includeHistoricalContext,
  }) {
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
    
    return '''
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
  }
  
  /// Parses cultural context response into a structured map
  Map<String, dynamic> _parseCulturalContextResponse(String responseText) {
    try {
      // Extract the JSON content from the response
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final Map<String, dynamic> contextData = jsonDecode(jsonStr);
          return contextData;
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        final Map<String, dynamic> contextData = jsonDecode(responseText);
        return contextData;
      } catch (_) {
        // If all parsing attempts fail, log and return default data
        debugPrint('Failed to parse cultural context response');
        return {
          'title': 'Kente Pattern Information',
          'description': 'This pattern is part of the rich Kente weaving tradition.',
        };
      }
    } catch (e) {
      debugPrint('Error parsing cultural context response: $e');
      return {
        'title': 'Kente Pattern Information',
        'description': 'This pattern is part of the rich Kente weaving tradition.',
      };
    }
  }
  
  /// Builds a prompt for generating a coding challenge
  String _buildChallengePrompt({
    required PatternDifficulty difficulty,
    required List<String> concepts,
    required String language,
  }) {
    String difficultyGuidance = '';
    switch (difficulty) {
      case PatternDifficulty.basic:
        difficultyGuidance = '''
        - Make the challenge suitable for ages 7-8
        - Focus on simple pattern recognition and sequencing
        - Provide clear, step-by-step instructions
        - Include 2-3 hints that are very helpful
        - Make success criteria very clear and achievable
        ''';
        break;
      case PatternDifficulty.intermediate:
        difficultyGuidance = '''
        - Make the challenge suitable for ages 8-10
        - Focus on pattern combinations and basic loops
        - Provide moderate guidance with some room for exploration
        - Include 2 hints that guide without giving away the answer
        - Allow for multiple similar solutions to be valid
        ''';
        break;
      case PatternDifficulty.advanced:
        difficultyGuidance = '''
        - Make the challenge suitable for ages 10-11
        - Focus on nested patterns and algorithmic thinking
        - Provide minimal guidance to promote problem-solving
        - Include 1-2 subtle hints that point in the right direction
        - Require optimization or efficiency in the solution
        ''';
        break;
      case PatternDifficulty.master:
        difficultyGuidance = '''
        - Make the challenge suitable for ages 11-12
        - Focus on complex algorithms and pattern creation
        - Provide only a goal with minimal guidance
        - Include at most 1 hint that is deliberately abstract
        - Require creative problem-solving and novel approaches
        ''';
        break;
    }
    
    return '''
    You are a coding education expert specializing in Kente weaving patterns and programming concepts.
    
    Create a coding challenge that teaches the following concepts through Kente pattern creation:
    ${concepts.join(', ')}
    
    Challenge difficulty: ${difficulty.toString().split('.').last}
    
    $difficultyGuidance
    
    Return your challenge in the following JSON format:
    ```json
    {
      "title": "Challenge title",
      "description": "Main challenge description",
      "objective": "Clear statement of what the user needs to achieve",
      "type": "blockArrangement|patternPrediction|codeOptimization|debugging|patternCreation",
      "difficulty": "${difficulty.toString().split('.').last}",
      "conceptsTaught": ["concept1", "concept2"],
      "requiredBlocks": ["block_id1", "block_id2"],
      "hints": ["Hint 1", "Hint 2"],
      "successCriteria": ["Criterion 1", "Criterion 2"],
      "culturalContext": {
        "title": "Cultural relevance title",
        "description": "How this challenge connects to Kente tradition"
      }
    }
    ```
    
    Output language: $language
    
    Return ONLY the JSON data, no additional explanation.
    ''';
  }
  
  /// Parses challenge response into a structured map
  Map<String, dynamic> _parseChallengeResponse(String responseText) {
    try {
      // Extract the JSON content from the response
      final jsonPattern = RegExp(r'\{.*\}', dotAll: true);
      final match = jsonPattern.firstMatch(responseText);
      
      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final Map<String, dynamic> challengeData = jsonDecode(jsonStr);
          return challengeData;
        }
      }
      
      // Try to parse the entire text if the regex approach fails
      try {
        final Map<String, dynamic> challengeData = jsonDecode(responseText);
        return challengeData;
      } catch (_) {
        // If all parsing attempts fail, log and return default data
        debugPrint('Failed to parse challenge response');
        return {
          'title': 'Pattern Challenge',
          'description': 'Create a pattern using coding blocks.',
          'type': 'patternCreation',
          'difficulty': 'basic',
        };
      }
    } catch (e) {
      debugPrint('Error parsing challenge response: $e');
      return {
        'title': 'Pattern Challenge',
        'description': 'Create a pattern using coding blocks.',
        'type': 'patternCreation',
        'difficulty': 'basic',
      };
    }
  }
  
  /// Creates a deterministic cache key from various parameters
  String _createCacheKey(dynamic primary, [dynamic secondary, dynamic tertiary, dynamic quaternary, dynamic quinary, dynamic senary]) {
    final buffer = StringBuffer();
    
    // Add all non-null parameters to the buffer
    buffer.write(primary.toString());
    
    if (secondary != null) {
      buffer.write('_');
      buffer.write(secondary.toString());
    }
    
    if (tertiary != null) {
      buffer.write('_');
      if (tertiary is List) {
        buffer.write(tertiary.join('|'));
      } else {
        buffer.write(tertiary.toString());
      }
    }
    
    if (quaternary != null) {
      buffer.write('_');
      if (quaternary is List) {
        buffer.write(quaternary.map((item) => item.toString()).join('|'));
      } else if (quaternary is Map) {
        buffer.write(quaternary.keys.join('|'));
      } else {
        buffer.write(quaternary.toString());
      }
    }
    
    if (quinary != null) {
      buffer.write('_');
      if (quinary is Map) {
        buffer.write(quinary.keys.join('|'));
      } else {
        buffer.write(quinary.toString());
      }
    }
    
    if (senary != null) {
      buffer.write('_');
      buffer.write(senary.toString());
    }
    
    // Create a hash of the buffer content to ensure reasonable key length
    return buffer.toString().hashCode.toString();
  }
  
  /// Retrieves cached story steps if they exist and are not expired
  Future<List<Map<String, dynamic>>?> _getCachedStorySteps(String cacheKey) async {
    try {
      // Check in-memory cache first
      if (_responseCache.containsKey(cacheKey)) {
        return _responseCache[cacheKey] as List<Map<String, dynamic>>;
      }
      
      // Check if we have a storage service
      if (_storageService != null) {
        final cachedJson = await _storageService!.read('$_storyStepsCachePrefix$cacheKey');
        final lastCacheTimeStr = await _storageService!.read('$_lastCacheTimePrefix$cacheKey');
        
        if (cachedJson != null && lastCacheTimeStr != null) {
          final lastCacheTime = int.parse(lastCacheTimeStr);
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          
          // Check if cache is expired
          if (currentTime - lastCacheTime <= _cacheExpirationTime) {
            // Parse the cached data
            final List<dynamic> parsedData = jsonDecode(cachedJson);
            final storySteps = parsedData.map((data) => data as Map<String, dynamic>).toList();
            
            // Update in-memory cache
            _responseCache[cacheKey] = storySteps;
            return storySteps;
          }
        }
        return null;
      }
      
      // Fall back to SharedPreferences if no storage service
      final prefs = await SharedPreferences.getInstance();
      final lastCacheTimeStr = prefs.getString('$_lastCacheTimePrefix$cacheKey');
      
      // Skip if no cache time (never cached) or if cache is expired
      if (lastCacheTimeStr == null) {
        return null;
      }
      
      final lastCacheTime = int.parse(lastCacheTimeStr);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      if (currentTime - lastCacheTime > _cacheExpirationTime) {
        // Cache expired, clear it
        await prefs.remove('$_storyStepsCachePrefix$cacheKey');
        await prefs.remove('$_lastCacheTimePrefix$cacheKey');
        return null;
      }
      
      // Retrieve cached data
      final cachedJson = prefs.getString('$_storyStepsCachePrefix$cacheKey');
      if (cachedJson == null) {
        return null;
      }
      
      // Parse the cached data
      final List<dynamic> parsedData = jsonDecode(cachedJson);
      final storySteps = parsedData.map((data) => data as Map<String, dynamic>).toList();
      
      // Update in-memory cache
      _responseCache[cacheKey] = storySteps;
      
      return storySteps;
    } catch (e) {
      debugPrint('Error retrieving cached story steps: $e');
      return null;
    }
  }
  
  /// Caches story steps in both memory and persistent storage
  Future<void> _cacheStorySteps(String cacheKey, List<Map<String, dynamic>> storySteps) async {
    try {
      // Cache in memory
      _responseCache[cacheKey] = storySteps;
      
      // Convert to JSON string
      final jsonStr = jsonEncode(storySteps);
      final currentTime = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Check if we have a storage service
      if (_storageService != null) {
        await _storageService!.write('$_storyStepsCachePrefix$cacheKey', jsonStr);
        await _storageService!.write('$_lastCacheTimePrefix$cacheKey', currentTime);
        return;
      }
      
      // Cache in persistent storage if no storage service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_storyStepsCachePrefix$cacheKey', jsonStr);
      await prefs.setString('$_lastCacheTimePrefix$cacheKey', currentTime);
    } catch (e) {
      debugPrint('Error caching story steps: $e');
    }
  }
  
  /// Retrieves cached story model if it exists and is not expired
  Future<StoryModel?> _getCachedStoryModel(String cacheKey) async {
    try {
      // Check if we have a storage service
      if (_storageService != null) {
        final cachedJson = await _storageService!.read('$_storyModelCachePrefix$cacheKey');
        final lastCacheTimeStr = await _storageService!.read('$_lastCacheTimePrefix$cacheKey');
        
        if (cachedJson != null && lastCacheTimeStr != null) {
          final lastCacheTime = int.parse(lastCacheTimeStr);
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          
          // Check if cache is expired
          if (currentTime - lastCacheTime <= _cacheExpirationTime) {
            // Parse the cached data
            final Map<String, dynamic> storyData = jsonDecode(cachedJson);
            return StoryModel.fromJson(storyData);
          }
        }
        return null;
      }
      
      // Fall back to SharedPreferences if no storage service
      final prefs = await SharedPreferences.getInstance();
      final lastCacheTimeStr = prefs.getString('$_lastCacheTimePrefix$cacheKey');
      
      // Skip if no cache time (never cached) or if cache is expired
      if (lastCacheTimeStr == null) {
        return null;
      }
      
      final lastCacheTime = int.parse(lastCacheTimeStr);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is expired
      if (currentTime - lastCacheTime > _cacheExpirationTime) {
        // Cache expired, clear it
        await prefs.remove('$_storyModelCachePrefix$cacheKey');
        await prefs.remove('$_lastCacheTimePrefix$cacheKey');
        return null;
      }
      
      // Retrieve cached data
      final cachedJson = prefs.getString('$_storyModelCachePrefix$cacheKey');
      if (cachedJson == null) {
        return null;
      }
      
      // Parse the cached data
      final Map<String, dynamic> storyData = jsonDecode(cachedJson);
      return StoryModel.fromJson(storyData);
      
    } catch (e) {
      debugPrint('Error retrieving cached story model: $e');
      return null;
    }
  }
  
  /// Caches story model in persistent storage
  Future<void> _cacheStoryModel(String cacheKey, StoryModel storyModel) async {
    try {
      // Convert to JSON string
      final jsonStr = jsonEncode(storyModel.toJson());
      final currentTime = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Check if we have a storage service
      if (_storageService != null) {
        await _storageService!.write('$_storyModelCachePrefix$cacheKey', jsonStr);
        await _storageService!.write('$_lastCacheTimePrefix$cacheKey', currentTime);
        return;
      }
      
      // Cache in persistent storage if no storage service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_storyModelCachePrefix$cacheKey', jsonStr);
      await prefs.setString('$_lastCacheTimePrefix$cacheKey', currentTime);
    } catch (e) {
      debugPrint('Error caching story model: $e');
    }
  }
  
  /// Generates fallback story steps if API fails
  List<Map<String, dynamic>> _generateFallbackStorySteps(LessonModel lesson, int stepsCount) {
    // Basic fallback for any lesson
    return [
      {
        'title': 'Introduction to ${lesson.title}',
        'content': 'Kwaku Ananse welcomes you to learn about ${lesson.title} through the art of Kente weaving.',
        'image': 'introduction',
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'Welcome to our lesson on ${lesson.title}! Today we will learn how coding connects to the beautiful patterns of Kente cloth.',
            'speaker': 'Kwaku',
          }
        ],
        'hasChoice': false,
      },
      {
        'title': 'Understanding the Pattern',
        'content': 'Nana Yaw explains the significance of patterns in both Kente weaving and coding.',
        'image': 'cultural',
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'In Kente weaving, patterns represent our history and values. In coding, patterns help us organize instructions.',
            'speaker': 'Nana Yaw',
          }
        ],
        'hasChoice': true,
        'choices': [
          {'text': 'Tell me more about the cultural meaning', 'nextStep': 2},
          {'text': 'Let\'s start coding', 'nextStep': 3},
        ],
      },
      {
        'title': 'Cultural Significance',
        'content': 'Nana Yaw shares the deep cultural meaning behind the patterns.',
        'image': 'cultural',
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'Each pattern tells a story. The Dame-Dame checkerboard pattern represents strategic thinking and duality in life.',
            'speaker': 'Nana Yaw',
          }
        ],
        'hasChoice': true,
        'choices': [
          {'text': 'Now let\'s start coding', 'nextStep': 3},
        ],
        'culturalContext': {
          'title': 'Dame-Dame Pattern',
          'description': 'The Dame-Dame pattern represents the concept of duality - the balance between opposites that exists in all things.',
        },
      },
      {
        'title': 'Coding Challenge',
        'content': 'Auntie Efua presents a coding challenge related to the lesson.',
        'image': 'challenge',
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'Now it\'s time to create your own pattern using the concepts we\'ve learned!',
            'speaker': 'Auntie Efua',
          }
        ],
        'hasChoice': false,
        'challenge': {
          'title': 'Create Your Pattern',
          'description': 'Use the blocks to create a pattern based on what we\'ve learned.',
          'type': 'pattern_creation',
          'difficulty': lesson.difficulty.toString().split('.').last,
        },
      },
      {
        'title': 'Completion',
        'content': 'Congratulations on completing the lesson!',
        'image': 'completion',
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'Well done! You\'ve successfully connected coding concepts to Kente weaving traditions.',
            'speaker': 'Kwaku',
          }
        ],
        'hasChoice': false,
      },
    ].take(stepsCount).toList();
  }
  
  /// Generates a fallback story model if API fails
  StoryModel _generateFallbackStory(
    String storyTemplateId,
    PatternDifficulty difficulty,
    List<String> targetConcepts,
    String language,
  ) {
    // Create a basic story with a few nodes
    final startNodeId = '${storyTemplateId}_start';
    
    // Create a map of nodes
    final Map<String, StoryNode> nodes = {
      startNodeId: StoryNode(
        id: startNodeId,
        title: 'Beginning Your Journey',
        content: 'Kwaku welcomes you to learn about coding through Kente patterns.',
        chapter: StoryChapter.introduction,
        requiredPatterns: [],
        nextNodes: {},
        contentBlocks: [
          ContentBlock(
            id: 'block_1',
            type: ContentType.dialogue,
            text: 'Welcome to our Kente coding adventure!',
            speaker: 'Kwaku',
          ),
          ContentBlock(
            id: 'block_2',
            type: ContentType.narration,
            text: 'Today you will learn about ${targetConcepts.join(', ')} through the art of Kente weaving.',
          ),
        ],
        choices: [
          StoryChoice(
            id: 'choice_1',
            text: 'Learn about Kente patterns',
            targetNodeId: '${storyTemplateId}_cultural',
          ),
          StoryChoice(
            id: 'choice_2',
            text: 'Start the coding challenge',
            targetNodeId: '${storyTemplateId}_challenge',
          ),
        ],
      ),
      
      '${storyTemplateId}_cultural': StoryNode(
        id: '${storyTemplateId}_cultural',
        title: 'Understanding Kente Patterns',
        content: 'Nana Yaw explains the cultural significance of Kente patterns.',
        chapter: StoryChapter.introduction,
        requiredPatterns: [],
        nextNodes: {},
        contentBlocks: [
          ContentBlock(
            id: 'cultural_1',
            type: ContentType.dialogue,
            text: 'Kente patterns are not just beautiful designs. Each pattern tells a story about our history and values.',
            speaker: 'Nana Yaw',
          ),
        ],
        choices: [
          StoryChoice(
            id: 'cultural_next',
            text: 'Tell me more',
            targetNodeId: '${storyTemplateId}_cultural_detail',
          ),
        ],
        culturalContextData: {
          'title': 'Kente Patterns',
          'description': 'Kente cloth is rich with symbolism. Each pattern and color has significance in Ghanaian culture.',
        },
      ),
      
      '${storyTemplateId}_cultural_detail': StoryNode(
        id: '${storyTemplateId}_cultural_detail',
        title: 'The Language of Patterns',
        content: 'Nana Yaw shares more about how patterns communicate cultural values.',
        chapter: StoryChapter.introduction,
        requiredPatterns: [],
        nextNodes: {},
        contentBlocks: [
          ContentBlock(
            id: 'cultural_detail_1',
            type: ContentType.dialogue,
            text: 'The Dame-Dame pattern represents duality and strategy. The Nkyinkyim zigzag pattern represents life\'s journey with its twists and turns.',
            speaker: 'Nana Yaw',
          ),
        ],
        choices: [
          StoryChoice(
            id: 'to_challenge',
            text: 'I\'m ready for the challenge',
            targetNodeId: '${storyTemplateId}_challenge',
          ),
        ],
      ),
      
      '${storyTemplateId}_challenge': StoryNode(
        id: '${storyTemplateId}_challenge',
        title: 'The Coding Challenge',
        content: 'Auntie Efua presents you with a coding challenge.',
        chapter: StoryChapter.firstThread,
        requiredPatterns: [],
        nextNodes: {},
        contentBlocks: [
          ContentBlock(
            id: 'challenge_1',
            type: ContentType.dialogue,
            text: 'Now it\'s time to apply what you\'ve learned! Create a pattern using the coding blocks.',
            speaker: 'Auntie Efua',
          ),
        ],
        challenge: Challenge(
          id: '${storyTemplateId}_main_challenge',
          title: 'Create Your Pattern',
          description: 'Use the blocks to create a pattern based on what we\'ve learned.',
          type: ChallengeType.patternCreation,
          difficulty: difficulty,
          conceptsTaught: targetConcepts,
        ),
        choices: [
          StoryChoice(
            id: 'complete_challenge',
            text: 'Complete the challenge',
            targetNodeId: '${storyTemplateId}_completion',
          ),
        ],
      ),
      
      '${storyTemplateId}_completion': StoryNode(
        id: '${storyTemplateId}_completion',
        title: 'Well Done!',
        content: 'You have successfully completed the challenge.',
        chapter: StoryChapter.firstThread,
        requiredPatterns: [],
        nextNodes: {},
        contentBlocks: [
          ContentBlock(
            id: 'completion_1',
            type: ContentType.dialogue,
            text: 'Excellent work! You\'ve created a beautiful pattern and learned about ${targetConcepts.join(', ')}.',
            speaker: 'Kwaku',
          ),
          ContentBlock(
            id: 'completion_2',
            type: ContentType.narration,
            text: 'With your new skills, you can create many more patterns and continue your journey in coding.',
          ),
        ],
        choices: [],
      ),
    };
    
    // Create the story model
    return StoryModel(
      id: storyTemplateId,
      title: 'Learning Through Kente Patterns',
      description: 'An adventure in coding through traditional Kente patterns',
      difficulty: difficulty,
      learningConcepts: targetConcepts,
      startNode: nodes[startNodeId]!,
      nodes: nodes,
    );
  }
  
  /// Generates fallback cultural context information
  Map<String, dynamic> _generateFallbackCulturalContext(String patternId, String language) {
    // Map pattern ID to readable name
    final patterns = {
      'dame_dame': {
        'title': 'Dame-Dame Pattern',
        'description': 'The Dame-Dame (checkerboard) pattern represents duality and strategic thinking. It symbolizes the balance between opposites - light and dark, joy and sorrow, the seen and unseen.',
        'colorMeanings': {
          'black': 'Spiritual energy and maturity',
          'gold': 'Royalty, wealth, and high status',
        },
        'historicalContext': 'Dame-Dame is one of the oldest Kente patterns, dating back centuries in Ghanaian weaving traditions.',
      },
      'nkyinkyim': {
        'title': 'Nkyinkyim Pattern',
        'description': 'The Nkyinkyim (zigzag) pattern represents life\'s journey with its twists and turns. It symbolizes adaptability, resilience, and the non-linear nature of human experience.',
        'colorMeanings': {
          'blue': 'Peace, harmony, and love',
          'red': 'Political power, sacrifice, and spiritual significance',
        },
        'historicalContext': 'Nkyinkyim is inspired by the Adinkra symbol of the same name, representing the twisting nature of life\'s journey.',
      },
      'babadua': {
        'title': 'Babadua Pattern',
        'description': 'The Babadua (horizontal stripes) pattern symbolizes cooperation and unity. It represents the concept that many individual threads come together to create something stronger.',
        'colorMeanings': {
          'green': 'Growth, renewal, and fertility',
          'gold': 'Wealth and spiritual vitality',
        },
        'historicalContext': 'Babadua is a fundamental pattern in Kente weaving, reflecting the importance of community in Ghanaian culture.',
      },
    };
    
    // Find the matching pattern or use a default
    for (final key in patterns.keys) {
      if (patternId.contains(key)) {
        return patterns[key]!;
      }
    }
    
    // Default fallback
    return {
      'title': 'Kente Pattern',
      'description': 'This pattern is part of the rich Kente weaving tradition of Ghana. Kente patterns are not just decorative; they carry cultural meanings and stories.',
      'colorMeanings': {
        'gold': 'Royalty and wealth',
        'black': 'Maturity and spiritual energy',
        'red': 'Political and spiritual significance',
        'blue': 'Peace and harmony',
        'green': 'Growth and renewal',
      },
      'historicalContext': 'Kente cloth originated with the Ashanti people of Ghana and has become an important cultural symbol throughout West Africa and the African diaspora.',
    };
  }
  
  /// Generates a fallback challenge if API fails
  Map<String, dynamic> _generateFallbackChallenge(
    PatternDifficulty difficulty,
    List<String> concepts,
    String language,
  ) {
    // Basic challenge structure
    final challengeData = {
      'title': 'Pattern Creation Challenge',
      'description': 'Create a pattern using the coding blocks provided.',
      'objective': 'Combine blocks to create a meaningful pattern.',
      'type': 'patternCreation',
      'difficulty': difficulty.toString().split('.').last,
      'conceptsTaught': concepts,
      'hints': <String>[
        'Try connecting a pattern block with a color block first.',
        'Think about how the blocks can be combined to create a repeated pattern.',
      ],
      'successCriteria': <String>[
        'Pattern should include at least one pattern block and one color block.',
        'Pattern should demonstrate understanding of the target concepts.',
      ],
      'culturalContext': {
        'title': 'Kente Patterns',
        'description': 'In Kente weaving, patterns are combined to tell stories and express cultural values.',
      },
    };
    
    // Add difficulty-specific content
    switch (difficulty) {
      case PatternDifficulty.basic:
        challengeData['requiredBlocks'] = ['checker_pattern', 'shuttle_black', 'shuttle_gold'];
        break;
      case PatternDifficulty.intermediate:
        challengeData['requiredBlocks'] = ['zigzag_pattern', 'loop_block', 'shuttle_blue', 'shuttle_red'];
        (challengeData['hints'] as List<String>).add('Try using a loop block to repeat your pattern efficiently.');
        break;
      case PatternDifficulty.advanced:
        challengeData['requiredBlocks'] = ['checker_pattern', 'zigzag_pattern', 'loop_block', 'row_block', 'shuttle_green'];
        (challengeData['hints'] as List<String>).add('Combine different pattern types to create more complex designs.');
        break;
      case PatternDifficulty.master:
        challengeData['requiredBlocks'] = ['checker_pattern', 'zigzag_pattern', 'loop_block', 'row_block', 'column_block', 'shuttle_black', 'shuttle_gold', 'shuttle_red'];
        (challengeData['hints'] as List<String>).add('Think about creating a pattern that tells a specific cultural story through its design.');
        break;
    }
    
    return challengeData;
  }
  
  /// Clears all cached data
  Future<void> clearCache() async {
    try {
      // Clear memory cache
      _responseCache.clear();
      
      // If we have a storage service, use it
      if (_storageService != null) {
        // We don't have a way to list keys with a specific prefix in the storage service
        // We would need to implement that in the storage service first
        debugPrint('Clearing storage service cache not fully implemented');
        return;
      }
      
      // Clear persistent cache from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_storyStepsCachePrefix) || 
            key.startsWith(_storyModelCachePrefix) || 
            key.startsWith(_lastCacheTimePrefix)) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
