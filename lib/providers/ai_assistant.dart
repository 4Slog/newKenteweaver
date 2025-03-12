import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';

/// A provider for AI-powered assistance and hints
class AIAssistant extends ChangeNotifier {
  final GeminiService _geminiService;
  final StorageService _storageService;
  
  String _hintMessage = "Start coding to receive hints!";
  bool _isLoading = false;
  
  /// Whether the assistant is currently loading a hint
  bool get isLoading => _isLoading;
  
  /// The current hint message
  String get hintMessage => _hintMessage;
  
  // Cache for hints to reduce API calls
  final Map<String, Map<String, dynamic>> _hintCache = {};
  
  // Cache expiration time (24 hours in milliseconds)
  static const int _cacheExpirationTime = 24 * 60 * 60 * 1000;
  
  /// Creates a new instance of AIAssistant
  AIAssistant({
    required GeminiService geminiService,
    required StorageService storageService,
  }) : _geminiService = geminiService,
       _storageService = storageService {
    _loadCachedHints();
  }
  
  /// Loads cached hints from storage
  Future<void> _loadCachedHints() async {
    try {
      final cachedData = await _storageService.read('ai_hint_cache');
      if (cachedData != null) {
        final Map<String, dynamic> data = jsonDecode(cachedData);
        data.forEach((key, value) {
          _hintCache[key] = Map<String, dynamic>.from(value);
        });
      }
    } catch (e) {
      // Ignore errors when loading cache
    }
  }
  
  /// Saves cached hints to storage
  Future<void> _saveCachedHints() async {
    try {
      await _storageService.write('ai_hint_cache', jsonEncode(_hintCache));
    } catch (e) {
      // Ignore errors when saving cache
    }
  }
  
  /// Generates an AI-powered hint based on the player's code and difficulty level
  Future<void> generateHint(String playerCode, PatternDifficulty difficulty) async {
    if (playerCode.isEmpty) {
      _hintMessage = "Hint: Start by defining a loop to create a base pattern.";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check cache first
      final cacheKey = '${playerCode.hashCode}_${difficulty.toString()}';
      if (_hintCache.containsKey(cacheKey)) {
        final cachedHint = _hintCache[cacheKey];
        if (cachedHint != null) {
          final timestamp = cachedHint['timestamp'] as int;
          if (DateTime.now().millisecondsSinceEpoch - timestamp < _cacheExpirationTime) {
            _hintMessage = cachedHint['hint'] as String;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
      
      // Generate hint using Gemini API
      final hint = await _geminiService.generateCodeHint(
        code: playerCode,
        difficulty: difficulty,
      );
      
      _hintMessage = hint;
      
      // Cache the hint
      _hintCache[cacheKey] = {
        'hint': hint,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save cache
      await _saveCachedHints();
      
    } catch (e) {
      // Fallback to basic hints if API fails
      if (playerCode.contains("for") && !playerCode.contains("if")) {
        _hintMessage = "Hint: Try adding an 'if' statement to introduce color variation.";
      } else if (playerCode.contains("if") && playerCode.contains("for")) {
        _hintMessage = "Great progress! Now refine your loop parameters for symmetry.";
      } else {
        _hintMessage = "Keep experimenting! Try modifying the loop or color logic.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Generates a more detailed explanation of the player's code
  Future<String> generateExplanation(String playerCode) async {
    if (playerCode.isEmpty) {
      return "Start coding to get an explanation!";
    }
    
    try {
      return await _geminiService.generateCodeExplanation(playerCode);
    } catch (e) {
      return "I can't analyze your code right now. Please try again later.";
    }
  }

  /// Reset hints when the user starts a new pattern
  void resetHint() {
    _hintMessage = "Start coding to receive hints!";
    notifyListeners();
  }
}
