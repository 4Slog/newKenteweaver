import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';

/// Service for managing tutorials
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  
  TutorialService._internal();
  
  final Map<String, TutorialData> _tutorialCache = {};
  
  /// Load a tutorial by ID
  Future<TutorialData> loadTutorial(String tutorialId) async {
    // Check if tutorial is already cached
    if (_tutorialCache.containsKey(tutorialId)) {
      return _tutorialCache[tutorialId]!;
    }
    
    try {
      // Load tutorial data from JSON file
      final jsonString = await rootBundle.loadString('assets/documents/tutorials/$tutorialId.json');
      final jsonData = json.decode(jsonString);
      
      // Parse tutorial data
      final tutorialData = TutorialData.fromJson(jsonData);
      
      // Cache tutorial data
      _tutorialCache[tutorialId] = tutorialData;
      
      return tutorialData;
    } catch (e) {
      debugPrint('Error loading tutorial $tutorialId: $e');
      throw Exception('Failed to load tutorial: $tutorialId');
    }
  }
  
  /// Get tutorial steps from a string list
  /// Format: "Title|Description"
  List<TutorialStep> parseTutorialSteps(List<String> stepStrings, String tutorialId) {
    final steps = <TutorialStep>[];
    
    for (int i = 0; i < stepStrings.length; i++) {
      final parts = stepStrings[i].split('|');
      if (parts.length < 2) continue;
      
      final title = parts[0].trim();
      final description = parts[1].trim();
      
      steps.add(TutorialStep(
        id: '${tutorialId}_step_${i + 1}',
        title: title,
        description: description,
        type: _getTutorialStepType(i, stepStrings.length),
        imageAsset: null,
        hint: null,
      ));
    }
    
    return steps;
  }
  
  /// Get tutorial step type based on position
  TutorialStepType _getTutorialStepType(int index, int totalSteps) {
    if (index == 0) {
      return TutorialStepType.introduction;
    } else if (index == totalSteps - 1) {
      return TutorialStepType.challenge;
    } else if (index == 1) {
      return TutorialStepType.blockDragging;
    } else if (index == 2) {
      return TutorialStepType.colorSelection;
    } else if (index == 3) {
      return TutorialStepType.loopUsage;
    } else {
      return TutorialStepType.patternSelection;
    }
  }
  
  /// Get recommended tutorial for a difficulty level
  Future<String> getRecommendedTutorialId(PatternDifficulty difficulty) async {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 'basic_pattern_tutorial';
      case PatternDifficulty.intermediate:
        return 'intermediate_pattern_tutorial';
      case PatternDifficulty.advanced:
        return 'advanced_pattern_tutorial';
      case PatternDifficulty.expert:
        return 'master_pattern_tutorial';
    }
  }
  
  /// Get next tutorial ID
  Future<String?> getNextTutorialId(String currentTutorialId) async {
    try {
      final tutorial = await loadTutorial(currentTutorialId);
      return tutorial.nextTutorialId;
    } catch (e) {
      debugPrint('Error getting next tutorial: $e');
      return null;
    }
  }
}

/// Tutorial data model
class TutorialData {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String? targetAge;
  final int estimatedDuration;
  final List<String> prerequisites;
  final List<String> learningObjectives;
  final List<TutorialStep> steps;
  final String? nextTutorialId;
  final Map<String, dynamic> metadata;
  
  TutorialData({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.targetAge,
    required this.estimatedDuration,
    required this.prerequisites,
    required this.learningObjectives,
    required this.steps,
    this.nextTutorialId,
    required this.metadata,
  });
  
  factory TutorialData.fromJson(Map<String, dynamic> json) {
    return TutorialData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: json['difficulty'],
      targetAge: json['targetAge'],
      estimatedDuration: json['estimatedDuration'] ?? 10,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      learningObjectives: List<String>.from(json['learningObjectives'] ?? []),
      steps: (json['steps'] as List<dynamic>)
          .map((step) => TutorialStep.fromJson(step))
          .toList(),
      nextTutorialId: json['nextTutorialId'],
      metadata: json['metadata'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'targetAge': targetAge,
      'estimatedDuration': estimatedDuration,
      'prerequisites': prerequisites,
      'learningObjectives': learningObjectives,
      'steps': steps.map((step) => step.toJson()).toList(),
      'nextTutorialId': nextTutorialId,
      'metadata': metadata,
    };
  }
}

/// Tutorial step model
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final TutorialStepType type;
  final String? imageAsset;
  final String? hint;
  final Map<String, dynamic>? interactiveData;
  
  TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageAsset,
    this.hint,
    this.interactiveData,
  });
  
  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: _parseTutorialStepType(json['type']),
      imageAsset: json['imageAsset'],
      hint: json['hint'],
      interactiveData: json['interactiveData'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'imageAsset': imageAsset,
      'hint': hint,
      'interactiveData': interactiveData,
    };
  }
  
  static TutorialStepType _parseTutorialStepType(String? typeStr) {
    if (typeStr == null) return TutorialStepType.introduction;
    
    switch (typeStr.toLowerCase()) {
      case 'introduction':
        return TutorialStepType.introduction;
      case 'blockdragging':
        return TutorialStepType.blockDragging;
      case 'patternselection':
        return TutorialStepType.patternSelection;
      case 'colorselection':
        return TutorialStepType.colorSelection;
      case 'loopusage':
        return TutorialStepType.loopUsage;
      case 'rowcolumns':
        return TutorialStepType.rowColumns;
      case 'culturalcontext':
        return TutorialStepType.culturalContext;
      case 'challenge':
        return TutorialStepType.challenge;
      default:
        return TutorialStepType.introduction;
    }
  }
}

/// Tutorial step type
enum TutorialStepType {
  introduction,
  blockDragging,
  patternSelection,
  colorSelection,
  loopUsage,
  rowColumns,
  culturalContext,
  challenge,
}
