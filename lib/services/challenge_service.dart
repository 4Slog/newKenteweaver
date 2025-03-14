import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';
import '../models/block_model.dart';
import '../models/learning_progress_model.dart' as learning;
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/logging_service.dart';
import '../services/adaptive_learning_service.dart';

/// Service for generating and validating coding challenges
class ChallengeService extends ChangeNotifier {
  final GeminiService _geminiService;
  final StorageService _storageService;
  final LoggingService _loggingService;
  final AdaptiveLearningService _learningService;
  
  /// Cache for challenges to reduce API calls
  final Map<String, Map<String, dynamic>> _challengeCache = {};
  
  /// Cache expiration time (24 hours in milliseconds)
  static const int _cacheExpirationTime = 24 * 60 * 60 * 1000;
  
  /// Currently active challenge
  String? _activeChallengeId;
  
  /// Challenge difficulty adjustment factor
  double _difficultyAdjustment = 0.0;
  
  /// Creates a new instance of ChallengeService
  ChallengeService({
    required GeminiService geminiService,
    required StorageService storageService,
    required LoggingService loggingService,
    required AdaptiveLearningService learningService,
  }) : _geminiService = geminiService,
       _storageService = storageService,
       _loggingService = loggingService,
       _learningService = learningService {
    _loadChallengeCache();
    _loadDifficultyAdjustment();
  }
  
  /// Load challenge cache from storage
  Future<void> _loadChallengeCache() async {
    try {
      final cacheData = await _storageService.read('challenge_cache');
      if (cacheData != null) {
        final Map<String, dynamic> data = jsonDecode(cacheData);
        data.forEach((key, value) {
          _challengeCache[key] = Map<String, dynamic>.from(value);
        });
      }
    } catch (e) {
      _loggingService.log('Failed to load challenge cache: $e');
    }
  }
  
  /// Load difficulty adjustment from storage
  Future<void> _loadDifficultyAdjustment() async {
    try {
      final adjustmentData = await _storageService.read('difficulty_adjustment');
      if (adjustmentData != null) {
        _difficultyAdjustment = double.parse(adjustmentData);
      }
    } catch (e) {
      _loggingService.log('Failed to load difficulty adjustment: $e');
    }
  }
  
  /// Save challenge cache to storage
  Future<void> _saveChallengeCache() async {
    try {
      await _storageService.write('challenge_cache', jsonEncode(_challengeCache));
    } catch (e) {
      _loggingService.log('Failed to save challenge cache: $e');
    }
  }
  
  /// Save difficulty adjustment to storage
  Future<void> _saveDifficultyAdjustment() async {
    try {
      await _storageService.write('difficulty_adjustment', _difficultyAdjustment.toString());
    } catch (e) {
      _loggingService.log('Failed to save difficulty adjustment: $e');
    }
  }
  
  /// Generate a new challenge based on concept and difficulty
  Future<Map<String, dynamic>> generateChallenge({
    required String conceptId,
    PatternDifficulty? difficulty,
    String? culturalContext,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Determine appropriate difficulty level
    final PatternDifficulty effectiveDifficulty = difficulty ?? 
        await _determineAppropriateLevel(conceptId);
    
    // Create cache key
    final String cacheKey = '${conceptId}_${effectiveDifficulty.name}_${culturalContext ?? 'default'}';
    
    // Check cache first
    if (_challengeCache.containsKey(cacheKey)) {
      final cachedChallenge = _challengeCache[cacheKey]!;
      final timestamp = cachedChallenge['timestamp'] as int;
      
      // Check if cache is still valid
      if (DateTime.now().millisecondsSinceEpoch - timestamp < _cacheExpirationTime) {
        _loggingService.debug('Using cached challenge for $cacheKey', tag: 'ChallengeService');
        return Map<String, dynamic>.from(cachedChallenge['data']);
      }
    }
    
    // Get concept mastery level
    final double masteryLevel = await _learningService.getConceptMastery(conceptId);
    
    // Apply difficulty adjustment
    final double adjustedMastery = (masteryLevel + _difficultyAdjustment).clamp(0.0, 1.0);
    
    // Prepare context for AI
    final Map<String, dynamic> context = {
      'conceptId': conceptId,
      'difficulty': effectiveDifficulty.name,
      'masteryLevel': adjustedMastery,
      'culturalContext': culturalContext,
      ...?additionalContext,
    };
    
    try {
      // Generate challenge using AI
      final challenge = await _geminiService.generateChallenge(
        conceptId: conceptId,
        difficulty: effectiveDifficulty,
        masteryLevel: adjustedMastery,
        context: additionalContext,
      );
      
      // Cache the result
      _challengeCache[cacheKey] = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': challenge,
      };
      
      // Save cache
      await _saveChallengeCache();
      
      // Set as active challenge
      _activeChallengeId = challenge['id'];
      
      return challenge;
    } catch (e) {
      _loggingService.error('Failed to generate challenge: $e', tag: 'ChallengeService');
      
      // Return a fallback challenge
      return _generateFallbackChallenge(conceptId, effectiveDifficulty);
    }
  }
  
