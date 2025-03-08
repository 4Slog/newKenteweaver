import 'package:flutter/material.dart';
import '../models/block_model.dart';
import 'story_challenge_transition_service.dart';
import 'advanced_learning_service.dart';
import 'story_aware_ai_service.dart';

class IntegratedLearningService {
  final StoryChallengeTransitionService _transitionService;
  final AdvancedLearningService _learningService;
  final StoryAwareAIService _aiService;
  
  // Integration state
  Map<String, dynamic> _currentState = {};
  bool _isInTransition = false;

  Future<Map<String, dynamic>> progressStory({
    required String currentPoint,
    required Map<String, dynamic> learningContext,
  }) async {
    // Enhance story context with AI
    final enhancedContext = await _aiService.enhanceStoryContext(
      storyPoint: currentPoint,
      learningContext: learningContext,
    );

    // Check if we need to transition to a challenge
    if (enhancedContext['requires_challenge']) {
      _isInTransition = true;
      return await _transitionService.initiateChallenge(
        storyPoint: currentPoint,
        conceptId: enhancedContext['concept_id'],
      );
    }

    // Continue with story
    return enhancedContext;
  }

  Future<Map<String, dynamic>> handleWorkspaceAction({
    required String action,
    required BlockCollection workspace,
    required Map<String, dynamic> context,
  }) async {
    // Get personalized guidance
    final guidance = await _learningService.getPersonalizedGuidance(
      conceptId: context['concept_id'],
      storyContext: context['narrative'],
    );

    // Generate contextual response
    final response = await _aiService.generateContextualResponse(
      trigger: action,
      workspace: workspace,
      learningState: guidance,
    );

    // Update learning progress
    await _learningService.updateLearningProgress(
      conceptId: context['concept_id'],
      attempt: workspace,
      result: guidance,
      storyContext: context['narrative'],
    );

    return {
      'guidance': guidance,
      'response': response,
      'next_steps': guidance['suggestions'],
    };
  }

  Future<Map<String, dynamic>> validateAndProgress({
    required BlockCollection workspace,
    required Map<String, dynamic> context,
  }) async {
    if (_isInTransition) {
      final result = await _transitionService.completeChallenge(
        solution: workspace,
      );

      if (result['success']) {
        _isInTransition = false;
        return result;
      }

      return result;
    }

    return await handleWorkspaceAction(
      action: 'validate',
      workspace: workspace,
      context: context,
    );
  }
} 