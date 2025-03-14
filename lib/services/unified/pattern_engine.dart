import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/block_model.dart';
import '../../models/pattern_difficulty.dart';
import '../block_definition_service.dart';

class PatternEngine {
  final BlockDefinitionService _definitionService = BlockDefinitionService();

  // Initialize the engine
  Future<void> initialize() async {
    await _definitionService.loadDefinitions();
  }

  // Generate pattern from blocks
  List<List<Color>> generatePatternFromBlocks(
      BlockCollection blockCollection, {
        int rows = 16,
        int columns = 16,
      }) {
    try {
      // Initialize empty pattern
      List<List<Color>> pattern = List.generate(
        rows,
        (_) => List.generate(columns, (_) => Colors.white),
      );

      // Log for debugging
      debugPrint('Generating pattern from ${blockCollection.blocks.length} blocks');

      // Find root blocks (those with no input connections)
      final rootBlocks = _findRootBlocks(blockCollection);
      
      // Log found root blocks
      debugPrint('Found ${rootBlocks.length} root blocks');
      for (final block in rootBlocks) {
        debugPrint('Root block: ${block.id} (${block.type})');
      }

      // If no root blocks found, try to find pattern blocks as starting points
      if (rootBlocks.isEmpty && blockCollection.blocks.isNotEmpty) {
        debugPrint('No root blocks found, trying pattern blocks as starting points');
        final patternBlocks = blockCollection.blocks.where((b) => b.type == BlockType.pattern).toList();
        
        if (patternBlocks.isNotEmpty) {
          debugPrint('Using ${patternBlocks.length} pattern blocks as starting points');
          for (final patternBlock in patternBlocks) {
            _processBlock(patternBlock, pattern, blockCollection);
          }
        } else {
          // If no pattern blocks, try color blocks
          debugPrint('No pattern blocks found, trying color blocks');
          final colorBlocks = blockCollection.blocks.where((b) => b.type == BlockType.color).toList();
          
          if (colorBlocks.isNotEmpty) {
            debugPrint('Using ${colorBlocks.length} color blocks as starting points');
            // Collect colors from all color blocks
            final colors = <Color>[];
            for (final colorBlock in colorBlocks) {
              _collectColor(colorBlock, colors);
            }
            
            // Apply a default pattern with the collected colors
            _applyDefaultPattern(pattern, colors);
          } else {
            // If no color blocks either, use all blocks as starting points
            debugPrint('No color blocks found, using all blocks as starting points');
            for (final block in blockCollection.blocks) {
              _processBlock(block, pattern, blockCollection);
            }
          }
        }
      } else {
        // Process each root block
        for (final rootBlock in rootBlocks) {
          _processBlock(rootBlock, pattern, blockCollection);
        }
      }

      // Verify pattern has content
      bool hasContent = false;
      for (final row in pattern) {
        for (final color in row) {
          if (color != Colors.white) {
            hasContent = true;
            break;
          }
        }
        if (hasContent) break;
      }
      
      // If pattern is empty, generate fallback pattern
      if (!hasContent && blockCollection.blocks.isNotEmpty) {
        debugPrint('Generated pattern is empty, using fallback');
        return _generateFallbackPattern(rows, columns);
      }

      return pattern;
    } catch (e, stackTrace) {
      debugPrint('Error generating pattern: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return a fallback pattern on error
      return _generateFallbackPattern(rows, columns);
    }
  }
  
  // Generate a fallback pattern when normal generation fails
  List<List<Color>> _generateFallbackPattern(int rows, int columns) {
    // Create a simple checkerboard pattern as fallback
    final colors = [Colors.black, Colors.amber];
    return List.generate(rows, (r) {
      return List.generate(columns, (c) {
        return (r + c) % 2 == 0 ? colors[0] : colors[1];
      });
    });
  }
  
  // Apply a default pattern with the given colors
  void _applyDefaultPattern(List<List<Color>> pattern, List<Color> colors) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.amber];
    }
    
    // Apply a simple checker pattern
    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        final colorIdx = (r + c) % colors.length;
        pattern[r][c] = colors[colorIdx];
      }
    }
  }

  // Find blocks with no input connections
  List<Block> _findRootBlocks(BlockCollection blockCollection) {
    return blockCollection.blocks.where((block) {
      final hasInputConnection = block.connections.any((conn) =>
      conn.type == ConnectionType.input && conn.connectedToId != null);
      return !hasInputConnection;
    }).toList();
  }

  // Process a block and its connections
  void _processBlock(
      Block block,
      List<List<Color>> pattern,
      BlockCollection blockCollection, {
        int startRow = 0,
        int startCol = 0,
        int endRow = 0,
        int endCol = 0,
        List<Color> colors = const [],
      }
      ) {
    switch (block.type) {
      case BlockType.pattern:
        _applyPatternBlock(block, pattern, startRow, startCol, endRow, endCol, colors);
        break;
      case BlockType.color:
        _collectColor(block, colors);
        break;
      case BlockType.loop:
        _processLoopBlock(block, pattern, blockCollection, startRow, startCol, endRow, endCol, colors);
        break;
      case BlockType.row:
        _processRowBlock(block, pattern, blockCollection, startRow, startCol, endRow, endCol, colors);
        break;
      case BlockType.column:
        _processColumnBlock(block, pattern, blockCollection, startRow, startCol, endRow, endCol, colors);
        break;
      default:
      // Handle other block types
        break;
    }

    // Process connected output blocks
    _processConnectedBlocks(block, pattern, blockCollection, startRow, startCol, endRow, endCol, colors);
  }

  // Apply pattern block to the pattern grid
  void _applyPatternBlock(
      Block block,
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      List<Color> colors,
      ) {
    // Determine pattern dimensions
    final patternType = block.subtype;
    final patternRows = endRow - startRow > 0 ? endRow - startRow : pattern.length;
    final patternCols = endCol - startCol > 0 ? endCol - startCol : pattern[0].length;

    // Get pattern definition
    final patternDefs = _definitionService.getPatternDefinitions();
    final patternDef = patternDefs.firstWhere(
          (p) => p['id'] == patternType,
      orElse: () => {},
    );

    // Use colors or default colors
    final usedColors = colors.isNotEmpty ? colors : _getDefaultColors(patternDef);

    // Apply the pattern based on its type
    switch (patternType) {
      case 'checker_pattern':
        _applyCheckerPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      case 'zigzag_pattern':
        _applyZigzagPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      case 'stripes_vertical_pattern':
        _applyVerticalStripesPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      case 'stripes_horizontal_pattern':
        _applyHorizontalStripesPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      case 'square_pattern':
        _applySquarePattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      case 'diamonds_pattern':
        _applyDiamondPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
      default:
      // Apply simple checkerboard as fallback
        _applyCheckerPattern(pattern, startRow, startCol, patternRows, patternCols, usedColors);
        break;
    }
  }

  // Collect colors from color blocks
  void _collectColor(Block block, List<Color> colors) {
    if (block.properties.containsKey('color')) {
      final colorStr = block.properties['color'];
      if (colorStr is String) {
        if (colorStr.startsWith('#')) {
          colors.add(Color(int.parse('0xFF${colorStr.substring(1)}')));
        } else if (colorStr.startsWith('0x')) {
          colors.add(Color(int.parse(colorStr)));
        } else {
          colors.add(block.color);
        }
      } else {
        colors.add(block.color);
      }
    } else {
      colors.add(block.color);
    }
  }

  // Process loop blocks
  void _processLoopBlock(
      Block block,
      List<List<Color>> pattern,
      BlockCollection blockCollection,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      List<Color> colors,
      ) {
    // Get loop count
    final loopCount = int.tryParse(block.properties['value']?.toString() ?? '3') ?? 3;

    // Find body connection
    final bodyConn = block.connections.firstWhere(
          (c) => c.id.contains('body'),
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    // If there's a connected block to the body
    if (bodyConn.connectedToId != null) {
      final connParts = bodyConn.connectedToId!.split('_');
      final connBlockId = connParts.first;
      final bodyBlock = blockCollection.getBlockById(connBlockId);

      if (bodyBlock != null) {
        // Apply the body block multiple times
        int patternSize = min(pattern.length, pattern[0].length) ~/ loopCount;

        for (int i = 0; i < loopCount; i++) {
          int loopStartRow = startRow + (i * patternSize);
          int loopEndRow = loopStartRow + patternSize;

          _processBlock(
            bodyBlock,
            pattern,
            blockCollection,
            startRow: loopStartRow,
            startCol: startCol,
            endRow: loopEndRow,
            endCol: endCol,
            colors: List.from(colors),
          );
        }
      }
    }
  }

  // Process row blocks
  void _processRowBlock(
      Block block,
      List<List<Color>> pattern,
      BlockCollection blockCollection,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      List<Color> colors,
      ) {
    // Get row count
    final size = int.tryParse(block.properties['value']?.toString() ?? '2') ?? 2;

    // Process child blocks
    final inputConn = block.connections.firstWhere(
          (c) => c.type == ConnectionType.input,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    if (inputConn.connectedToId != null) {
      final connParts = inputConn.connectedToId!.split('_');
      final connBlockId = connParts.first;
      final inputBlock = blockCollection.getBlockById(connBlockId);

      if (inputBlock != null) {
        final columnWidth = (pattern[0].length) ~/ size;

        for (int i = 0; i < size; i++) {
          int colStart = i * columnWidth;
          int colEnd = (i + 1) * columnWidth;

          _processBlock(
            inputBlock,
            pattern,
            blockCollection,
            startRow: startRow,
            startCol: colStart,
            endRow: endRow > 0 ? endRow : pattern.length,
            endCol: colEnd,
            colors: List.from(colors),
          );
        }
      }
    }
  }

  // Process column blocks
  void _processColumnBlock(
      Block block,
      List<List<Color>> pattern,
      BlockCollection blockCollection,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      List<Color> colors,
      ) {
    // Get column count
    final size = int.tryParse(block.properties['value']?.toString() ?? '2') ?? 2;

    // Process child blocks
    final inputConn = block.connections.firstWhere(
          (c) => c.type == ConnectionType.input,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    if (inputConn.connectedToId != null) {
      final connParts = inputConn.connectedToId!.split('_');
      final connBlockId = connParts.first;
      final inputBlock = blockCollection.getBlockById(connBlockId);

      if (inputBlock != null) {
        final rowHeight = (pattern.length) ~/ size;

        for (int i = 0; i < size; i++) {
          int rowStart = i * rowHeight;
          int rowEnd = (i + 1) * rowHeight;

          _processBlock(
            inputBlock,
            pattern,
            blockCollection,
            startRow: rowStart,
            startCol: startCol,
            endRow: rowEnd,
            endCol: endCol > 0 ? endCol : pattern[0].length,
            colors: List.from(colors),
          );
        }
      }
    }
  }

  // Process blocks connected to the output
  void _processConnectedBlocks(
      Block block,
      List<List<Color>> pattern,
      BlockCollection blockCollection,
      int startRow,
      int startCol,
      int endRow,
      int endCol,
      List<Color> colors,
      ) {
    // Find output connection
    final outputConn = block.connections.firstWhere(
          (c) => c.id.contains('output') && c.type == ConnectionType.output,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    // If there's a connected block to the output
    if (outputConn.connectedToId != null) {
      final connParts = outputConn.connectedToId!.split('_');
      final connBlockId = connParts.first;
      final outputBlock = blockCollection.getBlockById(connBlockId);

      if (outputBlock != null) {
        _processBlock(
          outputBlock,
          pattern,
          blockCollection,
          startRow: startRow,
          startCol: startCol,
          endRow: endRow,
          endCol: endCol,
          colors: List.from(colors),
        );
      }
    }
  }

  // Get default colors for a pattern
  List<Color> _getDefaultColors(Map<String, dynamic> patternDef) {
    final defaultColors = patternDef['defaultColors'] as List<dynamic>? ?? ['#000000', '#FFD700'];

    return defaultColors.map<Color>((colorStr) {
      if (colorStr is String && colorStr.startsWith('#')) {
        return Color(int.parse('0xFF${colorStr.substring(1)}'));
      }
      return Colors.black;
    }).toList();
  }

  // Pattern implementation methods
  void _applyCheckerPattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.length < 2) {
      colors = [Colors.black, Colors.white];
    }

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        final colorIdx = (r + c) % 2;
        pattern[startRow + r][startCol + c] = colors[colorIdx % colors.length];
      }
    }
  }

  void _applyZigzagPattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.white];
    }

    final zigzagWidth = 4; // Width of one complete zigzag

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        final zigzagPos = (c % zigzagWidth);
        final rowOffset = zigzagPos < zigzagWidth / 2 ? zigzagPos : zigzagWidth - zigzagPos - 1;

        final colorIdx = (r + rowOffset) % colors.length;
        pattern[startRow + r][startCol + c] = colors[colorIdx];
      }
    }
  }

  void _applyVerticalStripesPattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.white];
    }

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        final colorIdx = c % colors.length;
        pattern[startRow + r][startCol + c] = colors[colorIdx];
      }
    }
  }

  void _applyHorizontalStripesPattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.white];
    }

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      final colorIdx = r % colors.length;
      final rowColor = colors[colorIdx];

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        pattern[startRow + r][startCol + c] = rowColor;
      }
    }
  }

  void _applySquarePattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.white];
    }

    final centerR = startRow + (rows ~/ 2);
    final centerC = startCol + (cols ~/ 2);
    final maxDist = min(rows, cols) ~/ 2;

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        final rDist = (startRow + r - centerR).abs();
        final cDist = (startCol + c - centerC).abs();
        final maxD = max(rDist, cDist);

        final colorIdx = (maxD * colors.length ~/ maxDist) % colors.length;
        pattern[startRow + r][startCol + c] = colors[colorIdx];
      }
    }
  }

  void _applyDiamondPattern(
      List<List<Color>> pattern,
      int startRow,
      int startCol,
      int rows,
      int cols,
      List<Color> colors,
      ) {
    if (colors.isEmpty) {
      colors = [Colors.black, Colors.white];
    }

    final centerR = startRow + (rows ~/ 2);
    final centerC = startCol + (cols ~/ 2);
    final maxDist = min(rows, cols) ~/ 2;

    for (int r = 0; r < rows; r++) {
      if (startRow + r >= pattern.length) break;

      for (int c = 0; c < cols; c++) {
        if (startCol + c >= pattern[0].length) break;

        final rDist = (startRow + r - centerR).abs();
        final cDist = (startCol + c - centerC).abs();
        final dist = rDist + cDist;

        final colorIdx = (dist * colors.length ~/ (maxDist * 2)) % colors.length;
        pattern[startRow + r][startCol + c] = colors[colorIdx];
      }
    }
  }

  // Analyze a pattern
  Map<String, dynamic> analyzePattern({
    required List<List<Color>> pattern,
    required PatternDifficulty difficulty,
  }) {
    double complexity = _calculateComplexity(pattern);
    double colorVariety = _calculateColorVariety(pattern);
    double symmetry = _calculateSymmetry(pattern);
    double culturalScore = _estimateCulturalScore(pattern, complexity, colorVariety);

    return {
      'complexity': complexity,
      'color_variety': colorVariety,
      'symmetry': symmetry,
      'cultural_score': culturalScore,
      'suggestions': _generateSuggestions(pattern, complexity, colorVariety, difficulty),
    };
  }

  // Calculate pattern complexity
  double _calculateComplexity(List<List<Color>> pattern) {
    // Count color transitions
    int transitions = 0;
    int totalCells = 0;

    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        totalCells++;

        // Check horizontal transition
        if (c < pattern[r].length - 1 && pattern[r][c] != pattern[r][c + 1]) {
          transitions++;
        }

        // Check vertical transition
        if (r < pattern.length - 1 && pattern[r][c] != pattern[r + 1][c]) {
          transitions++;
        }
      }
    }

    // Normalize complexity (0-1)
    final maxTransitions = totalCells * 2;
    return min(1.0, transitions / maxTransitions);
  }

  // Calculate color variety
  double _calculateColorVariety(List<List<Color>> pattern) {
    Set<Color> uniqueColors = {};

    for (final row in pattern) {
      for (final color in row) {
        uniqueColors.add(color);
      }
    }

    // Normalize variety (0-1)
    return min(1.0, uniqueColors.length / 8); // Assuming 8 is max variety
  }

  // Calculate symmetry
  double _calculateSymmetry(List<List<Color>> pattern) {
    int symmetricPoints = 0;
    int totalPoints = 0;

    // Check horizontal symmetry
    final rows = pattern.length;
    final cols = pattern[0].length;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols ~/ 2; c++) {
        totalPoints++;
        if (pattern[r][c] == pattern[r][cols - c - 1]) {
          symmetricPoints++;
        }
      }
    }

    // Check vertical symmetry
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows ~/ 2; r++) {
        totalPoints++;
        if (pattern[r][c] == pattern[rows - r - 1][c]) {
          symmetricPoints++;
        }
      }
    }

    // Normalize symmetry (0-1)
    return totalPoints > 0 ? symmetricPoints / totalPoints : 0.0;
  }

  // Estimate cultural score
  double _estimateCulturalScore(
      List<List<Color>> pattern,
      double complexity,
      double colorVariety,
      ) {
    // Combine complexity and color variety as a proxy for cultural accuracy
    return (complexity * 0.6 + colorVariety * 0.4);
  }

  // Generate suggestions based on pattern analysis
  List<String> _generateSuggestions(
      List<List<Color>> pattern,
      double complexity,
      double colorVariety,
      PatternDifficulty difficulty,
      ) {
    List<String> suggestions = [];

    // Complexity suggestions
    if (complexity < 0.3) {
      suggestions.add('Try adding more pattern variations to increase complexity');
    } else if (complexity > 0.8) {
      suggestions.add('Your pattern has good complexity');
    }

    // Color variety suggestions
    if (colorVariety < 0.3) {
      suggestions.add('Consider adding more colors for traditional Kente richness');
    } else if (colorVariety > 0.7) {
      suggestions.add('Good use of multiple colors');
    }

    // Difficulty-based suggestions
    switch (difficulty) {
      case PatternDifficulty.basic:
        if (complexity < 0.2) {
          suggestions.add('Try combining different blocks to create more interesting patterns');
        }
        break;
      case PatternDifficulty.intermediate:
        if (complexity < 0.4) {
          suggestions.add('Try using loop blocks to create repetitive patterns');
        }
        break;
      case PatternDifficulty.advanced:
        if (colorVariety < 0.5) {
          suggestions.add('Use more color combinations for advanced patterns');
        }
        break;
      case PatternDifficulty.expert:
        if (complexity < 0.6 || colorVariety < 0.6) {
          suggestions.add('Master patterns typically have high complexity and color variety');
        }
        break;
    }

    return suggestions;
  }

  // Analyze a block collection
  Map<String, dynamic> analyzeBlockCollection(
      BlockCollection blockCollection,
      PatternDifficulty difficulty,
      ) {
    // Count block types
    int patternBlocks = 0;
    int colorBlocks = 0;
    int loopBlocks = 0;
    int structureBlocks = 0;

    for (final block in blockCollection.blocks) {
      switch (block.type) {
        case BlockType.pattern:
          patternBlocks++;
          break;
        case BlockType.color:
          colorBlocks++;
          break;
        case BlockType.loop:
          loopBlocks++;
          break;
        case BlockType.row:
        case BlockType.column:
          structureBlocks++;
          break;
        default:
          break;
      }
    }

    // Calculate metrics
    double blockVariety = min(1.0, (patternBlocks > 0 ? 0.25 : 0) +
        (colorBlocks > 0 ? 0.25 : 0) +
        (loopBlocks > 0 ? 0.25 : 0) +
        (structureBlocks > 0 ? 0.25 : 0));

    double complexity = min(1.0, 0.2 * patternBlocks +
        0.1 * colorBlocks +
        0.3 * loopBlocks +
        0.2 * structureBlocks);

    // Calculate connection complexity
    int connections = 0;
    for (final block in blockCollection.blocks) {
      for (final conn in block.connections) {
        if (conn.connectedToId != null) {
          connections++;
        }
      }
    }

    double connectionComplexity = min(1.0, connections / 10.0); // Assuming 10 connections is complex
    complexity = (complexity + connectionComplexity) / 2;

    double culturalScore = min(1.0, (patternBlocks * 0.3 + colorBlocks * 0.4) / 5.0);

    return {
      'complexity': complexity,
      'color_variety': min(1.0, colorBlocks / 6.0),
      'block_variety': blockVariety,
      'cultural_score': culturalScore,
      'symmetry': 0.5, // Default value
    };
  }
}
