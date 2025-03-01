import 'package:flutter/material.dart';
import '../models/block_model.dart';
// Fixed import path
import '../services/unified/pattern_engine.dart';

class AIExecutor {
  final PatternEngine patternEngine;
  
  AIExecutor({PatternEngine? engine}) 
      : patternEngine = engine ?? PatternEngine();

  /// Executes AI-generated weaving pattern and returns structured data
  Future<Map<String, dynamic>> executeWeavingPattern(Map<String, dynamic> patternData) async {
    if (patternData.isEmpty) {
      return {"error": "No pattern data received from AI."};
    }

    // Simulate AI-based pattern execution with a delay
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // Extract block definitions from AI-generated data
      final blockDefinitions = patternData['blocks'] as List<dynamic>? ?? [];
      
      // Convert AI definitions to Block objects
      final blocks = blockDefinitions.map<Block>((blockData) {
        final type = _getBlockTypeFromString(blockData['type']);
        
        return Block(
          id: blockData['id'] ?? 'block_${DateTime.now().millisecondsSinceEpoch}',
          name: blockData['name'] ?? 'Unnamed Block',
          description: blockData['description'] ?? '',
          type: type,
          subtype: blockData['subtype'] ?? blockData['type'],
          properties: blockData['properties'] ?? {},
          connections: _createConnectionsFromData(
            blockData['connections'] ?? [],
            type,
          ),
          iconPath: blockData['iconPath'] ?? 'assets/images/blocks/default.png',
          color: _getColorFromData(blockData['color']),
        );
      }).toList();
      
      // Create connections between blocks
      final connectionData = patternData['connections'] as List<dynamic>? ?? [];
      final blockCollection = _createConnectedBlockCollection(blocks, connectionData);
      
      // Generate pattern using the pattern engine
      final rows = patternData['grid_size']?['rows'] ?? 16;
      final columns = patternData['grid_size']?['columns'] ?? 16;
      
      final pattern = patternEngine.generatePatternFromBlocks(
        blockCollection,
        rows: rows,
        columns: columns,
      );
      
      // Convert pattern to color grid for rendering
      final gridData = _patternToGridData(pattern);
      
      return {
        "status": "success",
        "blockCollection": blockCollection,
        "executedPattern": {
          "grid": gridData,
          "gridSize": rows,
          "scale": patternData['scale'] ?? 1.0,
        },
        "properties": patternData['properties'] ?? {},
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Error executing AI pattern: $e",
      };
    }
  }
  
  List<List<String>> _patternToGridData(List<List<Color>> pattern) {
    return pattern.map((row) {
      return row.map((color) {
        // Fixed deprecated value usage
        final colorValue = color.value.toRadixString(16).substring(2);
        return '#$colorValue';
      }).toList();
    }).toList();
  }
  
  BlockType _getBlockTypeFromString(String typeStr) {
    if (typeStr.startsWith('pattern') || typeStr.contains('_pattern')) {
      return BlockType.pattern;
    }
    if (typeStr.startsWith('color') || typeStr.startsWith('shuttle_')) {
      return BlockType.color;
    }
    if (typeStr == 'loop' || typeStr == 'loop_block') {
      return BlockType.loop;
    }
    if (typeStr == 'row' || typeStr == 'row_block') {
      return BlockType.row;
    }
    if (typeStr == 'column' || typeStr == 'column_block') {
      return BlockType.column;
    }
    return BlockType.structure;
  }
  
  List<BlockConnection> _createConnectionsFromData(
    List<dynamic> connectionsData,
    BlockType blockType,
  ) {
    if (connectionsData.isNotEmpty) {
      return connectionsData.map<BlockConnection>((connData) {
        return BlockConnection(
          id: connData['id'] ?? 'conn_${DateTime.now().millisecondsSinceEpoch}',
          name: connData['name'] ?? '',
          type: _getConnectionTypeFromString(connData['type']),
          position: Offset(
            connData['position']?['x']?.toDouble() ?? 0.5,
            connData['position']?['y']?.toDouble() ?? 0.5,
          ),
          connectedToId: connData['connectedToId'],
        );
      }).toList();
    }
    
    // Default connections based on block type
    final connections = <BlockConnection>[];
    
    // Add input connection for most blocks except pattern and color
    if (blockType != BlockType.pattern && blockType != BlockType.color) {
      connections.add(BlockConnection(
        id: 'input_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Input',
        type: ConnectionType.input,
        position: const Offset(0, 0.5),
      ));
    }
    
    // Add output connection for most blocks
    connections.add(BlockConnection(
      id: 'output_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Output',
      type: ConnectionType.output,
      position: const Offset(1, 0.5),
    ));
    
    // Special connection for loop blocks
    if (blockType == BlockType.loop) {
      connections.add(BlockConnection(
        id: 'body_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Body',
        type: ConnectionType.output,
        position: const Offset(0.5, 1),
      ));
    }
    
    return connections;
  }
  
  ConnectionType _getConnectionTypeFromString(String? typeStr) {
    switch (typeStr) {
      case 'input':
        return ConnectionType.input;
      case 'output':
        return ConnectionType.output;
      case 'both':
        return ConnectionType.both;
      default:
        return ConnectionType.none;
    }
  }
  
  Color _getColorFromData(dynamic colorData) {
    if (colorData is int) {
      return Color(colorData);
    } else if (colorData is String) {
      if (colorData.startsWith('#')) {
        return Color(int.parse('0xFF${colorData.substring(1)}'));
      } else if (colorData.startsWith('0x')) {
        return Color(int.parse(colorData));
      }
    }
    return Colors.grey;
  }
  
  BlockCollection _createConnectedBlockCollection(
    List<Block> blocks,
    List<dynamic> connectionData,
  ) {
    final collection = BlockCollection(blocks: blocks);
    
    for (final connData in connectionData) {
      final sourceBlockId = connData['sourceBlockId'];
      final sourceConnectionId = connData['sourceConnectionId'];
      final targetBlockId = connData['targetBlockId'];
      final targetConnectionId = connData['targetConnectionId'];
      
      if (sourceBlockId != null && sourceConnectionId != null &&
          targetBlockId != null && targetConnectionId != null) {
        collection.connectBlocks(
          sourceBlockId,
          sourceConnectionId,
          targetBlockId,
          targetConnectionId,
        );
      }
    }
    
    return collection;
  }
  
  /// Generate an AI-enhanced version of the pattern
  Future<Map<String, dynamic>> generateEnhancedPattern(BlockCollection blockCollection) async {
    try {
      // Generate the base pattern
      final pattern = patternEngine.generatePatternFromBlocks(blockCollection);
      
      // Apply AI enhancements
      final enhancedPattern = await _applyAIEnhancements(pattern, blockCollection);
      
      // Convert pattern to grid data
      final gridData = _patternToGridData(enhancedPattern);
      
      return {
        "status": "success",
        "executedPattern": {
          "grid": gridData,
          "gridSize": pattern.length,
          "scale": 1.0,
        },
        "message": "Pattern enhanced with AI techniques",
      };
    } catch (e) {
      return {
        "status": "error",
        "message": "Error enhancing pattern: $e",
      };
    }
  }
  
  /// Apply AI enhancements to a pattern
  Future<List<List<Color>>> _applyAIEnhancements(
    List<List<Color>> pattern,
    BlockCollection blockCollection,
  ) async {
    // Simulate AI enhancement with a delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create a copy of the pattern to avoid modifying the original
    // Fixed type casting issue by explicitly creating List<List<Color>>
    final enhancedPattern = List<List<Color>>.generate(
      pattern.length,
      (i) => List<Color>.from(pattern[i]),
    );
    
    // Get dominant colors from the pattern
    final dominantColors = _extractDominantColors(pattern);
    
    // Apply enhancements based on block types
    final hasPatternBlocks = blockCollection.blocks.any((b) => b.type == BlockType.pattern);
    final hasLoopBlocks = blockCollection.blocks.any((b) => b.type == BlockType.loop);
    
    if (hasPatternBlocks && hasLoopBlocks) {
      // Apply complex pattern transformations for advanced combinations
      _applyComplexTransformation(enhancedPattern, dominantColors);
    } else if (hasPatternBlocks) {
      // Apply basic enhancements for pattern blocks
      _applyBasicEnhancement(enhancedPattern, dominantColors);
    }
    
    return enhancedPattern;
  }
  
  /// Extract dominant colors from a pattern
  List<Color> _extractDominantColors(List<List<Color>> pattern) {
    final colorCounts = <Color, int>{};
    
    // Count occurrences of each color
    for (final row in pattern) {
      for (final color in row) {
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Sort colors by frequency
    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return the top colors (up to 5)
    return sortedColors.take(5).map((e) => e.key).toList();
  }
  
  /// Apply basic enhancement to a pattern
  void _applyBasicEnhancement(List<List<Color>> pattern, List<Color> dominantColors) {
    if (dominantColors.isEmpty) return;
    
    final rows = pattern.length;
    final cols = pattern[0].length;
    
    // Add subtle border or highlight effects
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        // Border effect: use dominant color for edges
        if (i == 0 || i == rows - 1 || j == 0 || j == cols - 1) {
          // Use the most dominant color with 30% opacity
          final dominantColor = dominantColors[0];
          pattern[i][j] = Color.lerp(pattern[i][j], dominantColor, 0.3)!;
        }
      }
    }
  }
  
  /// Apply complex transformation to a pattern
  void _applyComplexTransformation(List<List<Color>> pattern, List<Color> dominantColors) {
    if (dominantColors.length < 2) return;
    
    final rows = pattern.length;
    final cols = pattern[0].length;
    final random = DateTime.now().millisecondsSinceEpoch;
    
    // Apply a more complex effect based on block structures
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        // Apply a wave-like effect using sine functions
        final wave = (i + j + random) % 10 == 0;
        if (wave) {
          final index = (i + j) % dominantColors.length;
          final targetColor = dominantColors[index];
          pattern[i][j] = Color.lerp(pattern[i][j], targetColor, 0.5)!;
        }
      }
    }
  }
}