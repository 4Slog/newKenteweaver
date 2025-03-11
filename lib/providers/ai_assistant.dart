import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';

class AIAssistant extends ChangeNotifier {
  String _hintMessage = "Start coding to receive hints!";

  String get hintMessage => _hintMessage;

  // Method to generate AI-based hints
  void generateHint(String playerCode, PatternDifficulty difficulty) {
    if (playerCode.isEmpty) {
      _hintMessage = "Hint: Start by defining a loop to create a base pattern.";
    } else if (playerCode.contains("for") && !playerCode.contains("if")) {
      _hintMessage = "Hint: Try adding an 'if' statement to introduce color variation.";
    } else if (playerCode.contains("if") && playerCode.contains("for")) {
      _hintMessage = "Great progress! Now refine your loop parameters for symmetry.";
    } else {
      _hintMessage = "Keep experimenting! Try modifying the loop or color logic.";
    }

    notifyListeners();
  }

  // Reset hints when the user starts a new pattern
  void resetHint() {
    _hintMessage = "Start coding to receive hints!";
    notifyListeners();
  }
}
