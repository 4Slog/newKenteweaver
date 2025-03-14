import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/lesson_model.dart';
import '../models/story_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/storage_service.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  
  /// Add new fields for enhanced story management
  static const String _storyStateKey = 'story_state_';
  static const String _characterContextKey = 'character_context_';
  
  /// Character context for consistent personality
  final Map<String, dynamic> _characterContext = {
    'kweku': {
      'personality': 'tech-savvy, modern, witty, helpful',
      'background': 'young coding expert, Ananse descendant',
      'teachingStyle': 'uses stories to explain code concepts',
      'catchphrases': [
        "Let's debug this pattern together!",
        "Every bug has a story behind it.",
        "Code is like weaving - patterns within patterns."
      ]
    },
    'ama': {
      'personality': 'patient, encouraging, detail-oriented',
      'background': 'experienced Kente weaver, cultural historian',
      'teachingStyle': 'connects coding to traditional weaving',
      'catchphrases': [
        "The pattern tells a story.",
        "In weaving as in coding, precision matters.",
        "Let me show you how our ancestors would approach this."
      ]
    }
  };
  
  /// Factory constructor to get the singleton instance
  factory GeminiStoryService() {
    _instance ??= GeminiStoryService._internal();
    return _instance!;
  }
  
  /// Private constructor for singleton pattern
  GeminiStoryService._internal();
  
  /// Initialize the service with API key and optional storage service
  Future<void> initialize({StorageService? storageService}) async {
    try {
      // Load API key from environment variables
      final String? apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in environment variables');
      }
      
      // Initialize the Gemini model
      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        safetySettings: [
          SafetySetting(
            category: HarmCategory.dangerousContent,
            threshold: HarmBlockThreshold.mediumAndAbove,
          ),
          SafetySetting(
            category: HarmCategory.harassment,
            threshold: HarmBlockThreshold.mediumAndAbove,
          ),
          SafetySetting(
            category: HarmCategory.hateSpeech,
            threshold: HarmBlockThreshold.mediumAndAbove,
          ),
          SafetySetting(
            category: HarmCategory.sexuallyExplicit,
            threshold: HarmBlockThreshold.mediumAndAbove,
          ),
        ],
      );
      
      // Set storage service if provided
      _storageService = storageService;
      
      // Load cache from shared preferences
      await _loadCacheFromPreferences();
      
      debugPrint('GeminiStoryService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing GeminiStoryService: $e');
      rethrow;
    }
  }
  
  /// Load cache from shared preferences
  Future<void> _loadCacheFromPreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get all keys
      final Set<String> keys = prefs.getKeys();
      
      // Filter story cache keys
      final Iterable<String> storyCacheKeys = keys.where(
        (key) => key.startsWith(_storyStepsCachePrefix) || key.startsWith(_storyModelCachePrefix)
      );
      
      // Load cache data
      for (final String key in storyCacheKeys) {
        final String? jsonData = prefs.getString(key);
        if (jsonData != null) {
          final String lastCacheTimeKey = _lastCacheTimePrefix + key;
          final int lastCacheTime = prefs.getInt(lastCacheTimeKey) ?? 0;
          
          // Check if cache is still valid
          final int currentTime = DateTime.now().millisecondsSinceEpoch;
          if (currentTime - lastCacheTime < _cacheExpirationTime) {
            _responseCache[key] = jsonDecode(jsonData);
          } else {
            // Remove expired cache
            await prefs.remove(key);
            await prefs.remove(lastCacheTimeKey);
          }
        }
      }
      
      debugPrint('Loaded ${_responseCache.length} items from cache');
    } catch (e) {
      debugPrint('Error loading cache from preferences: $e');
    }
  }
  
  /// Save data to cache
  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      _responseCache[key] = data;
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(data);
      
      await prefs.setString(key, jsonData);
      
      // Save cache timestamp
      final String timeKey = _lastCacheTimePrefix + key;
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(timeKey, currentTime);
      
      debugPrint('Saved data to cache with key: $key');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }
  
  /// Generate a story node based on a prompt
  Future<Map<String, dynamic>> generateStoryNode({
    required String prompt,
    String chapter = 'introduction',
    String character = 'kweku',
    String? culturalContext,
    PatternDifficulty difficulty = PatternDifficulty.basic,
  }) async {
    try {
      // Create a cache key
      final String cacheKey = _storyStepsCachePrefix + _createCacheKey(
        prompt: prompt,
        chapter: chapter,
        character: character,
        culturalContext: culturalContext,
        difficulty: difficulty.toString(),
      );
      
      // Check cache first
      if (_responseCache.containsKey(cacheKey)) {
        debugPrint('Using cached story node for prompt: $prompt');
        return Map<String, dynamic>.from(_responseCache[cacheKey]);
      }
      
      // Build the prompt for Gemini
      final String systemPrompt = _buildStoryNodePrompt(
        prompt: prompt,
        chapter: chapter,
        character: character,
        culturalContext: culturalContext,
        difficulty: difficulty,
      );
      
      // Generate content using Gemini
      final GenerateContentResponse response = await _model.generateContent([
        Content.text(systemPrompt),
      ]);
      
      // Extract and parse the response
      final String responseText = response.text ?? '';
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      // Parse the JSON response
      Map<String, dynamic> nodeData;
      try {
        // Extract JSON from the response (it might be wrapped in markdown code blocks)
        final String jsonText = _extractJsonFromResponse(responseText);
        nodeData = jsonDecode(jsonText) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error parsing JSON response: $e');
        // Fallback to a basic node structure
        nodeData = _createFallbackStoryNode(
          prompt: prompt,
          chapter: chapter,
          character: character,
        );
      }
      
      // Save to cache
      await _saveToCache(cacheKey, nodeData);
      
      return nodeData;
    } catch (e) {
      debugPrint('Error generating story node: $e');
      // Return a fallback node in case of error
      return _createFallbackStoryNode(
        prompt: prompt,
        chapter: chapter,
        character: character,
      );
    }
  }
  
  /// Generate a complete story based on a prompt
  Future<StoryModel> generateStory({
    required String prompt,
    required String title,
    PatternDifficulty difficulty = PatternDifficulty.basic,
    int nodeCount = 5,
    String? culturalContext,
  }) async {
    try {
      // Create a cache key
      final String cacheKey = _storyModelCachePrefix + _createCacheKey(
        prompt: prompt,
        title: title,
        difficulty: difficulty.toString(),
        nodeCount: nodeCount.toString(),
        culturalContext: culturalContext,
      );
      
      // Check cache first
      if (_responseCache.containsKey(cacheKey)) {
        debugPrint('Using cached story for prompt: $prompt');
        final Map<String, dynamic> storyData = Map<String, dynamic>.from(_responseCache[cacheKey]);
        return StoryModel.fromJson(storyData);
      }
      
      // Build the prompt for Gemini
      final String systemPrompt = _buildStoryPrompt(
        prompt: prompt,
        title: title,
        difficulty: difficulty,
        nodeCount: nodeCount,
        culturalContext: culturalContext,
      );
      
      // Generate content using Gemini
      final GenerateContentResponse response = await _model.generateContent([
        Content.text(systemPrompt),
      ]);
      
      // Extract and parse the response
      final String responseText = response.text ?? '';
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      // Parse the JSON response
      Map<String, dynamic> storyData;
      try {
        // Extract JSON from the response (it might be wrapped in markdown code blocks)
        final String jsonText = _extractJsonFromResponse(responseText);
        storyData = jsonDecode(jsonText) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error parsing JSON response: $e');
        // Fallback to a basic story structure
        storyData = _createFallbackStory(
          prompt: prompt,
          title: title,
          difficulty: difficulty,
        );
      }
      
      // Save to cache
      await _saveToCache(cacheKey, storyData);
      
      return StoryModel.fromJson(storyData);
    } catch (e) {
      debugPrint('Error generating story: $e');
      // Return a fallback story in case of error
      final Map<String, dynamic> fallbackStory = _createFallbackStory(
        prompt: prompt,
        title: title,
        difficulty: difficulty,
      );
      return StoryModel.fromJson(fallbackStory);
    }
  }
  
  /// Build a prompt for generating a story node
  String _buildStoryNodePrompt({
    required String prompt,
    required String chapter,
    required String character,
    String? culturalContext,
    required PatternDifficulty difficulty,
  }) {
    final Map<String, dynamic>? characterInfo = _characterContext[character.toLowerCase()];
    
    return '''
You are an AI assistant helping to create interactive educational content for "Kente Codeweaver", an app that teaches coding through the lens of traditional Ghanaian Kente weaving patterns.

Create a single story node with the following characteristics:
- It should be part of the "$chapter" chapter
- It should be narrated by ${character}, who is ${characterInfo?['personality'] ?? 'helpful and knowledgeable'} and ${characterInfo?['background'] ?? 'an expert in coding and Kente weaving'}
- The difficulty level is ${difficulty.displayName}
- The node should relate to this prompt: "$prompt"
${culturalContext != null ? '- Include this cultural context: "$culturalContext"' : ''}

Return ONLY a JSON object with the following structure:
{
  "id": "unique_node_id",
  "title": "Node Title",
  "subtitle": "Optional subtitle",
  "content": "Main content of the node, 2-3 paragraphs",
  "culturalContext": "Optional cultural context information",
  "chapter": "$chapter",
  "requiredPatterns": ["pattern1", "pattern2"],
  "nextNodes": {"choice1": "next_node_id_1", "choice2": "next_node_id_2"},
  "hint": "Optional hint for the user",
  "isPremium": false,
  "lessonId": "optional_lesson_id",
  "difficulty": "${difficulty.toString().split('.').last}",
  "backgroundMusic": "optional_music_filename"
}
''';
  }
  
  /// Build a prompt for generating a complete story
  String _buildStoryPrompt({
    required String prompt,
    required String title,
    required PatternDifficulty difficulty,
    required int nodeCount,
    String? culturalContext,
  }) {
    return '''
You are an AI assistant helping to create interactive educational content for "Kente Codeweaver", an app that teaches coding through the lens of traditional Ghanaian Kente weaving patterns.

Create a complete story with the following characteristics:
- Title: "$title"
- Difficulty level: ${difficulty.displayName}
- The story should relate to this prompt: "$prompt"
- The story should have approximately $nodeCount nodes
${culturalContext != null ? '- Include this cultural context: "$culturalContext"' : ''}

Return ONLY a JSON object with the following structure:
{
  "id": "unique_story_id",
  "title": "$title",
  "description": "Brief description of the story",
  "difficulty": "${difficulty.toString().split('.').last}",
  "startNodeId": "id_of_first_node",
  "nodes": [
    {
      "id": "node_id_1",
      "title": "Node Title",
      "subtitle": "Optional subtitle",
      "content": "Main content of the node",
      "culturalContext": "Optional cultural context",
      "chapter": "introduction",
      "requiredPatterns": ["pattern1", "pattern2"],
      "nextNodes": {"choice1": "next_node_id", "choice2": "another_node_id"},
      "hint": "Optional hint",
      "isPremium": false,
      "lessonId": "optional_lesson_id",
      "difficulty": "${difficulty.toString().split('.').last}",
      "backgroundMusic": "optional_music_filename"
    },
    // More nodes...
  ]
}
''';
  }
  
  /// Extract JSON from a response that might contain markdown or other text
  String _extractJsonFromResponse(String response) {
    // Try to extract JSON from markdown code blocks
    final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final Match? match = jsonRegex.firstMatch(response);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    
    // If no code blocks found, try to find JSON object directly
    final RegExp objectRegex = RegExp(r'(\{[\s\S]*\})');
    final Match? objectMatch = objectRegex.firstMatch(response);
    
    if (objectMatch != null && objectMatch.groupCount >= 1) {
      return objectMatch.group(1)!.trim();
    }
    
    // If all else fails, return the original response
    return response.trim();
  }
  
  /// Create a fallback story node in case of API failure
  Map<String, dynamic> _createFallbackStoryNode({
    required String prompt,
    required String chapter,
    required String character,
  }) {
    final String nodeId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': nodeId,
      'title': 'The Journey Continues',
      'subtitle': 'A step in your coding adventure',
      'content': 'As you continue your journey through the world of coding and Kente patterns, '
          'remember that every challenge is an opportunity to learn. '
          'The path ahead may have obstacles, but with persistence, you will master both the art of code and the wisdom of traditional patterns.',
      'culturalContext': 'In Ghanaian tradition, learning is seen as a continuous journey, not a destination.',
      'chapter': chapter,
      'requiredPatterns': ['basic_loop', 'simple_condition'],
      'nextNodes': {'continue': 'next_$nodeId'},
      'hint': 'Think about how patterns repeat in both code and weaving.',
      'isPremium': false,
      'difficulty': 'basic',
      'backgroundMusic': 'gentle_background.mp3'
    };
  }
  
  /// Create a fallback story in case of API failure
  Map<String, dynamic> _createFallbackStory({
    required String prompt,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    final String storyId = 'fallback_story_${DateTime.now().millisecondsSinceEpoch}';
    final String nodeId1 = '${storyId}_node_1';
    final String nodeId2 = '${storyId}_node_2';
    final String nodeId3 = '${storyId}_node_3';
    
    return {
      'id': storyId,
      'title': title,
      'description': 'A journey through coding and Kente weaving traditions.',
      'difficulty': difficulty.toString().split('.').last,
      'startNodeId': nodeId1,
      'nodes': [
        {
          'id': nodeId1,
          'title': 'The Beginning',
          'subtitle': 'First steps in your journey',
          'content': 'Welcome to the world of Kente Codeweaving! In this adventure, you will learn how traditional patterns connect to modern coding concepts. Every pattern tells a story, just as every line of code serves a purpose.',
          'culturalContext': 'Kente cloth has been woven by the Akan people of Ghana for centuries, with each pattern having specific cultural meanings.',
          'chapter': 'introduction',
          'requiredPatterns': ['basic_loop'],
          'nextNodes': {'continue': nodeId2},
          'hint': 'Look for the repeating elements in the pattern.',
          'isPremium': false,
          'difficulty': 'basic',
          'backgroundMusic': 'intro_theme.mp3'
        },
        {
          'id': nodeId2,
          'title': 'The Challenge',
          'subtitle': 'Applying what you\'ve learned',
          'content': 'Now it\'s time to apply what you\'ve learned. Can you identify the pattern that repeats in this Kente design? Think about how you might represent this using a loop in code.',
          'chapter': 'basics',
          'requiredPatterns': ['basic_loop', 'simple_condition'],
          'nextNodes': {'success': nodeId3, 'try_again': nodeId2},
          'hint': 'Consider how the pattern changes when certain conditions are met.',
          'isPremium': false,
          'difficulty': 'basic',
          'backgroundMusic': 'thinking_music.mp3'
        },
        {
          'id': nodeId3,
          'title': 'The Revelation',
          'subtitle': 'Understanding the connection',
          'content': 'Excellent work! You\'ve discovered how the repeating elements in Kente patterns mirror the loops in code. This connection between traditional craft and modern technology shows how human creativity finds similar patterns across different domains and centuries.',
          'culturalContext': 'Master weavers in Ghana spend years perfecting their craft, just as expert programmers continuously refine their skills.',
          'chapter': 'conclusion',
          'requiredPatterns': ['basic_loop', 'simple_condition', 'function_basics'],
          'nextNodes': {},
          'isPremium': false,
          'difficulty': 'basic',
          'backgroundMusic': 'success_theme.mp3'
        }
      ]
    };
  }
  
  /// Create a cache key from parameters
  String _createCacheKey({
    String? prompt,
    String? title,
    String? chapter,
    String? character,
    String? culturalContext,
    String? difficulty,
    String? nodeCount,
  }) {
    final List<String> keyParts = [];
    
    if (prompt != null) keyParts.add('prompt:${prompt.hashCode}');
    if (title != null) keyParts.add('title:${title.hashCode}');
    if (chapter != null) keyParts.add('chapter:$chapter');
    if (character != null) keyParts.add('character:$character');
    if (culturalContext != null) keyParts.add('context:${culturalContext.hashCode}');
    if (difficulty != null) keyParts.add('difficulty:$difficulty');
    if (nodeCount != null) keyParts.add('nodeCount:$nodeCount');
    
    return keyParts.join('_');
  }
  
  /// Clear the cache
  Future<void> clearCache() async {
    try {
      _responseCache.clear();
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();
      
      for (final String key in keys) {
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
  
  /// Dispose of resources
  void dispose() {
    // Nothing to dispose currently
  }
} 