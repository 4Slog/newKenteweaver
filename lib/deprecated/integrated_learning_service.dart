import '../models/block_model.dart' show BlockCollection;
import '../models/pattern_model.dart' show PatternDifficulty;
import 'story_challenge_transition_service.dart';
import 'advanced_learning_service.dart';
import 'gemini_service.dart';
import '../utils/block_collection_converter.dart';
import 'dart:convert';

class IntegratedLearningService {
  final StoryChallengeTransitionService _transitionService;
  final AdvancedLearningService _learningService;
  final GeminiService _geminiService;
  
  IntegratedLearningService({
    required StoryChallengeTransitionService transitionService,
    required AdvancedLearningService learningService,
    required GeminiService geminiService,
  }) : _transitionService = transitionService,
       _learningService = learningService,
       _geminiService = geminiService;
  
  bool _isInTransition = false;

  Future<Map<String, dynamic>> progressStory({
    required String currentPoint,
    required Map<String, dynamic> learningContext,
  }) async {
    // Enhance story context with AI
    final prompt = '''
    Current story point: $currentPoint
    Learning context: ${jsonEncode(learningContext)}
    
    Analyze the current story progress and determine if a challenge is needed.
    Return response in JSON format:
    {
      "requires_challenge": true/false,
      "concept_id": "concept_to_test",
      "next_steps": "description of what should happen next"
    }
    ''';

    final response = await _geminiService.generateText(prompt);
    final enhancedContext = jsonDecode(response) as Map<String, dynamic>;

    // Check if we need to transition to a challenge
    if (enhancedContext['requires_challenge'] == true) {
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
    // Convert BlockCollection to learning model type
    final learningWorkspace = BlockCollectionConverter.toLearningModel(workspace);

    // Get personalized guidance
    final guidance = await _learningService.getPersonalizedGuidance(
      conceptId: context['concept_id'],
      storyContext: context['narrative'],
    );

    // Generate contextual response using pattern analysis
    final analysis = await _geminiService.analyzePattern(
      blocks: learningWorkspace.blocks,
      difficulty: workspace.metadata['difficulty'] ?? PatternDifficulty.basic,
    );

    // Update learning progress
    await _learningService.updateLearningProgress(
      conceptId: context['concept_id'],
      attempt: learningWorkspace,
      result: guidance,
      storyContext: context['narrative'],
    );

    return {
      'guidance': guidance,
      'analysis': analysis,
      'next_steps': guidance['suggestions'],
    };
  }

  Future<Map<String, dynamic>> validateAndProgress({
    required BlockCollection workspace,
    required Map<String, dynamic> context,
  }) async {
    if (_isInTransition) {
      // Convert BlockCollection to learning model type before passing to transition service
      final learningWorkspace = BlockCollectionConverter.toLearningModel(workspace);
      // Convert back to block_model.BlockCollection for the transition service
      final blockModelWorkspace = BlockCollectionConverter.toBlockModel(learningWorkspace);
      final result = await _transitionService.completeChallenge(
        solution: blockModelWorkspace,
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