  /// Determine appropriate difficulty level based on user's mastery
  Future<PatternDifficulty> _determineAppropriateLevel(String conceptId) async {
    final double mastery = await _learningService.getConceptMastery(conceptId);
    
    // Apply difficulty adjustment
    final double adjustedMastery = (mastery + _difficultyAdjustment).clamp(0.0, 1.0);
    
    if (adjustedMastery < 0.3) {
      return PatternDifficulty.basic;
    } else if (adjustedMastery < 0.6) {
      return PatternDifficulty.intermediate;
    } else if (adjustedMastery < 0.85) {
      return PatternDifficulty.advanced;
    } else {
      return PatternDifficulty.expert;
    }
  }
  
  /// Generate a fallback challenge when AI generation fails
  Map<String, dynamic> _generateFallbackChallenge(
    String conceptId, 
    PatternDifficulty difficulty,
  ) {
    // Simple fallback challenges for different concepts
    final Map<String, List<Map<String, dynamic>>> fallbackChallenges = {
      'sequences': [
        {
          'id': 'seq_basic_1',
          'title': 'Create a Simple Pattern',
          'description': 'Create a pattern using the blocks provided.',
          'instructions': 'Arrange the blocks to create a repeating pattern.',
          'difficulty': PatternDifficulty.basic.name,
        },
        {
          'id': 'seq_intermediate_1',
          'title': 'Complete the Pattern',
          'description': 'Complete the pattern by filling in the missing blocks.',
          'instructions': 'Identify the pattern and place the correct blocks in the empty spaces.',
          'difficulty': PatternDifficulty.intermediate.name,
        },
      ],
      'loops': [
        {
          'id': 'loop_basic_1',
          'title': 'Repeat a Pattern',
          'description': 'Use a loop to repeat a pattern multiple times.',
          'instructions': 'Use the repeat block to create a pattern that repeats 3 times.',
          'difficulty': PatternDifficulty.basic.name,
        },
        {
          'id': 'loop_intermediate_1',
          'title': 'Nested Loops',
          'description': 'Use nested loops to create a complex pattern.',
          'instructions': 'Create a pattern using one loop inside another loop.',
          'difficulty': PatternDifficulty.intermediate.name,
        },
      ],
      // Add more fallback challenges for other concepts
    };
    
    // Get fallback challenges for the concept
    final List<Map<String, dynamic>> conceptChallenges = 
        fallbackChallenges[conceptId] ?? fallbackChallenges['sequences']!;
    
    // Find a challenge matching the difficulty
    final matchingChallenges = conceptChallenges.where(
      (c) => c['difficulty'] == difficulty.name
    ).toList();
    
    if (matchingChallenges.isNotEmpty) {
      return matchingChallenges.first;
    } else {
      // Return the first challenge if no matching difficulty
      return conceptChallenges.first;
    }
  }
  
  /// Validate a user's solution to a challenge
  Future<Map<String, dynamic>> validateSolution({
    required String challengeId,
    required List<Block> solution,
  }) async {
    if (_activeChallengeId != challengeId) {
      _loggingService.warning(
        'Validating solution for inactive challenge: $challengeId',
        tag: 'ChallengeService',
      );
    }
    
    try {
      // Convert solution to a format suitable for validation
      final solutionData = solution.map((block) => block.toJson()).toList();
      
      // Get the appropriate difficulty level
      final PatternDifficulty solutionDifficulty = await _determineAppropriateLevel(challengeId.split('_')[0]);
      
      // Validate using AI
      final validationResult = await _geminiService.validateChallengeSolution(
        challengeId: challengeId,
        blocks: learning.BlockCollection(
          blocks: solutionData,
          pattern: 'solution_pattern',
        ),
        difficulty: solutionDifficulty,
      );
      
      // Update difficulty adjustment based on result
      _updateDifficultyAdjustment(validationResult['success'] as bool);
      
      // Update concept mastery
      if (validationResult.containsKey('conceptId')) {
        final String conceptId = validationResult['conceptId'];
        final bool success = validationResult['success'];
        final double masteryChange = success ? 0.1 : -0.05;
        
        await _learningService.updateConceptMastery(
          conceptId: conceptId,
          performance: success ? 1.0 : 0.0,
        );
      }
      
      return validationResult;
    } catch (e) {
      _loggingService.error('Failed to validate solution: $e', tag: 'ChallengeService');
      
      // Return a basic validation result
      return {
        'success': false,
        'feedback': 'Unable to validate your solution. Please try again.',
        'error': e.toString(),
      };
    }
  }
  
  /// Update difficulty adjustment based on challenge results
  void _updateDifficultyAdjustment(bool success) {
    if (success) {
      // Increase difficulty slightly on success
      _difficultyAdjustment += 0.02;
    } else {
      // Decrease difficulty more significantly on failure
      _difficultyAdjustment -= 0.05;
    }
    
    // Clamp to reasonable range
    _difficultyAdjustment = _difficultyAdjustment.clamp(-0.3, 0.3);
    
    // Save the adjustment
    _saveDifficultyAdjustment();
    
    notifyListeners();
  }
  
  /// Reset difficulty adjustment to default
  Future<void> resetDifficultyAdjustment() async {
    _difficultyAdjustment = 0.0;
    await _saveDifficultyAdjustment();
    notifyListeners();
  }
  
  /// Get current difficulty adjustment
  double get difficultyAdjustment => _difficultyAdjustment;
  
  /// Clear challenge cache
  Future<void> clearChallengeCache() async {
    _challengeCache.clear();
    await _saveChallengeCache();
  }
} 