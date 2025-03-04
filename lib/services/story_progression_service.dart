import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/storage_service.dart';
import '../providers/user_provider.dart';

/// Service responsible for managing story progression, including tracking
/// user progress, persisting choices, and unlocking new content.
class StoryProgressionService {
  /// Storage service used for persistent data
  final StorageService _storage;
  
  /// User provider for accessing user information
  final UserProvider _userProvider;
  
  /// In-memory cache of story progress data
  final Map<String, Map<String, dynamic>> _progressCache = {};
  
  /// In-memory cache of unlocked stories
  final Map<String, List<String>> _unlockedStoriesCache = {};
  
  /// In-memory cache of story nodes
  final Map<String, StoryNode> _storyNodeCache = {};
  
  /// In-memory cache of story models
  final Map<String, StoryModel> _storyModelCache = {};
  
  /// Storage key prefix for progress data
  static const String _progressPrefix = 'story_progress_';
  
  /// Storage key prefix for unlocked stories
  static const String _unlockedStoriesKey = 'unlocked_stories_';
  
  /// Storage key for story catalog
  static const String _storyCatalogKey = 'story_catalog';
  
  /// Creates a new instance of StoryProgressionService
  StoryProgressionService({
    required StorageService storage,
    required UserProvider userProvider,
  })  : _storage = storage,
        _userProvider = userProvider;

