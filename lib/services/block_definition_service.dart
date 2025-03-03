import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';

class BlockDefinitionService {
  static final BlockDefinitionService _instance = BlockDefinitionService._internal();
  factory BlockDefinitionService() => _instance;

  BlockDefinitionService._internal();

  Map<String, dynamic> _blockDefinitions = {};
  List<Block> _parsedBlocks = [];
  bool _isLoaded = false;

  /// Load block definitions from assets
  Future<void> loadDefinitions() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/documents/blocks.json');
      _blockDefinitions = jsonDecode(jsonString);
      _parseBlockDefinitions();
      _isLoaded = true;
    } catch (e) {
      print('Error loading block definitions: $e');
      _blockDefinitions = {};
      _parsedBlocks = [];
    }
  }

  /// Parse the JSON into Block objects
  void _parseBlockDefinitions() {
    final blocksList = _blockDefinitions['blocks'] as List<dynamic>? ?? [];
    _parsedBlocks = blocksList.map<Block>((blockData) {
      return Block.fromJson(blockData);
    }).toList();
  }

  /// Get all blocks
  List<Block> getAllBlocks() {
    return List.from(_parsedBlocks);
  }

  /// Get blocks by type
  List<Block> getBlocksByType(BlockType type) {
    return _parsedBlocks.where((block) => block.type == type).toList();
  }

  /// Get blocks by difficulty
  List<Block> getBlocksByDifficulty(PatternDifficulty difficulty) {
    final difficultyStr = difficulty.toString().split('.').last;
    return _parsedBlocks.where((block) {
      final blockDifficulty = block.properties['difficulty'] ?? 'basic';
      return blockDifficulty == difficultyStr;
    }).toList();
  }

  /// Get pattern definitions
  List<Map<String, dynamic>> getPatternDefinitions() {
    return List<Map<String, dynamic>>.from(
        _blockDefinitions['patterns'] ?? []
    );
  }

  /// Get color definitions
  List<Map<String, dynamic>> getColorDefinitions() {
    return List<Map<String, dynamic>>.from(
        _blockDefinitions['colors'] ?? []
    );
  }

  /// Get difficulty level definitions
  List<Map<String, dynamic>> getDifficultyDefinitions() {
    return List<Map<String, dynamic>>.from(
        _blockDefinitions['difficultyLevels'] ?? []
    );
  }

  /// Get block by ID
  Block? getBlockById(String id) {
    try {
      return _parsedBlocks.firstWhere((block) => block.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get cultural meaning for a pattern
  String getCulturalMeaning(String patternType) {
    final patterns = getPatternDefinitions();
    for (final pattern in patterns) {
      if (pattern['id'] == patternType) {
        return pattern['culturalSignificance'] ?? '';
      }
    }
    return '';
  }

  /// Get cultural meaning for a color
  String getColorMeaning(String colorId) {
    final colors = getColorDefinitions();
    for (final color in colors) {
      if (color['id'] == colorId) {
        return color['culturalMeaning'] ?? '';
      }
    }
    return '';
  }

  /// Get blocks by category (pattern, color, structure)
  List<Block> getBlocksByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'pattern':
      case 'patterns':
      case 'pattern blocks':
        return getBlocksByType(BlockType.pattern);
      case 'color':
      case 'colors':
      case 'color blocks':
        return getBlocksByType(BlockType.color);
      case 'structure':
      case 'structures':
      case 'structure blocks':
        return _parsedBlocks.where((block) =>
        block.type == BlockType.structure ||
            block.type == BlockType.loop ||
            block.type == BlockType.row ||
            block.type == BlockType.column
        ).toList();
      default:
        return [];
    }
  }

  /// Filter blocks by difficulty and category
  List<Block> getFilteredBlocks({
    required PatternDifficulty difficulty,
    String category = '',
  }) {
    List<Block> filteredBlocks = [];

    // First filter by difficulty
    final difficultyBlocks = getBlocksByDifficulty(difficulty);

    // Then filter by category if specified
    if (category.isNotEmpty) {
      switch (category.toLowerCase()) {
        case 'pattern':
        case 'patterns':
        case 'pattern blocks':
          filteredBlocks = difficultyBlocks.where((block) =>
          block.type == BlockType.pattern
          ).toList();
          break;
        case 'color':
        case 'colors':
        case 'color blocks':
          filteredBlocks = difficultyBlocks.where((block) =>
          block.type == BlockType.color
          ).toList();
          break;
        case 'structure':
        case 'structures':
        case 'structure blocks':
          filteredBlocks = difficultyBlocks.where((block) =>
          block.type == BlockType.structure ||
              block.type == BlockType.loop ||
              block.type == BlockType.row ||
              block.type == BlockType.column
          ).toList();
          break;
        default:
          filteredBlocks = difficultyBlocks;
      }
    } else {
      filteredBlocks = difficultyBlocks;
    }

    return filteredBlocks;
  }

  /// Get default colors for a pattern
  List<Color> getDefaultColorsForPattern(String patternType) {
    final patterns = getPatternDefinitions();
    for (final pattern in patterns) {
      if (pattern['id'] == patternType) {
        final defaultColors = pattern['defaultColors'] as List<dynamic>? ?? [];
        return defaultColors.map<Color>((colorStr) {
          if (colorStr is String && colorStr.startsWith('#')) {
            return Color(int.parse('0xFF${colorStr.substring(1)}'));
          }
          return Colors.black;
        }).toList();
      }
    }
    return [Colors.black, Colors.white]; // Default fallback
  }

  /// Get min/max colors for a pattern
  Map<String, int> getColorLimitsForPattern(String patternType) {
    final patterns = getPatternDefinitions();
    for (final pattern in patterns) {
      if (pattern['id'] == patternType) {
        return {
          'min': pattern['minColors'] ?? 2,
          'max': pattern['maxColors'] ?? 4,
        };
      }
    }
    return {'min': 2, 'max': 4}; // Default fallback
  }

  /// Create a new block instance with unique ID
  Block createBlockInstance(String blockId) {
    final templateBlock = getBlockById(blockId);
    if (templateBlock == null) {
      throw Exception('Block template not found: $blockId');
    }

    // Create unique ID with timestamp
    final uniqueId = '${blockId}_${DateTime.now().millisecondsSinceEpoch}';

    // Clone the block with the new ID
    return templateBlock.copyWith(id: uniqueId);
  }

  /// Check if definitions are loaded
  bool get isLoaded => _isLoaded;

  /// Force reload definitions
  Future<void> reloadDefinitions() async {
    _isLoaded = false;
    await loadDefinitions();
  }
}