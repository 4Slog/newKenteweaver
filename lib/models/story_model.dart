import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart';

/// Enum representing different story chapters
enum StoryChapter {
  introduction,
  firstThread,
  repeatingPath,
  colorCode,
  masterWeaver,
}

/// Enum representing types of requirements for accessing content
enum RequirementType {
  level,
  challengeCompleted,
  patternCreated,
  achievement,
  conceptMastered,
}

/// Enum representing types of content blocks in the story
enum ContentType {
  narration,
  dialogue,
  description,
  instruction,
  culturalContext,
  challenge,
  choicePoint,
}

/// Enum representing different challenge types
enum ChallengeType {
  blockArrangement,
  patternPrediction,
  codeOptimization,
  debugging,
  patternCreation,
  conceptExplanation,
}

/// Class representing a requirement to access a story node
class StoryRequirement {
  final RequirementType type;
  final dynamic value;

  const StoryRequirement({
    required this.type,
    required this.value,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'value': value,
    };
  }

  // Create from JSON
  factory StoryRequirement.fromJson(Map<String, dynamic> json) {
    return StoryRequirement(
      type: RequirementType.values.firstWhere(
          (e) => e.toString() == 'RequirementType.${json['type']}',
          orElse: () => RequirementType.level),
      value: json['value'],
    );
  }
}

/// Class representing a content block within a story node
class ContentBlock {
  final String id;
  final ContentType type;
  final String text;
  final String? speaker;
  final Map<String, dynamic>? ttsAttributes;
  final Map<String, dynamic>? additionalAttributes;

  const ContentBlock({
    required this.id,
    required this.type,
    required this.text,
    this.speaker,
    this.ttsAttributes,
    this.additionalAttributes,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'text': text,
      'speaker': speaker,
      'ttsAttributes': ttsAttributes,
      'additionalAttributes': additionalAttributes,
    };
  }

  // Create from JSON
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id'],
      type: ContentType.values.firstWhere(
          (e) => e.toString() == 'ContentType.${json['type']}',
          orElse: () => ContentType.narration),
      text: json['text'],
      speaker: json['speaker'],
      ttsAttributes: json['ttsAttributes'],
      additionalAttributes: json['additionalAttributes'],
    );
  }
}

/// Class representing a user choice in the story
class StoryChoice {
  final String id;
  final String text;
  final String? targetNodeId;
  final String? challengeId;
  final StoryRequirement? requirement;
  final Map<String, dynamic> consequences;
  final Map<String, dynamic>? codingChallenge;

  const StoryChoice({
    required this.text,
    this.id = '',
    this.targetNodeId,
    this.challengeId,
    this.requirement,
    this.consequences = const {},
    this.codingChallenge,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'targetNodeId': targetNodeId,
      'challengeId': challengeId,
      'requirement': requirement?.toJson(),
      'consequences': consequences,
      'codingChallenge': codingChallenge,
    };
  }

  // Create from JSON
  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      id: json['id'] ?? '',
      text: json['text'],
      targetNodeId: json['targetNodeId'],
      challengeId: json['challengeId'],
      requirement: json['requirement'] != null
          ? StoryRequirement.fromJson(json['requirement'])
          : null,
      consequences: json['consequences'] ?? {},
      codingChallenge: json['codingChallenge'],
    );
  }

  // Create legacy version for backwards compatibility
  factory StoryChoice.fromLegacy(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'],
      targetNodeId: json['targetNodeId'],
      challengeId: json['challengeId'],
      requirement: json['requirement'] != null
          ? StoryRequirement.fromJson(json['requirement'])
          : null,
    );
  }
}

/// Class representing a coding challenge within a story
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final PatternDifficulty difficulty;
  final List<String> conceptsTaught;
  final Map<String, dynamic> parameters;
  final List<String> hints;
  final Map<String, dynamic>? successCriteria;
  final Map<String, dynamic>? culturalContext;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    this.conceptsTaught = const [],
    this.parameters = const {},
    this.hints = const [],
    this.successCriteria,
    this.culturalContext,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'conceptsTaught': conceptsTaught,
      'parameters': parameters,
      'hints': hints,
      'successCriteria': successCriteria,
      'culturalContext': culturalContext,
    };
  }

  // Create from JSON
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ChallengeType.values.firstWhere(
          (e) => e.toString() == 'ChallengeType.${json['type']}',
          orElse: () => ChallengeType.blockArrangement),
      difficulty: PatternDifficulty.values.firstWhere(
          (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
          orElse: () => PatternDifficulty.basic),
      conceptsTaught: json['conceptsTaught'] != null
          ? List<String>.from(json['conceptsTaught'])
          : [],
      parameters: json['parameters'] ?? {},
      hints: json['hints'] != null ? List<String>.from(json['hints']) : [],
      successCriteria: json['successCriteria'],
      culturalContext: json['culturalContext'],
    );
  }
}