  /// Loads all available stories in the catalog
  Future<List<StoryOverview>> getStoryCatalog() async {
    try {
      final catalogJson = await _storage.read(_storyCatalogKey);
      if (catalogJson == null) {
        return _getDefaultStoryCatalog();
      }
      
      final List<dynamic> catalogData = jsonDecode(catalogJson);
      return catalogData
          .map((data) => StoryOverview.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('Error loading story catalog: $e');
      return _getDefaultStoryCatalog();
    }
  }
  
  /// Gets a list of story overviews that are available for the current user
  Future<List<StoryOverview>> getAvailableStories(String userId) async {
    // Ensure user progress is loaded
    await _loadUserUnlockedStories(userId);
    
    // Get the list of unlocked story IDs
    final unlockedStoryIds = _unlockedStoriesCache[userId] ?? [];
    
    // Get the full catalog
    final catalog = await getStoryCatalog();
    
    // Filter catalog to only include unlocked stories
    return catalog.where((story) => 
        unlockedStoryIds.contains(story.id) || 
        _isInitialStory(story.id)).toList();
  }
  
  /// Returns true if the story is an initial story that's always unlocked
  bool _isInitialStory(String storyId) {
    // In a real app, this might check against a list of initial story IDs
    // For now, we'll just assume stories with IDs starting with 'intro_' are initial
    return storyId.startsWith('intro_');
  }
  
  /// Gets a specific story model by ID
  Future<StoryModel?> getStory(String storyId) async {
    // Check cache first
    if (_storyModelCache.containsKey(storyId)) {
      return _storyModelCache[storyId];
    }
    
    try {
      // Load from storage
      final storyJson = await _storage.read('story_$storyId');
      if (storyJson == null) {
        return null;
      }
      
      final storyData = jsonDecode(storyJson);
      final story = StoryModel.fromJson(storyData);
      
      // Cache for future use
      _storyModelCache[storyId] = story;
      
      return story;
    } catch (e) {
      debugPrint('Error loading story $storyId: $e');
      return null;
    }
  }
  
  /// Gets a specific story node by ID
  Future<StoryNode?> getStoryNode(String nodeId) async {
    // Check cache first
    if (_storyNodeCache.containsKey(nodeId)) {
      return _storyNodeCache[nodeId];
    }
    
    // Extract the story ID from the node ID (assuming format: storyId_nodeId)
    final parts = nodeId.split('_');
    if (parts.length < 2) {
      // Invalid node ID format
      return null;
    }
    
    final storyId = parts[0];
    
    // Get the full story
    final story = await getStory(storyId);
    if (story == null) {
      return null;
    }
    
    // Find the node in the story
    final node = story.nodes[nodeId];
    if (node != null) {
      // Cache for future use
      _storyNodeCache[nodeId] = node;
    }
    
    return node;
  }
  
  /// Records user's progress in a story
  Future<void> recordStoryProgress({
    required String userId,
    required String storyId,
    required String currentNodeId,
    required List<String> completedNodeIds,
    required Map<String, List<String>> choicesMade,
    List<String>? conceptsMastered,
    Map<String, Map<String, dynamic>>? challengeResults,
    double completionPercentage = 0.0,
  }) async {
    // Load existing progress
    await _loadUserStoryProgress(userId, storyId);
    
    // Get current progress or initialize new progress
    final progress = _progressCache['${userId}_$storyId'] ?? {};
    
    // Update progress fields
    progress['currentNodeId'] = currentNodeId;
    progress['completedNodeIds'] = completedNodeIds;
    progress['choicesMade'] = choicesMade;
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    
    if (conceptsMastered != null && conceptsMastered.isNotEmpty) {
      // Merge with existing concepts
      final existingConcepts = (progress['conceptsMastered'] as List?)?.cast<String>() ?? [];
      final mergedConcepts = {...existingConcepts, ...conceptsMastered}.toList();
      progress['conceptsMastered'] = mergedConcepts;
    }
    
    if (challengeResults != null) {
      // Merge with existing challenge results
      final existingResults = progress['challengeResults'] as Map? ?? {};
      progress['challengeResults'] = {
        ...existingResults,
        ...challengeResults,
      };
    }
    
    progress['completionPercentage'] = completionPercentage;
    
    // Save progress to cache and storage
    _progressCache['${userId}_$storyId'] = progress;
    await _storage.write(
      '$_progressPrefix${userId}_$storyId',
      jsonEncode(progress),
    );
    
    // Check for story completion and unlock new content if needed
    if (completionPercentage >= 0.9) {
      await _handleStoryCompletion(userId, storyId);
    }
  }
  
  /// Handles story completion, including unlocking new content
  Future<void> _handleStoryCompletion(String userId, String storyId) async {
    // Get the story to determine what to unlock next
    final story = await getStory(storyId);
    if (story == null) return;
    
    // Get unlocked stories
    await _loadUserUnlockedStories(userId);
    final unlockedStories = _unlockedStoriesCache[userId] ?? [];
    
    // Check if this story unlocks other stories
    final newlyUnlocked = await _getStoriesToUnlock(storyId);
    
    // Add any new stories that aren't already unlocked
    final updatedUnlocked = [...unlockedStories];
    bool hasNewUnlocks = false;
    
    for (final unlockId in newlyUnlocked) {
      if (!updatedUnlocked.contains(unlockId)) {
        updatedUnlocked.add(unlockId);
        hasNewUnlocks = true;
      }
    }
    
    // If there are new unlocks, update storage
    if (hasNewUnlocks) {
      _unlockedStoriesCache[userId] = updatedUnlocked;
      await _storage.write(
        '$_unlockedStoriesKey$userId',
        jsonEncode(updatedUnlocked),
      );
    }
    
    // Record achievement for story completion if appropriate
    final achievementId = 'story_complete_$storyId';
    _userProvider.unlockAchievement(achievementId);
    
    // Give XP based on story difficulty
    int xpGain = 0;
    switch (story.difficulty) {
      case PatternDifficulty.basic:
        xpGain = 50;
        break;
      case PatternDifficulty.intermediate:
        xpGain = 100;
        _userProvider.unlockAchievement('intermediate_story_complete');
        break;
      case PatternDifficulty.advanced:
        xpGain = 200;
        _userProvider.unlockAchievement('advanced_story_complete');
        break;
      case PatternDifficulty.master:
        xpGain = 500;
        _userProvider.unlockAchievement('master_story_complete');
        break;
    }
    
    // Award XP
    if (xpGain > 0) {
      _userProvider.incrementXP(xpGain);
    }
  }
  
  /// Gets the list of story IDs that should be unlocked when a story is completed
  Future<List<String>> _getStoriesToUnlock(String completedStoryId) async {
    // In a real app, this would be defined in a story progression map
    // For now, we'll use a simple mapping
    final Map<String, List<String>> progressionMap = {
      'intro_first_pattern': ['basic_dame_dame', 'basic_colors'],
      'basic_dame_dame': ['basic_loops', 'intermediate_patterns'],
      'basic_colors': ['intermediate_colors', 'cultural_significance'],
      'basic_loops': ['intermediate_patterns'],
      'intermediate_patterns': ['advanced_patterns'],
      'advanced_patterns': ['master_patterns'],
    };
    
    return progressionMap[completedStoryId] ?? [];
  }
  
  /// Gets the user's progress in a specific story
  Future<Map<String, dynamic>> getStoryProgress(String userId, String storyId) async {
    await _loadUserStoryProgress(userId, storyId);
    return _progressCache['${userId}_$storyId'] ?? {
      'currentNodeId': '',
      'completedNodeIds': [],
      'choicesMade': {},
      'conceptsMastered': [],
      'challengeResults': {},
      'completionPercentage': 0.0,
      'lastUpdated': null,
    };
  }
  
  /// Records a specific choice made by the user
  Future<void> recordUserChoice({
    required String userId,
    required String storyId, 
    required String nodeId,
    required String choiceId,
    Map<String, dynamic> consequences = const {},
  }) async {
    // Load existing progress
    final progress = await getStoryProgress(userId, storyId);
    
    // Update choices made
    final Map<String, dynamic> choicesMade = 
        (progress['choicesMade'] as Map<String, dynamic>?) ?? {};
    
    if (!choicesMade.containsKey(nodeId)) {
      choicesMade[nodeId] = [];
    }
    
    // Add the choice if not already recorded
    final nodeChoices = List<String>.from(choicesMade[nodeId] ?? []);
    if (!nodeChoices.contains(choiceId)) {
      nodeChoices.add(choiceId);
      choicesMade[nodeId] = nodeChoices;
    }
    
    // Update completed nodes
    final completedNodeIds = List<String>.from(progress['completedNodeIds'] ?? []);
    if (!completedNodeIds.contains(nodeId)) {
      completedNodeIds.add(nodeId);
    }
    
    // Calculate approximate completion percentage
    final story = await getStory(storyId);
    double completionPercentage = 0.0;
    if (story != null) {
      completionPercentage = completedNodeIds.length / (story.nodes.length * 0.7);
      // Cap at 1.0 (100%)
      completionPercentage = completionPercentage > 1.0 ? 1.0 : completionPercentage;
    }
    
    // Record updated progress
    await recordStoryProgress(
      userId: userId,
      storyId: storyId,
      currentNodeId: nodeId,
      completedNodeIds: completedNodeIds,
      choicesMade: choicesMade.map((k, v) => MapEntry(k, List<String>.from(v))),
      completionPercentage: completionPercentage,
    );
    
    // Process any immediate consequences
    _processChoiceConsequences(userId, consequences);
  }
  
  /// Process any immediate consequences from a user choice
  void _processChoiceConsequences(String userId, Map<String, dynamic> consequences) {
    // Example: If choice gives XP, add it
    if (consequences.containsKey('xpGain')) {
      final xpGain = consequences['xpGain'] as int;
      _userProvider.incrementXP(xpGain);
    }
    
    // Example: If choice unlocks an achievement
    if (consequences.containsKey('achievements')) {
      final achievements = List<String>.from(consequences['achievements']);
      for (final achievement in achievements) {
        _userProvider.unlockAchievement(achievement);
      }
    }
    
    // Example: If choice teaches a pattern
    if (consequences.containsKey('patternUnlocked')) {
      final pattern = consequences['patternUnlocked'] as String;
      final difficulty = PatternDifficulty.basic; // Default to basic
      _userProvider.recordPatternCreated(pattern, difficulty);
    }
  }
  
  /// Records the result of a challenge
  Future<void> recordChallengeResult({
    required String userId,
    required String storyId,
    required String challengeId,
    required bool success,
    required double score,
    required int timeTaken,
    List<String>? conceptsMastered,
  }) async {
    // Load existing progress
    final progress = await getStoryProgress(userId, storyId);
    
    // Update challenge results
    final challengeResults = 
        (progress['challengeResults'] as Map<String, dynamic>?) ?? {};
    
    challengeResults[challengeId] = {
      'success': success,
      'score': score,
      'timeTaken': timeTaken,
      'completedAt': DateTime.now().toIso8601String(),
    };
    
    // Record updated progress with challenge results and mastered concepts
    await recordStoryProgress(
      userId: userId,
      storyId: storyId,
      currentNodeId: progress['currentNodeId'] ?? '',
      completedNodeIds: List<String>.from(progress['completedNodeIds'] ?? []),
      choicesMade: (progress['choicesMade'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v))
      ) ?? {},
      challengeResults: {challengeId: challengeResults[challengeId]},
      conceptsMastered: conceptsMastered,
      completionPercentage: progress['completionPercentage'] ?? 0.0,
    );
    
    // If successful, increment challenges and award achievements
    if (success) {
      _userProvider.incrementChallenges();
      _userProvider.unlockAchievement('challenge_complete_$challengeId');
      
      // If score is exceptional, award additional achievement
      if (score > 0.9) {
        _userProvider.unlockAchievement('challenge_master_$challengeId');
      }
    }
  }
  
