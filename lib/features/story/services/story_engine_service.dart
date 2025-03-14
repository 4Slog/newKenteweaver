import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../models/story_model.dart';
import '../../../models/pattern_difficulty.dart';
import '../../../services/storage_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/logging_service.dart';

/// Service for generating and managing story content using Google's Gemini API
class StoryEngineService extends ChangeNotifier {
  final GeminiService _geminiService;
  final StorageService _storageService;
  final LoggingService _loggingService;
  
  /// Cache for story responses to reduce API calls
  final Map<String, dynamic> _responseCache = {};
  
  /// Keys for the storage
  static const String _storyStepsCachePrefix = 'story_steps_cache_';
  static const String _storyModelCachePrefix = 'story_model_cache_';
  static const String _lastCacheTimePrefix = 'last_cache_time_';
  
  /// Cache expiration time (24 hours in milliseconds)
  static const int _cacheExpirationTime = 24 * 60 * 60 * 1000;
  
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
        "Every bug is just an opportunity for a better algorithm.",
        "In coding, as in weaving, patterns tell stories.",
      ],
    },
  };
  
  /// Creates a new instance of StoryEngineService
  StoryEngineService({
    required GeminiService geminiService,
    required StorageService storageService,
    required LoggingService loggingService,
  }) : _geminiService = geminiService,
       _storageService = storageService,
       _loggingService = loggingService;
  
  /// Get a story node by ID
  Future<StoryNode> getNode(String nodeId) async {
    try {
      // Check cache first
      final cacheKey = '${_storyModelCachePrefix}$nodeId';
      final cachedData = await _storageService.read(cacheKey);
      
      if (cachedData != null) {
        final lastCacheTime = await _storageService.read('${_lastCacheTimePrefix}$nodeId');
        if (lastCacheTime != null) {
          final cacheTime = int.parse(lastCacheTime);
          if (DateTime.now().millisecondsSinceEpoch - cacheTime < _cacheExpirationTime) {
            return StoryNode.fromJson(jsonDecode(cachedData));
          }
        }
      }
      
      // Generate node using Gemini API
      final prompt = _buildNodePrompt(nodeId);
      final response = await _geminiService.generateStoryNode(prompt);
      
      try {
        final nodeData = jsonDecode(response);
        final node = StoryNode.fromJson(nodeData);
        
        // Cache the node
        await _storageService.write(cacheKey, jsonEncode(nodeData));
        await _storageService.write(
          '${_lastCacheTimePrefix}$nodeId',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        return node;
      } catch (e) {
        _loggingService.logError('Failed to parse story node: $e');
        // Fallback to default node if parsing fails
        return _createDefaultNode(nodeId);
      }
    } catch (e) {
      _loggingService.logError('Failed to get story node: $e');
      return _createDefaultNode(nodeId);
    }
  }
  
  /// Generate a story based on user progress and preferences
  Future<StoryModel> generateStory({
    required String storyId,
    required PatternDifficulty difficulty,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${_storyModelCachePrefix}$storyId';
      final cachedData = await _storageService.read(cacheKey);
      
      if (cachedData != null) {
        final lastCacheTime = await _storageService.read('${_lastCacheTimePrefix}$storyId');
        if (lastCacheTime != null) {
          final cacheTime = int.parse(lastCacheTime);
          if (DateTime.now().millisecondsSinceEpoch - cacheTime < _cacheExpirationTime) {
            return StoryModel.fromJson(jsonDecode(cachedData));
          }
        }
      }
      
      // Generate story using Gemini API
      final prompt = _buildStoryPrompt(storyId, difficulty, userContext);
      final response = await _geminiService.generateStory(prompt);
      
      try {
        final storyData = jsonDecode(response);
        final story = StoryModel.fromJson(storyData);
        
        // Cache the story
        await _storageService.write(cacheKey, jsonEncode(storyData));
        await _storageService.write(
          '${_lastCacheTimePrefix}$storyId',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        return story;
      } catch (e) {
        _loggingService.logError('Failed to parse story: $e');
        // Fallback to default story if parsing fails
        return _createDefaultStory(storyId, difficulty);
      }
    } catch (e) {
      _loggingService.logError('Failed to generate story: $e');
      return _createDefaultStory(storyId, difficulty);
    }
  }
  
  /// Build a prompt for generating a story node
  String _buildNodePrompt(String nodeId) {
    return '''
    Generate a story node for the Kente Codeweaver app with the following ID: $nodeId.
    
    The story should feature Kweku Ananse, a 9-10 year old tech-savvy mentor who teaches coding through Kente weaving.
    
    Character context:
    ${jsonEncode(_characterContext['kweku'])}
    
    The response should be a valid JSON object with the following structure:
    {
      "id": "$nodeId",
      "title": "Node title",
      "subtitle": "Optional subtitle",
      "content": "Main story content",
      "culturalContext": "Optional cultural information about Kente patterns",
      "chapter": "introduction|basics|intermediate|advanced",
      "requiredPatterns": ["pattern1", "pattern2"],
      "nextNodes": {"choice1": "nextNodeId1", "choice2": "nextNodeId2"},
      "hint": "Optional hint for the user",
      "isPremium": false,
      "lessonId": "Optional lesson ID",
      "difficulty": "basic|intermediate|advanced|expert",
      "backgroundMusic": "Optional background music filename"
    }
    ''';
  }
  
  /// Build a prompt for generating a complete story
  String _buildStoryPrompt(
    String storyId, 
    PatternDifficulty difficulty,
    Map<String, dynamic>? userContext,
  ) {
    final difficultyStr = difficulty.toString().split('.').last;
    final contextStr = userContext != null ? jsonEncode(userContext) : '{}';
    
    return '''
    Generate a complete story for the Kente Codeweaver app with the following ID: $storyId.
    
    The story should be appropriate for a $difficultyStr difficulty level.
    
    User context:
    $contextStr
    
    Character context:
    ${jsonEncode(_characterContext['kweku'])}
    
    The story should teach coding concepts through Kente weaving patterns.
    
    The response should be a valid JSON object with the following structure:
    {
      "id": "$storyId",
      "title": "Story title",
      "description": "Brief description",
      "difficulty": "$difficultyStr",
      "nodes": [
        {
          "id": "node1",
          "title": "Node title",
          "content": "Story content",
          "chapter": "introduction",
          "nextNodes": {"choice1": "node2"}
        },
        // More nodes...
      ],
      "startNodeId": "node1"
    }
    ''';
  }
  
  /// Create a default node when generation fails
  StoryNode _createDefaultNode(String nodeId) {
    return StoryNode(
      id: nodeId,
      title: 'The Journey Begins',
      content: 'Kweku Ananse welcomes you to the world of coding and Kente weaving. "Let\'s start our adventure together!"',
      chapter: StoryChapter.introduction,
      nextNodes: const {'continue': 'intro_2'},
      requiredPatterns: const [],
    );
  }
  
  /// Create a default story when generation fails
  StoryModel _createDefaultStory(String storyId, PatternDifficulty difficulty) {
    final difficultyStr = difficulty.toString().split('.').last;
    
    return StoryModel(
      id: storyId,
      title: 'The Coding Adventure',
      description: 'Join Kweku Ananse on a coding adventure through the world of Kente patterns.',
      difficulty: difficulty,
      nodes: [
        StoryNode(
          id: 'intro_1',
          title: 'The Journey Begins',
          content: 'Kweku Ananse welcomes you to the world of coding and Kente weaving. "Let\'s start our adventure together!"',
          chapter: StoryChapter.introduction,
          nextNodes: const {'continue': 'intro_2'},
          requiredPatterns: const [],
        ),
        StoryNode(
          id: 'intro_2',
          title: 'First Steps',
          content: 'Kweku shows you your first pattern. "This is how we start coding our Kente patterns."',
          chapter: StoryChapter.introduction,
          nextNodes: const {'continue': 'challenge_1'},
          requiredPatterns: const [],
        ),
        StoryNode(
          id: 'challenge_1',
          title: 'Your First Challenge',
          content: 'Time to create your first pattern! Kweku will guide you through the process.',
          chapter: StoryChapter.basics,
          nextNodes: const {'complete': 'outro'},
          requiredPatterns: const ['basic_pattern'],
        ),
        StoryNode(
          id: 'outro',
          title: 'Well Done!',
          content: 'Congratulations on completing your first pattern! Kweku is proud of your progress.',
          chapter: StoryChapter.basics,
          nextNodes: const {},
          requiredPatterns: const [],
        ),
      ],
      startNodeId: 'intro_1',
    );
  }
}
