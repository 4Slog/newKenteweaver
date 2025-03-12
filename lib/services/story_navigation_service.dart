import 'dart:async';
import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../models/user_progress.dart';
import 'gemini_story_service.dart';
import 'narration_service.dart';
import 'package:get_it/get_it.dart';

/// Service responsible for navigating through story nodes
class StoryNavigationService {
  /// The current story being navigated
  StoryModel? _currentStory;
  
  /// The current node being displayed
  StoryNode? _currentNode;
  
  /// Stream controller for the current node
  final StreamController<StoryNode?> _nodeController = StreamController<StoryNode?>.broadcast();
  
  /// Stream of the current node
  Stream<StoryNode?> get currentNodeStream => _nodeController.stream;
  
  /// The narration service for text-to-speech
  final NarrationService _narrationService = GetIt.instance<NarrationService>();
  
  /// The Gemini story service for generating story content
  final GeminiStoryService _geminiStoryService = GetIt.instance<GeminiStoryService>();
  
  /// History of visited nodes
  final List<String> _nodeHistory = [];
  
  /// Get the current story
  StoryModel? get currentStory => _currentStory;
  
  /// Get the current node
  StoryNode? get currentNode => _currentNode;
  
  /// Get the node history
  List<String> get nodeHistory => List.unmodifiable(_nodeHistory);
  
  /// Initialize the service with a story
  Future<void> initializeStory(StoryModel story) async {
    _currentStory = story;
    _nodeHistory.clear();
    await navigateToNode(story.startNodeId);
  }
  
  /// Navigate to a specific node by ID
  Future<bool> navigateToNode(String nodeId) async {
    if (_currentStory == null) {
      debugPrint('Cannot navigate: No story loaded');
      return false;
    }
    
    final StoryNode? node = _currentStory!.getNode(nodeId);
    if (node == null) {
      debugPrint('Cannot navigate: Node $nodeId not found');
      return false;
    }
    
    // Stop any ongoing narration
    await _narrationService.stop();
    
    // Update current node and notify listeners
    _currentNode = node;
    _nodeController.add(node);
    
    // Add to history
    _nodeHistory.add(nodeId);
    
    // Start narration of the new node
    _narrationService.speak(node.content);
    
    return true;
  }
  
  /// Navigate to the next node based on a choice
  Future<bool> makeChoice(StoryChoice choice) async {
    return navigateToNode(choice.nextNodeId);
  }
  
  /// Navigate back to the previous node
  Future<bool> goBack() async {
    if (_nodeHistory.length <= 1) {
      debugPrint('Cannot go back: At the beginning of history');
      return false;
    }
    
    // Remove current node from history
    _nodeHistory.removeLast();
    
    // Get the previous node ID
    final String previousNodeId = _nodeHistory.last;
    
    // Remove it from history (it will be added back in navigateToNode)
    _nodeHistory.removeLast();
    
    // Navigate to the previous node
    return navigateToNode(previousNodeId);
  }
  
  /// Generate a new story node based on user input
  Future<StoryNode?> generateStoryNode(String prompt, {StoryChapter? chapter}) async {
    try {
      final Map<String, dynamic> nodeData = await _geminiStoryService.generateStoryNode(
        prompt: prompt,
        chapter: chapter?.toString().split('.').last ?? 'introduction',
      );
      
      return StoryNode.fromJson(nodeData);
    } catch (e) {
      debugPrint('Error generating story node: $e');
      return null;
    }
  }
  
  /// Update user progress based on the current node
  Future<void> updateProgress(UserProgress progress) async {
    if (_currentNode == null || _currentStory == null) {
      return;
    }
    
    // Add the current node to completed nodes
    progress.addCompletedStoryNode(_currentStory!.id, _currentNode!.id);
    
    // Update any other progress metrics based on the node
    if (_currentNode!.lessonId != null) {
      progress.addCompletedLesson(_currentNode!.lessonId!);
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _narrationService.stop();
    _nodeController.close();
  }
} 