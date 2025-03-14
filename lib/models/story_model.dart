import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'pattern_difficulty.dart';

/// Represents a chapter in a story
enum StoryChapter {
  introduction,
  basics,
  intermediate,
  advanced,
  conclusion,
}

/// Represents a choice in a story node
class StoryChoice {
  /// The unique identifier for the choice
  final String id;
  
  /// The text of the choice
  final String text;
  
  /// The ID of the next node to navigate to
  final String nextNodeId;
  
  /// Optional consequences of making this choice
  final Map<String, dynamic>? consequences;
  
  /// Optional coding challenge associated with this choice
  final Map<String, dynamic>? codingChallenge;
  
  /// Creates a new StoryChoice
  const StoryChoice({
    required this.id,
    required this.text,
    required this.nextNodeId,
    this.consequences,
    this.codingChallenge,
  });
  
  /// Creates a StoryChoice from a JSON object
  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      id: json['id'] as String,
      text: json['text'] as String,
      nextNodeId: json['nextNodeId'] as String,
      consequences: json['consequences'] as Map<String, dynamic>?,
      codingChallenge: json['codingChallenge'] as Map<String, dynamic>?,
    );
  }
  
  /// Converts the StoryChoice to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'nextNodeId': nextNodeId,
      if (consequences != null) 'consequences': consequences,
      if (codingChallenge != null) 'codingChallenge': codingChallenge,
    };
  }
}

/// Represents a node in a story
class StoryNode {
  /// The unique identifier for the node
  final String id;
  
  /// The title of the node
  final String title;
  
  /// The subtitle of the node (optional)
  final String? subtitle;
  
  /// The main content of the node
  final String content;
  
  /// Optional cultural context information
  final String? culturalContext;
  
  /// The chapter this node belongs to
  final StoryChapter chapter;
  
  /// The patterns required to complete this node
  final List<String> requiredPatterns;
  
  /// The next nodes that can be navigated to
  final Map<String, String> nextNodes;
  
  /// Optional hint for the user
  final String? hint;
  
  /// Whether this node is premium content
  final bool isPremium;
  
  /// Optional lesson ID associated with this node
  final String? lessonId;
  
  /// The difficulty level of this node
  final PatternDifficulty? difficulty;
  
  /// Optional background music filename
  final String? backgroundMusic;
  
  /// Creates a new StoryNode
  const StoryNode({
    required this.id,
    required this.title,
    this.subtitle,
    required this.content,
    this.culturalContext,
    required this.chapter,
    required this.requiredPatterns,
    required this.nextNodes,
    this.hint,
    this.isPremium = false,
    this.lessonId,
    this.difficulty,
    this.backgroundMusic,
  });
  
  /// Creates a StoryNode from a JSON object
  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String,
      culturalContext: json['culturalContext'] as String?,
      chapter: _parseChapter(json['chapter'] as String?),
      requiredPatterns: (json['requiredPatterns'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      nextNodes: (json['nextNodes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)) ?? {},
      hint: json['hint'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      lessonId: json['lessonId'] as String?,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      backgroundMusic: json['backgroundMusic'] as String?,
    );
  }
  
  /// Converts the StoryNode to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      'content': content,
      if (culturalContext != null) 'culturalContext': culturalContext,
      'chapter': chapter.toString().split('.').last,
      'requiredPatterns': requiredPatterns,
      'nextNodes': nextNodes,
      if (hint != null) 'hint': hint,
      'isPremium': isPremium,
      if (lessonId != null) 'lessonId': lessonId,
      if (difficulty != null) 'difficulty': difficulty.toString().split('.').last,
      if (backgroundMusic != null) 'backgroundMusic': backgroundMusic,
    };
  }
  
  /// Parse a chapter string into a StoryChapter enum
  static StoryChapter _parseChapter(String? chapterStr) {
    if (chapterStr == null) return StoryChapter.introduction;
    
    try {
      return StoryChapter.values.firstWhere(
        (e) => e.toString().split('.').last == chapterStr,
        orElse: () => StoryChapter.introduction,
      );
    } catch (_) {
      return StoryChapter.introduction;
    }
  }
  
  /// Parse a difficulty string into a PatternDifficulty enum
  static PatternDifficulty? _parseDifficulty(String? difficultyStr) {
    if (difficultyStr == null) return null;
    
    try {
      return PatternDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == difficultyStr,
        orElse: () => PatternDifficulty.basic,
      );
    } catch (_) {
      return PatternDifficulty.basic;
    }
  }
}

/// Represents a complete story
class StoryModel {
  /// The unique identifier for the story
  final String id;
  
  /// The title of the story
  final String title;
  
  /// The description of the story
  final String description;
  
  /// The difficulty level of the story
  final PatternDifficulty difficulty;
  
  /// The nodes in the story
  final List<StoryNode> nodes;
  
  /// The ID of the starting node
  final String startNodeId;
  
  /// Creates a new StoryModel
  const StoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.nodes,
    required this.startNodeId,
  });
  
  /// Creates a StoryModel from a JSON object
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      nodes: (json['nodes'] as List<dynamic>)
          .map((e) => StoryNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      startNodeId: json['startNodeId'] as String,
    );
  }
  
  /// Converts the StoryModel to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'nodes': nodes.map((e) => e.toJson()).toList(),
      'startNodeId': startNodeId,
    };
  }
  
  /// Parse a difficulty string into a PatternDifficulty enum
  static PatternDifficulty _parseDifficulty(String? difficultyStr) {
    if (difficultyStr == null) return PatternDifficulty.basic;
    
    try {
      return PatternDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == difficultyStr,
        orElse: () => PatternDifficulty.basic,
      );
    } catch (_) {
      return PatternDifficulty.basic;
    }
  }
  
  /// Get a node by ID
  StoryNode? getNode(String nodeId) {
    try {
      return nodes.firstWhere((node) => node.id == nodeId);
    } catch (_) {
      return null;
    }
  }
} 