  /// Gets the requirements for a specific story
  Future<Map<String, dynamic>> getStoryRequirements(String storyId) async {
    // Get the story
    final story = await getStory(storyId);
    if (story == null) {
      return {'hasRequirements': false};
    }
    
    // Check for story-specific requirements in metadata
    final metadata = story.metadata;
    if (metadata == null || !metadata.containsKey('requirements')) {
      return {'hasRequirements': false};
    }
    
    return {
      'hasRequirements': true,
      ...metadata['requirements'] as Map<String, dynamic>,
    };
  }
  
  /// Checks if a user meets the requirements to access a story
  Future<bool> userMeetsRequirements(String userId, String storyId) async {
    // No requirements for initial stories
    if (_isInitialStory(storyId)) {
      return true;
    }
    
    // Load unlocked stories
    await _loadUserUnlockedStories(userId);
    final unlockedStories = _unlockedStoriesCache[userId] ?? [];
    
    // Check if already unlocked
    if (unlockedStories.contains(storyId)) {
      return true;
    }
    
    // Get requirements
    final requirements = await getStoryRequirements(storyId);
    if (!requirements['hasRequirements']) {
      return false; // Cannot access if not unlocked and no defined requirements
    }
    
    // Check prerequisite stories
    if (requirements.containsKey('prerequisiteStories')) {
      final prerequisites = List<String>.from(requirements['prerequisiteStories']);
      for (final prereq in prerequisites) {
        final prereqProgress = await getStoryProgress(userId, prereq);
        final completion = prereqProgress['completionPercentage'] ?? 0.0;
        if (completion < 0.9) {
          return false; // Prerequisite not completed
        }
      }
    }
    
    // Check level requirements
    if (requirements.containsKey('minimumLevel')) {
      final requiredLevel = requirements['minimumLevel'] as int;
      if (_userProvider.level < requiredLevel) {
        return false; // User level too low
      }
    }

    // Check achievement requirements
    if (requirements.containsKey('requiredAchievements')) {
      final requiredAchievements = List<String>.from(requirements['requiredAchievements']);
      for (final achievement in requiredAchievements) {
        if (!_userProvider.hasAchievement(achievement)) {
          return false; // Missing required achievement
        }
      }
    }
    
    // Check pattern requirements
    if (requirements.containsKey('requiredPatterns')) {
      final requiredPatterns = List<String>.from(requirements['requiredPatterns']);
      for (final pattern in requiredPatterns) {
        if (!_userProvider.hasCreatedPattern(pattern)) {
          return false; // Missing required pattern
        }
      }
    }
    
    // Check premium content flag
    if (requirements.containsKey('isPremium') && requirements['isPremium'] == true) {
      if (!_userProvider.isPremium) {
        return false; // Premium content locked for non-premium users
      }
    }
    
    // All requirements met
    return true;
  }
  