/// Class representing a node in the story
class StoryNode {
  final String id;
  final String title;
  final String content; // Legacy support
  final String? subtitle;
  final String? culturalContext;
  final StoryChapter chapter;
  final List<String> requiredPatterns;
  final Map<String, String> nextNodes;
  final String? hint;
  final bool isPremium;
  final String? lessonId;
  final PatternDifficulty difficulty;
  final String? backgroundImagePath;
  final String? characterImagePath;
  
  // New enhanced fields
  final List<ContentBlock>? contentBlocks;
  final List<StoryChoice>? choices;
  final Challenge? challenge;
  final Map<String, dynamic>? culturalContextData;
  final List<String>? conceptsTaught;

  const StoryNode({
    required this.id,
    required this.title,
    required this.content, // Keep for backward compatibility
    this.subtitle,
    this.culturalContext,
    required this.chapter,
    required this.requiredPatterns,
    required this.nextNodes,
    this.hint,
    this.isPremium = false,
    this.lessonId,
    this.difficulty = PatternDifficulty.basic,
    this.backgroundImagePath,
    this.characterImagePath,
    this.contentBlocks,
    this.choices,
    this.challenge,
    this.culturalContextData,
    this.conceptsTaught,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'subtitle': subtitle,
      'culturalContext': culturalContext,
      'chapter': chapter.toString().split('.').last,
      'requiredPatterns': requiredPatterns,
      'nextNodes': nextNodes,
      'hint': hint,
      'isPremium': isPremium,
      'lessonId': lessonId,
      'difficulty': difficulty.toString().split('.').last,
      'backgroundImagePath': backgroundImagePath,
      'characterImagePath': characterImagePath,
      'contentBlocks': contentBlocks?.map((block) => block.toJson()).toList(),
      'choices': choices?.map((choice) => choice.toJson()).toList(),
      'challenge': challenge?.toJson(),
      'culturalContextData': culturalContextData,
      'conceptsTaught': conceptsTaught,
    };
  }

  // Create from JSON
  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      subtitle: json['subtitle'],
      culturalContext: json['culturalContext'],
      chapter: StoryChapter.values.firstWhere(
          (e) => e.toString() == 'StoryChapter.${json['chapter']}',
          orElse: () => StoryChapter.introduction),
      requiredPatterns: json['requiredPatterns'] != null
          ? List<String>.from(json['requiredPatterns'])
          : [],
      nextNodes: json['nextNodes'] != null
          ? Map<String, String>.from(json['nextNodes'])
          : {},
      hint: json['hint'],
      isPremium: json['isPremium'] ?? false,
      lessonId: json['lessonId'],
      difficulty: PatternDifficulty.values.firstWhere(
          (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
          orElse: () => PatternDifficulty.basic),
      backgroundImagePath: json['backgroundImagePath'],
      characterImagePath: json['characterImagePath'],
      contentBlocks: json['contentBlocks'] != null
          ? (json['contentBlocks'] as List)
              .map((block) => ContentBlock.fromJson(block))
              .toList()
          : null,
      choices: json['choices'] != null
          ? (json['choices'] as List)
              .map((choice) => StoryChoice.fromJson(choice))
              .toList()
          : null,
      challenge: json['challenge'] != null
          ? Challenge.fromJson(json['challenge'])
          : null,
      culturalContextData: json['culturalContextData'],
      conceptsTaught: json['conceptsTaught'] != null
          ? List<String>.from(json['conceptsTaught'])
          : null,
    );
  }

  // Get the next node based on choice
  StoryNode? getNextNode(String choiceId, Map<String, StoryNode> allNodes) {
    // Check new choices first
    if (choices != null) {
      for (final choice in choices!) {
        if (choice.id == choiceId && choice.targetNodeId != null) {
          return allNodes[choice.targetNodeId];
        }
      }
    }
    
    // Legacy fallback
    if (nextNodes.containsKey(choiceId)) {
      return allNodes[nextNodes[choiceId]];
    }
    
    return null;
  }

  // Get next node after challenge based on result
  StoryNode? getNextNodeAfterChallenge(
      Map<String, dynamic> result, Map<String, StoryNode> allNodes) {
    final bool isSuccess = result['success'] ?? false;
    final String nextNodeKey = isSuccess ? 'success' : 'failure';
    
    if (nextNodes.containsKey(nextNodeKey)) {
      return allNodes[nextNodes[nextNodeKey]];
    }
    
    return null;
  }
}

