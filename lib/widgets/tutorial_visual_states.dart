import 'package:flutter/material.dart';
import '../models/tutorial_state.dart';

/// Controller for managing visual states during the tutorial
class TutorialVisualController extends ChangeNotifier {
  final ValueNotifier<double> workspaceOpacity = ValueNotifier(0.0);
  final ValueNotifier<double> blockScale = ValueNotifier(1.0);
  final ValueNotifier<double> highlightIntensity = ValueNotifier(0.0);
  TutorialState currentState = TutorialState.initial;
  double progress = 0.0;

  void updateState(TutorialState newState) {
    currentState = newState;
    
    switch (newState) {
      case TutorialState.initial:
        _resetState();
        break;
      case TutorialState.introduction:
        _handleIntroduction();
        break;
      case TutorialState.workspaceReveal:
        _handleWorkspaceReveal();
        break;
      case TutorialState.blockDragging:
        _handleBlockDragging();
        break;
      case TutorialState.patternSelection:
        _handlePatternSelection();
        break;
      case TutorialState.colorSelection:
        _handleColorSelection();
        break;
      case TutorialState.loopUsage:
        _handleLoopUsage();
        break;
      case TutorialState.rowColumns:
        _handleRowColumns();
        break;
      case TutorialState.culturalContext:
        _handleCulturalContext();
        break;
      case TutorialState.challenge:
        _handleChallenge();
        break;
      case TutorialState.complete:
        _handleComplete();
        break;
      case TutorialState.next:
        // Handle next state transition
        break;
    }
    
    notifyListeners();
  }

  void updateProgress(double value, {Curve curve = Curves.easeInOut}) {
    progress = value;
    notifyListeners();
  }

  void _resetState() {
    workspaceOpacity.value = 0.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.0;
  }

  void _handleIntroduction() {
    workspaceOpacity.value = 0.3;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.5;
  }

  void _handleWorkspaceReveal() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.8;
  }

  void _handleBlockDragging() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.1;
    highlightIntensity.value = 1.0;
  }

  void _handlePatternSelection() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.8;
  }

  void _handleColorSelection() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.8;
  }

  void _handleLoopUsage() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.1;
    highlightIntensity.value = 0.9;
  }

  void _handleRowColumns() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.1;
    highlightIntensity.value = 0.9;
  }

  void _handleCulturalContext() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.7;
  }

  void _handleChallenge() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.2;
    highlightIntensity.value = 1.0;
  }

  void _handleComplete() {
    workspaceOpacity.value = 1.0;
    blockScale.value = 1.0;
    highlightIntensity.value = 0.0;
  }
} 
