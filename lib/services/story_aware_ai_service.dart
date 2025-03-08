import 'package:flutter/material.dart';
import '../models/block_model.dart';
import 'gemini_service.dart';

class StoryAwareAIService {
  final GeminiService _geminiService;
  
  // Story context tracking
  String _currentNarrative = '';
  Map<String, dynamic> _characterContext = {};
  List<String> _storyThreads = [];
  
  Future<Map<String, dynamic>> enhanceStoryContext({
    required String storyPoint,
    required Map<String, dynamic> learningContext,
  }) async {
    // Update story context
    _currentNarrative = storyPoint;
    
    // Generate Kweku's personality adaptations
    final personalityContext = await _geminiService.generateMentorPersonality(
      storyContext: storyPoint,
      learningProgress: learningContext,
    );

    // Update character context
    _characterContext = personalityContext;

    // Track story threads
    _storyThreads = await _geminiService.identifyStoryThreads(
      narrative: storyPoint,
      learningGoals: learningContext['goals'],
    );

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
    return _geminiService.generateMentorResponse(
      trigger: trigger,
      workspace: workspace,
      storyContext: _currentNarrative,
      characterContext: _characterContext,
      learningState: learningState,
      storyThreads: _storyThreads,
    );
  }
} 