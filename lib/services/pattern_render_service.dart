import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../services/device_profile_service.dart';
import '../services/storage_service.dart';
import 'dart:convert';
import 'dart:math' as math;

class PatternRenderService extends ChangeNotifier {
  static final PatternRenderService _instance = PatternRenderService._internal();
  factory PatternRenderService() => _instance;
  
  PatternRenderService._internal();
  
  late DeviceProfileService _deviceProfileService;
  late StorageService _storageService;
  
  // Pattern cache for performance
  final Map<String, Map<String, dynamic>> _patternCache = {};
  
  // Kente pattern metadata with coding concepts
  final Map<String, Map<String, String>> _kentePatternInfo = {
    'adinkra_gye_nyame': {
      'name': 'Gye Nyame',
      'meaning': 'Symbol of God\'s supremacy',
      'difficulty': 'basic',
      'codeRelation': 'Basic sequences and symbols - Introduction to coding blocks',
      'conceptTaught': 'sequential_execution',
    },
    'kente_basic_lines': {
      'name': 'Basic Lines Pattern',
      'meaning': 'Foundation of Kente weaving',
      'difficulty': 'basic',
      'codeRelation': 'Simple loops - Repeating patterns',
      'conceptTaught': 'loops',
    },
    'fibonacci_pattern': {
      'name': 'Fibonacci Spiral',
      'meaning': 'Mathematical beauty in traditional patterns',
      'difficulty': 'intermediate',
      'codeRelation': 'Number sequences and mathematical patterns',
      'conceptTaught': 'variables_and_math',
    },
    'adinkra_sankofa': {
      'name': 'Sankofa Pattern',
      'meaning': 'Return and get it - Learn from the past',
      'difficulty': 'intermediate',
      'codeRelation': 'Functions and reusable code blocks',
      'conceptTaught': 'functions',
    },
    'kente_zigzag': {
      'name': 'ZigZag Pattern',
      'meaning': 'Life\'s ups and downs',
      'difficulty': 'basic',
      'codeRelation': 'Conditional statements - If-then patterns',
      'conceptTaught': 'conditionals',
    },
  };
  
  Future<void> initialize({
    required DeviceProfileService deviceProfileService,
    required StorageService storageService,
  }) async {
    _deviceProfileService = deviceProfileService;
    _storageService = storageService;
    await _loadPatternCache();
  }
  
