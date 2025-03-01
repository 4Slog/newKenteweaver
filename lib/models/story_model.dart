import 'package:flutter/foundation.dart';
import '../models/pattern_difficulty.dart'; // Updated import to match your structure (removed unused 'pattern_generator.dart')

enum StoryChapter {
  introduction,
  firstThread,
  repeatingPath,
  colorCode,
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

class StoryRequirement {
  final RequirementType type;
  final dynamic value;

  const StoryRequirement({
    required this.type,
    required this.value,
  });
}

enum RequirementType {
  level,
  challengeCompleted,
  patternCreated,
  achievement,
}

class StoryChoice {
  final String text;
  final String? targetNodeId;
  final String? challengeId;
  final StoryRequirement? requirement;

  const StoryChoice({
    required this.text,
    this.targetNodeId,
    this.challengeId,
    this.requirement,
  });
}

class StoryNode {
  final String id;
  final String title;
  final String content; // Made required to match story_service.dart usage
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

  const StoryNode({
    required this.id,
    required this.title,
    required this.content, // Ensure content is required
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
  });
}

class StoryProgress extends ChangeNotifier {
  StoryChapter _currentChapter = StoryChapter.introduction;
  String _currentNodeId = 'intro_1';
  Map<String, bool> _completedNodes = {};
  DifficultyLevel _difficulty = DifficultyLevel.easy;
  final Map<String, StoryNode> _nodes = {};

  StoryChapter get currentChapter => _currentChapter;
  String get currentNodeId => _currentNodeId;
  DifficultyLevel get difficulty => _difficulty;

  bool isNodeCompleted(String nodeId) => _completedNodes[nodeId] ?? false;

  void addNode(StoryNode node) {
    _nodes[node.id] = node;
  }

  Future<StoryNode?> getNode(String nodeId) async {
    return _nodes[nodeId];
  }

  Future<List<StoryChoice>> getAvailableChoices(StoryNode node) async {
    // Implementation would depend on your game logic
    return [];
  }

  void markNodeVisited(String nodeId) {
    _completedNodes[nodeId] = true;
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
      default:
        return null;
    }
  }

  void advanceStory(String nextNodeId) {
    _completedNodes[_currentNodeId] = true;
    _currentNodeId = nextNodeId;
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
    'difficulty': _difficulty.index,
  };

  void fromJson(Map<String, dynamic> json) {
    _currentChapter = StoryChapter.values[json['currentChapter']];
    _currentNodeId = json['currentNodeId'];
    _completedNodes = Map<String, bool>.from(json['completedNodes']);
    _difficulty = DifficultyLevel.values[json['difficulty']];
    notifyListeners();
  }
}