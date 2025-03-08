import 'package:flutter/material.dart';
import '../models/learning_progress_model.dart';
import 'gemini_service.dart';

class AdvancedLearningService {
  final GeminiService _geminiService;
  
  // Detailed learning tracking
  final Map<String, ConceptMastery> _conceptMastery = {};
  final Map<String, List<PracticeAttempt>> _practiceHistory = {};
  final Map<String, List<String>> _conceptDependencies = {};
  
  // Learning path optimization
  double _overallProgress = 0.0;
  Map<String, double> _conceptWeights = {};
  List<String> _adaptivePath = [];

  Future<void> updateLearningProgress({
    required String conceptId,
    required BlockCollection attempt,
    required Map<String, dynamic> result,
    required String storyContext,
  }) async {
    // Update concept mastery
    final mastery = _conceptMastery[conceptId] ??= ConceptMastery(conceptId);
    mastery.addAttempt(attempt, result);

    // Record practice history
    _practiceHistory[conceptId] ??= [];
    _practiceHistory[conceptId]!.add(
      PracticeAttempt(
        timestamp: DateTime.now(),
        blocks: attempt,
        result: result,
        storyContext: storyContext,
      ),
    );

    // Update learning path
    await _optimizeLearningPath();
  }

  Future<Map<String, dynamic>> getPersonalizedGuidance({
    required String conceptId,
    required String storyContext,
  }) async {
    final mastery = _conceptMastery[conceptId];
    final history = _practiceHistory[conceptId];

    return _geminiService.generatePersonalizedGuidance(
      conceptId: conceptId,
      mastery: mastery?.toJson(),
      history: history?.map((h) => h.toJson()).toList(),
      storyContext: storyContext,
    );
  }

  Future<void> _optimizeLearningPath() async {
    // Calculate concept dependencies
    for (final concept in _conceptMastery.keys) {
      final dependencies = await _geminiService.analyzeConceptDependencies(
        concept: concept,
        mastery: _conceptMastery[concept]!.toJson(),
      );
      _conceptDependencies[concept] = dependencies;
    }

    // Update concept weights based on dependencies and story progress
    _updateConceptWeights();

    // Generate optimized learning path
    _adaptivePath = await _geminiService.generateOptimizedPath(
      mastery: _conceptMastery,
      dependencies: _conceptDependencies,
      weights: _conceptWeights,
    );
  }
} 