  Future<void> _loadPatternCache() async {
    try {
      final savedPatterns = await _storageService.read('pattern_cache');
      if (savedPatterns != null) {
        final Map<String, dynamic> patterns = jsonDecode(savedPatterns);
        _patternCache.clear();
        patterns.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _patternCache[key] = value;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading pattern cache: $e');
    }
  }
  
  Future<Map<String, dynamic>> renderPattern({
    required String patternId,
    required List<Map<String, dynamic>> blocks,
    required Size previewSize,
  }) async {
    if (_patternCache.containsKey(patternId)) {
      return _patternCache[patternId]!;
    }
    
    final pattern = await _generatePattern(blocks, previewSize);
    _patternCache[patternId] = pattern;
    return pattern;
  }
  
  Future<Map<String, dynamic>> _generatePattern(
    List<Map<String, dynamic>> blocks,
    Size previewSize,
  ) async {
    final patternData = <String, dynamic>{
      'grid': [],
      'colors': [],
      'size': {'width': previewSize.width, 'height': previewSize.height},
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Convert blocks to pattern grid
    final grid = List.generate(
      (previewSize.height ~/ 20).toInt(),
      (y) => List.generate(
        (previewSize.width ~/ 20).toInt(),
        (x) => 0,
      ),
    );

    // Process blocks to generate pattern
    for (final block in blocks) {
      final type = block['type'] as String?;
      final params = block['parameters'] as Map<String, dynamic>?;
      
      switch (type) {
        case 'repeat':
          _applyRepeatPattern(grid, params);
          break;
        case 'zigzag':
          _applyZigzagPattern(grid, params);
          break;
        case 'spiral':
          _applySpiralPattern(grid, params);
          break;
        case 'symbol':
          _applySymbolPattern(grid, params);
          break;
      }
    }

    patternData['grid'] = grid;
    return patternData;
  }

  void _applyRepeatPattern(List<List<int>> grid, Map<String, dynamic>? params) {
    final count = params?['count'] as int? ?? 4;
    final pattern = params?['pattern'] as List? ?? [1, 0, 1, 0];
    
    for (var y = 0; y < grid.length; y++) {
      for (var x = 0; x < grid[y].length; x++) {
        grid[y][x] = pattern[x % pattern.length];
      }
    }
  }

  void _applyZigzagPattern(List<List<int>> grid, Map<String, dynamic>? params) {
    final amplitude = params?['amplitude'] as int? ?? 2;
    final period = params?['period'] as int? ?? 4;
    
    for (var x = 0; x < grid[0].length; x++) {
      final y = (amplitude * math.sin(x * 2 * math.pi / period)).round() + grid.length ~/ 2;
      if (y >= 0 && y < grid.length) {
        grid[y][x] = 1;
      }
    }
  }

  void _applySpiralPattern(List<List<int>> grid, Map<String, dynamic>? params) {
    final centerX = grid[0].length ~/ 2;
    final centerY = grid.length ~/ 2;
    final maxRadius = math.min(centerX, centerY);
    
    for (var r = 0; r < maxRadius; r++) {
      final angle = r * 0.5;
      final x = (centerX + r * math.cos(angle)).round();
      final y = (centerY + r * math.sin(angle)).round();
      
      if (x >= 0 && x < grid[0].length && y >= 0 && y < grid.length) {
        grid[y][x] = 1;
      }
    }
  }

  void _applySymbolPattern(List<List<int>> grid, Map<String, dynamic>? params) {
    final symbol = params?['symbol'] as String? ?? 'gye_nyame';
    // Will be expanded with actual symbol patterns
    // For now, just create a simple cross pattern
    final centerX = grid[0].length ~/ 2;
    final centerY = grid.length ~/ 2;
    
    for (var x = 0; x < grid[0].length; x++) {
      grid[centerY][x] = 1;
    }
    for (var y = 0; y < grid.length; y++) {
      grid[y][centerX] = 1;
    }
  }
  
  Map<String, String>? getPatternInfo(String patternId) {
    return _kentePatternInfo[patternId];
  }
  
  List<String> getAvailablePatterns() {
    return _kentePatternInfo.keys.toList();
  }
  
  String? getConceptForPattern(String patternId) {
    return _kentePatternInfo[patternId]?['conceptTaught'];
  }
  
  void clearCache() {
    _patternCache.clear();
    notifyListeners();
  }
  
  Future<void> savePattern(String patternId, Map<String, dynamic> pattern) async {
    try {
      _patternCache[patternId] = pattern;
      
      // Save to storage
      final allPatterns = Map<String, dynamic>.from(_patternCache);
      await _storageService.write(
        'pattern_cache',
        jsonEncode(allPatterns),
      );
      
      // Update device profile
      final profile = _deviceProfileService.currentProfile;
      if (profile != null) {
        final progress = profile.progress;
        if (!progress.unlockedPatterns.contains(patternId)) {
          final updatedProgress = progress.copyWith(
            unlockedPatterns: [...progress.unlockedPatterns, patternId],
          );
          await _deviceProfileService.updateProgress(updatedProgress);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving pattern: $e');
      throw Exception('Failed to save pattern: $e');
    }
  }
  
  Future<void> deletePattern(String patternId) async {
    try {
      _patternCache.remove(patternId);
      
      // Update storage
      final allPatterns = Map<String, dynamic>.from(_patternCache);
      await _storageService.write(
        'pattern_cache',
        jsonEncode(allPatterns),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting pattern: $e');
      throw Exception('Failed to delete pattern: $e');
    }
  }
  
  List<String> getUnlockedPatterns() {
    final profile = _deviceProfileService.currentProfile;
    if (profile == null) return [];
    return profile.progress.unlockedPatterns;
  }
  
  bool isPatternUnlocked(String patternId) {
    final profile = _deviceProfileService.currentProfile;
    if (profile == null) return false;
    return profile.progress.unlockedPatterns.contains(patternId);
  }
  
  Future<Map<String, dynamic>?> getPattern(String patternId) async {
    if (_patternCache.containsKey(patternId)) {
      return _patternCache[patternId];
    }
    return null;
  }
} 