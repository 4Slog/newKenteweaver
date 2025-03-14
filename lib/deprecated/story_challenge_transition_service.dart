import 'package:flutter/material.dart';
import '../models/block_model.dart';
import 'story_progression_service.dart';
import 'adaptive_learning_service.dart';
import 'gemini_service.dart';

class StoryChallengeTransitionService {
  final StoryProgressionService _storyService;
  final AdaptiveLearningService _learningService;
  final GeminiService _geminiService;
  
  // Track transition states
  bool _isInChallenge = false;
  String? _activeTransitionId;
  Map<String, dynamic> _transitionContext = {};

  StoryChallengeTransitionService({
    required StoryProgressionService storyService,
    required AdaptiveLearningService learningService,
    required GeminiService geminiService,
  }) : _storyService = storyService,
       _learningService = learningService,
       _geminiService = geminiService;

  Future<Map<String, dynamic>> initiateChallenge({
    required String storyPoint,
    required String conceptId,
  }) async {
    _isInChallenge = true;
    _activeTransitionId = DateTime.now().toString();

    // Get story context and challenge requirements
    final challengeContext = await _storyService.prepareChallenge(storyPoint);
    
    // Get available blocks based on learning progress
    final availableBlocks = await _learningService.getContextualBlocks(
      conceptId: conceptId,
      challengeType: 'pattern',
    );

    // Get AI-enhanced introduction
    final introduction = await _geminiService.generateChallengeIntroduction(
      context: challengeContext,
      availableTools: availableBlocks,
    );

    _transitionContext = {
      'challenge_id': _activeTransitionId,
      'story_context': challengeContext,
      'available_blocks': availableBlocks,
      'introduction': introduction,
      'success_criteria': challengeContext['requirements'],
    };

    return _transitionContext;
  }

  Future<Map<String, dynamic>> completeChallenge({
    required BlockCollection solution,
  }) async {
    if (!_isInChallenge) {
      throw Exception('No active challenge to complete');
    }

    // Validate solution
    final result = await _storyService.validateChallenge(
      blocks: solution,
      challengeId: _activeTransitionId!,
    );

    if (result['success']) {
      // Generate transition back to story
      final transition = await _geminiService.generateChallengeCompletion(
        context: _transitionContext,
        solution: solution,
        result: result,
      );

      _isInChallenge = false;
      _activeTransitionId = null;

      return {
        'success': true,
        'transition': transition,
        'next_story_point': result['story_progression'],
      };
    }

    return {
      'success': false,
      'feedback': result['feedback'],
      'hints': result['hints'],
    };
  }
} 
