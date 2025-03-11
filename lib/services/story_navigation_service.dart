import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../models/audio_model.dart' as audio;
import '../services/story_engine_service.dart';
import '../services/audio_service.dart';

/// Service for managing story-based navigation and transitions
class StoryNavigationService extends ChangeNotifier {
  final StoryEngineService _storyEngine;
  final AudioService _audioService;
  final List<String> _navigationHistory = [];
  String? _currentNodeId;
  
  StoryNavigationService({
    required StoryEngineService storyEngine,
    required AudioService audioService,
  })  : _storyEngine = storyEngine,
        _audioService = audioService;
  
  /// Get the current node ID
  String? get currentNodeId => _currentNodeId;
  
  /// Get the navigation history
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  
  /// Navigate to a story node
  Future<void> navigateToNode(String nodeId) async {
    if (_currentNodeId != null) {
      _navigationHistory.add(_currentNodeId!);
    }
    _currentNodeId = nodeId;

    final node = await _storyEngine.getNode(nodeId);
    if (node.backgroundMusic != null) {
      final audioType = audio.AudioType.values.firstWhere(
        (type) => type.filename == node.backgroundMusic,
        orElse: () => audio.AudioType.storyTheme,
      );
      await _audioService.playMusic(audioType);
    }

    notifyListeners();
  }
  
  /// Navigate to the previous node
  Future<bool> navigateBack() async {
    if (_navigationHistory.isEmpty) {
      return false;
    }

    final previousNode = _navigationHistory.removeLast();
    _currentNodeId = previousNode;
    
    final node = await _storyEngine.getNode(previousNode);
    if (node.backgroundMusic != null) {
      final audioType = audio.AudioType.values.firstWhere(
        (type) => type.filename == node.backgroundMusic,
        orElse: () => audio.AudioType.storyTheme,
      );
      await _audioService.playMusic(audioType);
    }

    notifyListeners();
    return true;
  }
  
  /// Start a new story
  Future<void> startStory(String initialNodeId) async {
    _navigationHistory.clear();
    await navigateToNode(initialNodeId);
  }
  
  /// Handle a story choice
  Future<void> handleChoice(StoryChoice choice) async {
    await navigateToNode(choice.nextNodeId);
  }
  
  /// Reset navigation state
  void reset() {
    _navigationHistory.clear();
    _currentNodeId = null;
    _audioService.stopMusic();
    notifyListeners();
  }
} 