  /// Manually unlock a story for a user (e.g., for testing or admin functions)
  Future<void> unlockStory(String userId, String storyId) async {
    await _loadUserUnlockedStories(userId);
    final unlockedStories = _unlockedStoriesCache[userId] ?? [];
    
    if (!unlockedStories.contains(storyId)) {
      unlockedStories.add(storyId);
      _unlockedStoriesCache[userId] = unlockedStories;
      
      await _storage.write(
        '$_unlockedStoriesKey$userId',
        jsonEncode(unlockedStories),
      );
    }
  }
  
  /// Resets a user's progress in a specific story
  Future<void> resetStoryProgress(String userId, String storyId) async {
    // Remove from cache
    _progressCache.remove('${userId}_$storyId');
    
    // Remove from storage
    await _storage.delete('$_progressPrefix${userId}_$storyId');
  }
  
  /// Resets all story progress for a user
  Future<void> resetAllProgress(String userId) async {
    // Clear progress cache for this user
    _progressCache.removeWhere((key, _) => key.startsWith('${userId}_'));
    
    // Get all keys in storage for this user
    final keysWithPrefix = '$_progressPrefix$userId';
    final unlockedStoriesKey = '$_unlockedStoriesKey$userId';
    
    // Delete progress and unlock data
    await _storage.delete(unlockedStoriesKey);
    
    // Note: In a real implementation, we would need a way to list keys
    // with a prefix in the StorageService. For now, we'll work with what we have.
    _unlockedStoriesCache.remove(userId);
  }
  