/// Class representing a complete story model
class StoryModel {
  final String id;
  final String title;
  final String description;
  final PatternDifficulty difficulty;
  final List<String> learningConcepts;
  final StoryNode startNode;
  final Map<String, StoryNode> nodes;
  final List<Challenge> challenges;
  final bool isPremium;
  final String? imageAsset;
  final Map<String, dynamic>? metadata;

  const StoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.learningConcepts = const [],
    required this.startNode,
    required this.nodes,
    this.challenges = const [],
    this.isPremium = false,
    this.imageAsset,
    this.metadata,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'learningConcepts': learningConcepts,
      'startNodeId': startNode.id,
      'nodes': nodes.map((key, value) => MapEntry(key, value.toJson())),
      'challenges': challenges.map((challenge) => challenge.toJson()).toList(),
      'isPremium': isPremium,
      'imageAsset': imageAsset,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    // First parse all nodes
    final Map<String, StoryNode> parsedNodes = {};
    if (json['nodes'] != null) {
      (json['nodes'] as Map).forEach((key, value) {
        parsedNodes[key.toString()] = StoryNode.fromJson(value);
      });
    }

    // Get the start node
    final startNodeId = json['startNodeId'];
    if (startNodeId == null || !parsedNodes.containsKey(startNodeId)) {
      throw FormatException('Invalid or missing start node ID');
    }

    return StoryModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: PatternDifficulty.values.firstWhere(
          (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
          orElse: () => PatternDifficulty.basic),
      learningConcepts: json['learningConcepts'] != null
          ? List<String>.from(json['learningConcepts'])
          : [],
      startNode: parsedNodes[startNodeId]!,
      nodes: parsedNodes,
      challenges: json['challenges'] != null
          ? (json['challenges'] as List)
              .map((challenge) => Challenge.fromJson(challenge))
              .toList()
          : [],
      isPremium: json['isPremium'] ?? false,
      imageAsset: json['imageAsset'],
      metadata: json['metadata'],
    );
  }

  // Get a challenge by ID
  Challenge? getChallengeById(String challengeId) {
    try {
      return challenges.firstWhere((challenge) => challenge.id == challengeId);
    } catch (e) {
      return null;
    }
  }
}

/// Class for tracking story progress
class StoryProgress extends ChangeNotifier {
  StoryChapter _currentChapter = StoryChapter.introduction;
  String _currentNodeId = 'intro_1';
  Map<String, bool> _completedNodes = {};
  Map<String, List<String>> _choicesMade = {};
  Map<String, Map<String, dynamic>> _challengeResults = {};
  Set<String> _masteredConcepts = {};
  DifficultyLevel _difficulty = DifficultyLevel.easy;
  final Map<String, StoryNode> _nodes = {};

  StoryChapter get currentChapter => _currentChapter;
  String get currentNodeId => _currentNodeId;
  DifficultyLevel get difficulty => _difficulty;
  Set<String> get masteredConcepts => _masteredConcepts;
  Map<String, List<String>> get choicesMade => _choicesMade;

  bool isNodeCompleted(String nodeId) => _completedNodes[nodeId] ?? false;

  void addNode(StoryNode node) {
    _nodes[node.id] = node;
  }

  Future<StoryNode?> getNode(String nodeId) async {
    return _nodes[nodeId];
  }

  Future<List<StoryChoice>> getAvailableChoices(StoryNode node) async {
    // Use the new choices field if available
    if (node.choices != null && node.choices!.isNotEmpty) {
      return node.choices!;
    }
    
    // Legacy implementation (placeholder)
    return [];
  }

  void markNodeVisited(String nodeId) {
    _completedNodes[nodeId] = true;
    notifyListeners();
  }

  void recordChoice(String nodeId, String choiceId) {
    if (!_choicesMade.containsKey(nodeId)) {
      _choicesMade[nodeId] = [];
    }
    _choicesMade[nodeId]!.add(choiceId);
    notifyListeners();
  }

  void recordChallengeResult(String challengeId, Map<String, dynamic> result) {
    _challengeResults[challengeId] = result;
    notifyListeners();
  }

  void recordConceptMastery(List<String> concepts) {
    _masteredConcepts.addAll(concepts);
    notifyListeners();
  }

