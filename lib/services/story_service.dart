import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/story_model.dart';
import '../models/pattern_difficulty.dart';
import '../providers/user_provider.dart';

class StoryService {
  Future<StoryNode> getNode(String nodeId) async {
    final String data = await rootBundle.loadString('assets/data/story.json');
    final Map<String, dynamic> jsonData = jsonDecode(data);
    final List<dynamic> nodes = jsonData['nodes'];

    final nodeData = nodes.firstWhere(
          (node) => node['id'] == nodeId,
      orElse: () => <String, dynamic>{
        'id': nodeId,
        'title': 'Not Found',
        'content': 'Node not found',
        'chapter': 'introduction',
      },
    );

    if (nodeData['id'] == nodeId && nodeData['title'] == 'Not Found') {
      return StoryNode(
        id: nodeId,
        title: 'Not Found',
        content: 'Node not found',
        chapter: StoryChapter.introduction,
        nextNodes: const {},
        requiredPatterns: const [],
      );
    }

    return StoryNode(
      id: nodeData['id'],
      title: nodeData['title'],
      content: nodeData['content'],
      subtitle: nodeData['subtitle'],
      culturalContext: nodeData['culturalContext'],
      chapter: StoryChapter.values.firstWhere(
            (e) => e.toString() == 'StoryChapter.${nodeData['chapter']}',
        orElse: () => StoryChapter.introduction,
      ),
      requiredPatterns: List<String>.from(nodeData['requiredPatterns'] ?? []),
      nextNodes: Map<String, String>.from(nodeData['nextNodes'] ?? {}),
      hint: nodeData['hint'],
      isPremium: nodeData['isPremium'] ?? false,
      lessonId: nodeData['lessonId'],
      difficulty: PatternDifficulty.values.firstWhere(
            (e) => e.toString() == 'PatternDifficulty.${nodeData['difficulty']}',
        orElse: () => PatternDifficulty.basic,
      ),
      backgroundImagePath: nodeData['backgroundImagePath'],
      characterImagePath: nodeData['characterImagePath'],
    );
  }

  Future<List<StoryChoice>> getAvailableChoices(StoryNode node, UserProvider userProvider) async {
    List<StoryChoice> choices = [];

    for (final entry in node.nextNodes.entries) {
      final nextNodeId = entry.value;
      final targetNode = await getNode(nextNodeId);

      choices.add(StoryChoice(
        text: targetNode.title,
        targetNodeId: nextNodeId,
        challengeId: null,
        requirement: _createRequirementForNode(targetNode),
      ));
    }

    // Filter choices based on user progress
    choices = choices.where((choice) {
      if (choice.requirement == null) return true;
      return _checkRequirement(choice.requirement!, userProvider);
    }).toList();

    return choices;
  }

  StoryRequirement? _createRequirementForNode(StoryNode node) {
    if (node.isPremium) {
      return const StoryRequirement(
        type: RequirementType.achievement,
        value: 'premium_member',
      );
    }

    if (node.difficulty == PatternDifficulty.advanced) {
      return const StoryRequirement(
        type: RequirementType.level,
        value: 5,
      );
    }

    return null;
  }

  bool _checkRequirement(StoryRequirement requirement, UserProvider userProvider) {
    switch (requirement.type) {
      case RequirementType.level:
        final requiredLevel = requirement.value as int;
        return userProvider.level >= requiredLevel;
      case RequirementType.challengeCompleted:
        final challengeId = requirement.value as String;
        return userProvider.hasCompletedChallenge(challengeId);
      case RequirementType.patternCreated:
        final patternId = requirement.value as String;
        return userProvider.hasCreatedPattern(patternId);
      case RequirementType.achievement:
        final achievementId = requirement.value as String;
        return userProvider.hasAchievement(achievementId);
      case RequirementType.conceptMastered:
        final conceptId = requirement.value as String;
        return userProvider.hasConceptMastered(conceptId);
    }
  }
}