  /// Gets the user's next recommended story
  Future<StoryOverview?> getRecommendedNextStory(String userId) async {
    // Get all available stories
    final availableStories = await getAvailableStories(userId);
    
    if (availableStories.isEmpty) {
      return null;
    }
    
    // Get user's level
    final userLevel = _userProvider.level;
    
    // Sort by appropriate difficulty for user's level
    availableStories.sort((a, b) {
      // Convert difficulty to numeric value for comparison
      final aDiff = _difficultyValue(a.difficulty);
      final bDiff = _difficultyValue(b.difficulty);
      
      // Calculate how appropriate each story is for user's level
      final aAppropriate = (aDiff - userLevel).abs();
      final bAppropriate = (bDiff - userLevel).abs();
      
      // Sort by most appropriate first
      return aAppropriate.compareTo(bAppropriate);
    });
    
    // Return the most appropriate story
    return availableStories.first;
  }
  
  /// Converts difficulty enum to numeric value for comparison
  int _difficultyValue(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 1;
      case PatternDifficulty.intermediate:
        return 2;
      case PatternDifficulty.advanced:
        return 3;
      case PatternDifficulty.master:
        return 4;
    }
  }
  
  /// Loads a user's unlocked stories from storage into cache
  Future<void> _loadUserUnlockedStories(String userId) async {
    // Check if already loaded
    if (_unlockedStoriesCache.containsKey(userId)) {
      return;
    }
    
    try {
      final unlockedJson = await _storage.read('$_unlockedStoriesKey$userId');
      if (unlockedJson == null) {
        // Initialize with default unlocked stories
        _unlockedStoriesCache[userId] = _getDefaultUnlockedStories();
        return;
      }
      
      final List<dynamic> unlockedData = jsonDecode(unlockedJson);
      _unlockedStoriesCache[userId] = unlockedData.cast<String>();
    } catch (e) {
      debugPrint('Error loading unlocked stories for $userId: $e');
      _unlockedStoriesCache[userId] = _getDefaultUnlockedStories();
    }
  }
  
  /// Loads a user's progress in a specific story from storage into cache
  Future<void> _loadUserStoryProgress(String userId, String storyId) async {
    final cacheKey = '${userId}_$storyId';
    
    // Check if already loaded
    if (_progressCache.containsKey(cacheKey)) {
      return;
    }
    
    try {
      final progressJson = await _storage.read('$_progressPrefix$cacheKey');
      if (progressJson == null) {
        // Initialize empty progress
        _progressCache[cacheKey] = {};
        return;
      }
      
      final Map<String, dynamic> progressData = jsonDecode(progressJson);
      _progressCache[cacheKey] = progressData;
    } catch (e) {
      debugPrint('Error loading progress for $userId in story $storyId: $e');
      _progressCache[cacheKey] = {};
    }
  }
  
  /// Returns the default list of unlocked stories for new users
  List<String> _getDefaultUnlockedStories() {
    // In a real app, this would be a predefined list of initial story IDs
    return ['intro_first_pattern'];
  }
  
  /// Returns the default story catalog if none is stored
  List<StoryOverview> _getDefaultStoryCatalog() {
    // In a real app, this would be loaded from a bundled assets file
    return [
      StoryOverview(
        id: 'intro_first_pattern',
        title: 'The First Pattern',
        description: 'Learn about the Dame-Dame pattern and its significance',
        difficulty: PatternDifficulty.basic,
        concepts: ['sequence', 'pattern'],
      ),
      StoryOverview(
        id: 'basic_dame_dame',
        title: 'Creating Dame-Dame',
        description: 'Create your first Kente pattern - the checkerboard',
        difficulty: PatternDifficulty.basic,
        concepts: ['pattern', 'sequence'],
      ),
      StoryOverview(
        id: 'basic_colors',
        title: 'Colors in Kente',
        description: 'Learn about the meaning of colors in Kente cloth',
        difficulty: PatternDifficulty.basic,
        concepts: ['variables', 'pattern'],
      ),
      StoryOverview(
        id: 'basic_loops',
        title: 'Pattern Repetition',
        description: 'Learn how to repeat patterns using loops',
        difficulty: PatternDifficulty.basic,
        concepts: ['loop', 'pattern'],
      ),
      StoryOverview(
        id: 'intermediate_patterns',
        title: 'Nkyinkyim Pattern',
        description: 'Create the zigzag pattern representing life\'s journey',
        difficulty: PatternDifficulty.intermediate,
        concepts: ['pattern', 'loop', 'sequence'],
      ),
      StoryOverview(
        id: 'intermediate_colors',
        title: 'Color Harmony',
        description: 'Learn to create balanced color combinations',
        difficulty: PatternDifficulty.intermediate,
        concepts: ['variables', 'conditionals'],
      ),
      StoryOverview(
        id: 'cultural_significance',
        title: 'Stories in Patterns',
        description: 'Discover how patterns tell cultural stories',
        difficulty: PatternDifficulty.intermediate,
        concepts: ['pattern', 'sequence'],
      ),
      StoryOverview(
        id: 'advanced_patterns',
        title: 'Complex Pattern Combinations',
        description: 'Create advanced patterns with nested structures',
        difficulty: PatternDifficulty.advanced,
        concepts: ['loop', 'functions', 'pattern'],
      ),
      StoryOverview(
        id: 'master_patterns',
        title: 'Master Weaver Patterns',
        description: 'Create museum-quality traditional patterns',
        difficulty: PatternDifficulty.master,
        concepts: ['loop', 'functions', 'pattern', 'debug'],
        isPremium: true,
      ),
    ];
  }
  
  /// Clears all caches (useful for testing or when changing users)
  void clearCaches() {
    _progressCache.clear();
    _unlockedStoriesCache.clear();
    _storyNodeCache.clear();
    _storyModelCache.clear();
  }
}