  String? getCurrentChapter() {
    switch (_currentChapter) {
      case StoryChapter.introduction:
        return 'Introduction';
      case StoryChapter.firstThread:
        return 'First Thread';
      case StoryChapter.repeatingPath:
        return 'Repeating Path';
      case StoryChapter.colorCode:
        return 'Color Code';
      case StoryChapter.masterWeaver:
        return 'Master Weaver';
      default:
        return null;
    }
  }

  void advanceStory(String nextNodeId) {
    _completedNodes[_currentNodeId] = true;
    _currentNodeId = nextNodeId;
    
    // Update chapter if the node belongs to a different chapter
    final nextNode = _nodes[nextNodeId];
    if (nextNode != null && nextNode.chapter != _currentChapter) {
      _currentChapter = nextNode.chapter;
    }
    
    notifyListeners();
  }

  void adjustDifficulty(DifficultyLevel newDifficulty) {
    _difficulty = newDifficulty;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'currentChapter': _currentChapter.index,
    'currentNodeId': _currentNodeId,
    'completedNodes': _completedNodes,
    'choicesMade': _choicesMade,
    'challengeResults': _challengeResults,
    'masteredConcepts': _masteredConcepts.toList(),
    'difficulty': _difficulty.index,
  };

  void fromJson(Map<String, dynamic> json) {
    _currentChapter = StoryChapter.values[json['currentChapter']];
    _currentNodeId = json['currentNodeId'];
    _completedNodes = Map<String, bool>.from(json['completedNodes']);
    
    // Parse choices with type safety
    if (json['choicesMade'] != null) {
      final Map<String, dynamic> choicesData = json['choicesMade'];
      choicesData.forEach((nodeId, choices) {
        _choicesMade[nodeId] = List<String>.from(choices);
      });
    }
    
    // Parse challenge results
    if (json['challengeResults'] != null) {
      final Map<String, dynamic> resultsData = json['challengeResults'];
      _challengeResults = resultsData.map((key, value) => 
          MapEntry(key, Map<String, dynamic>.from(value)));
    }
    
    // Parse mastered concepts
    if (json['masteredConcepts'] != null) {
      _masteredConcepts = Set<String>.from(json['masteredConcepts']);
    }
    
    _difficulty = DifficultyLevel.values[json['difficulty']];
    notifyListeners();
  }
}

/// Difficulty level enum for story
enum DifficultyLevel {
  easy,
  medium,
  hard,
}

/// Class representing a challenge result
class ChallengeResult {
  final bool success;
  final double score;
  final int timeTaken;
  final List<String> conceptsMastered;
  final Map<String, dynamic>? additionalData;

  const ChallengeResult({
    required this.success,
    required this.score,
    required this.timeTaken,
    this.conceptsMastered = const [],
    this.additionalData,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'score': score,
      'timeTaken': timeTaken,
      'conceptsMastered': conceptsMastered,
      'additionalData': additionalData,
    };
  }

  // Create from JSON
  factory ChallengeResult.fromJson(Map<String, dynamic> json) {
    return ChallengeResult(
      success: json['success'] ?? false,
      score: (json['score'] ?? 0.0).toDouble(),
      timeTaken: json['timeTaken'] ?? 0,
      conceptsMastered: json['conceptsMastered'] != null
          ? List<String>.from(json['conceptsMastered'])
          : [],
      additionalData: json['additionalData'],
    );
  }
}

/// Class for a story overview (for selection screens)
class StoryOverview {
  final String id;
  final String title;
  final String description;
  final PatternDifficulty difficulty;
  final bool isPremium;
  final String? imageAsset;
  final List<String> concepts;
  final Map<String, dynamic>? requirements;

  const StoryOverview({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    this.isPremium = false,
    this.imageAsset,
    this.concepts = const [],
    this.requirements,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'isPremium': isPremium,
      'imageAsset': imageAsset,
      'concepts': concepts,
      'requirements': requirements,
    };
  }

  // Create from JSON
  factory StoryOverview.fromJson(Map<String, dynamic> json) {
    return StoryOverview(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: PatternDifficulty.values.firstWhere(
          (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
          orElse: () => PatternDifficulty.basic),
      isPremium: json['isPremium'] ?? false,
      imageAsset: json['imageAsset'],
      concepts: json['concepts'] != null ? List<String>.from(json['concepts']) : [],
      requirements: json['requirements'],
    );
  }

  // Create from StoryModel
  factory StoryOverview.fromStoryModel(StoryModel model) {
    return StoryOverview(
      id: model.id,
      title: model.title,
      description: model.description,
      difficulty: model.difficulty,
      isPremium: model.isPremium,
      imageAsset: model.imageAsset,
      concepts: model.learningConcepts,
    );
  }
}