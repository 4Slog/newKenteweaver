import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/block_model.dart';
import '../../models/pattern_difficulty.dart';
import '../../theme/app_theme.dart';

class PatternEngine {
  static final PatternEngine _instance = PatternEngine._internal();
  
  factory PatternEngine() {
    return _instance;
  }
  
  PatternEngine._internal();

  // Generate pattern from blocks
  List<List<Color>> generatePatternFromBlocks(BlockCollection blockCollection, {
    int rows = 16,
    int columns = 16,
  }) {
    final result = List.generate(
      rows,
      (i) => List.filled(columns, Colors.white),
    );
    
    // Find root blocks (those without input connections)
    final rootBlocks = blockCollection.blocks.where((block) {
      return !block.connections.any((conn) => 
        conn.type == ConnectionType.input && conn.connectedToId != null);
    }).toList();
    
    // Process each root block
    for (final rootBlock in rootBlocks) {
      _processBlock(rootBlock, blockCollection, result, rows, columns);
    }
    
    return result;
  }
  
  void _processBlock(Block block, BlockCollection blockCollection, 
                   List<List<Color>> result, int rows, int columns) {
    // Process based on block type
    switch (block.type) {
      case BlockType.pattern:
        _applyPatternBlock(block, result, rows, columns);
        break;
      case BlockType.color:
        _applyColorBlock(block, result, rows, columns);
        break;
      case BlockType.loop:
        _applyLoopBlock(block, blockCollection, result, rows, columns);
        break;
      case BlockType.row:
        _applyRowBlock(block, blockCollection, result, rows, columns);
        break;
      case BlockType.column:
        _applyColumnBlock(block, blockCollection, result, rows, columns);
        break;
      case BlockType.structure:
        // Handle other structure blocks
        break;
    }
    
    // Follow output connections
    final outputConns = block.connections
        .where((conn) => conn.type == ConnectionType.output && conn.connectedToId != null);
    
    for (final conn in outputConns) {
      if (conn.connectedToId != null) {
        final targetConnParts = conn.connectedToId!.split('_');
        final targetBlockId = targetConnParts.first;
        final targetBlock = blockCollection.getBlockById(targetBlockId);
        
        if (targetBlock != null) {
          _processBlock(targetBlock, blockCollection, result, rows, columns);
        }
      }
    }
  }
  
  void _applyPatternBlock(Block block, List<List<Color>> result, int rows, int columns) {
    // Extract pattern type from subtype, handling different naming conventions
    String patternType;
    if (block.subtype.endsWith('_pattern')) {
      patternType = block.subtype.replaceAll('_pattern', '');
    } else {
      patternType = block.subtype;
    }
    
    // Get colors from block properties
    final colors = _getColorsFromProperties(block.properties);
    
    // Generate the pattern
    generatePattern(
      patternType: patternType,
      colors: colors,
      rows: rows,
      columns: columns,
      pattern: result,
    );
  }
  
  void _applyColorBlock(Block block, List<List<Color>> result, int rows, int columns) {
    final color = _getColorFromBlockType(block.subtype);
    
    // Apply the color to the entire pattern or follow specific rules
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        result[i][j] = color;
      }
    }
  }
  
  void _applyLoopBlock(Block block, BlockCollection blockCollection, 
                     List<List<Color>> result, int rows, int columns) {
    final repeats = int.tryParse(block.properties['value'] ?? '3') ?? 3;
    
    // Find the body connection
    final bodyConn = block.connections.firstWhere(
      (conn) => conn.id.endsWith('_body'),
      orElse: () => block.connections.firstWhere(
        (conn) => conn.type == ConnectionType.output,
        orElse: () => BlockConnection(
          id: '', 
          name: '', 
          type: ConnectionType.none, 
          position: Offset.zero
        ),
      ),
    );
    
    if (bodyConn.connectedToId != null) {
      final targetConnParts = bodyConn.connectedToId!.split('_');
      final targetBlockId = targetConnParts.first;
      final targetBlock = blockCollection.getBlockById(targetBlockId);
      
      if (targetBlock != null) {
        for (int i = 0; i < repeats; i++) {
          _processBlock(targetBlock, blockCollection, result, rows, columns);
        }
      }
    }
  }
  
  void _applyRowBlock(Block block, BlockCollection blockCollection, 
                    List<List<Color>> result, int rows, int columns) {
    // Find connected blocks and apply them in a row
    final bodyConn = block.connections.firstWhere(
      (conn) => conn.type == ConnectionType.output,
      orElse: () => BlockConnection(
        id: '', 
        name: '', 
        type: ConnectionType.none, 
        position: Offset.zero
      ),
    );
    
    if (bodyConn.connectedToId != null) {
      final targetConnParts = bodyConn.connectedToId!.split('_');
      final targetBlockId = targetConnParts.first;
      final targetBlock = blockCollection.getBlockById(targetBlockId);
      
      if (targetBlock != null) {
        // Create a temporary result grid for the connected block
        final tempResult = List.generate(
          rows,
          (i) => List.filled(columns, Colors.white),
        );
        
        // Process the connected block into the temporary grid
        _processBlock(targetBlock, blockCollection, tempResult, rows, columns);
        
        // Apply the temporary grid in a row pattern (horizontally)
        final segmentWidth = columns ~/ 3;
        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < columns; j++) {
            final segmentIndex = j ~/ segmentWidth;
            if (segmentIndex < 3) { // Limit to 3 segments
              result[i][j] = tempResult[i][j % segmentWidth];
            }
          }
        }
      }
    }
  }
  
  void _applyColumnBlock(Block block, BlockCollection blockCollection, 
                       List<List<Color>> result, int rows, int columns) {
    // Find connected blocks and apply them in a column
    final bodyConn = block.connections.firstWhere(
      (conn) => conn.type == ConnectionType.output,
      orElse: () => BlockConnection(
        id: '', 
        name: '', 
        type: ConnectionType.none, 
        position: Offset.zero
      ),
    );
    
    if (bodyConn.connectedToId != null) {
      final targetConnParts = bodyConn.connectedToId!.split('_');
      final targetBlockId = targetConnParts.first;
      final targetBlock = blockCollection.getBlockById(targetBlockId);
      
      if (targetBlock != null) {
        // Create a temporary result grid for the connected block
        final tempResult = List.generate(
          rows,
          (i) => List.filled(columns, Colors.white),
        );
        
        // Process the connected block into the temporary grid
        _processBlock(targetBlock, blockCollection, tempResult, rows, columns);
        
        // Apply the temporary grid in a column pattern (vertically)
        final segmentHeight = rows ~/ 3;
        for (int i = 0; i < rows; i++) {
          final segmentIndex = i ~/ segmentHeight;
          if (segmentIndex < 3) { // Limit to 3 segments
            for (int j = 0; j < columns; j++) {
              result[i][j] = tempResult[i % segmentHeight][j];
            }
          }
        }
      }
    }
  }
  
  Color _getColorFromBlockType(String blockType) {
    if (blockType.startsWith('shuttle_')) {
      final colorName = blockType.split('_')[1];
      
      switch (colorName) {
        case 'black': return Colors.black;
        case 'blue': return Colors.blue;
        case 'gold': return AppTheme.kenteGold;
        case 'green': return Colors.green;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'red': return Colors.red;
        case 'white': return Colors.white;
        default: return Colors.grey;
      }
    }
    
    return Colors.grey;
  }
  
  List<Color> _getColorsFromProperties(Map<String, dynamic> properties) {
    if (properties.containsKey('colors')) {
      return (properties['colors'] as List).map((c) => 
        Color(int.parse(c.toString().replaceAll('#', '0xFF')))).toList();
    }
    
    // Default colors if none specified
    return [Colors.black, Colors.red, AppTheme.kenteGold];
  }

  // Original pattern generation method with updated signature
  void generatePattern({
    required String patternType,
    required List<Color> colors,
    required int rows,
    required int columns,
    List<List<Color>>? pattern,
    int? repetitions,
  }) {
    if (colors.isEmpty) {
      colors = [Colors.white];
    }

    final result = pattern ?? List.generate(
      rows,
      (i) => List.filled(columns, colors[0]),
    );

    switch (patternType) {
      case 'checker':
      case 'checker_pattern':
        _generateCheckerPattern(result, colors);
        break;
      case 'stripes_vertical':
      case 'vertical':
        _generateVerticalStripes(result, colors);
        break;
      case 'stripes_horizontal':
      case 'horizontal':
        _generateHorizontalStripes(result, colors);
        break;
      case 'diamond':
      case 'diamonds':
      case 'diamonds_pattern':
        _generateDiamondPattern(result, colors);
        break;
      case 'zigzag':
      case 'zigzag_pattern':
        _generateZigzagPattern(result, colors);
        break;
      case 'square':
      case 'square_pattern':
        _generateSquarePattern(result, colors);
        break;
      default:
        // Default to checker pattern if unknown pattern type
        _generateCheckerPattern(result, colors);
        break;
    }

    if (repetitions != null && repetitions > 1) {
      // Apply repetition to the result pattern
      final repeatedPattern = _applyRepetition(result, repetitions);
      
      // Copy the repeated pattern back to the result
      for (int i = 0; i < math.min(result.length, repeatedPattern.length); i++) {
        for (int j = 0; j < math.min(result[i].length, repeatedPattern[i].length); j++) {
          result[i][j] = repeatedPattern[i][j];
        }
      }
    }
  }

  // Pattern Analysis
  Map<String, dynamic> analyzePattern({
    required List<List<Color>> pattern,
    required PatternDifficulty difficulty,
  }) {
    final complexity = _calculateComplexity(pattern);
    final colorVariety = _analyzeColorVariety(pattern);
    final symmetry = _checkSymmetry(pattern);
    final culturalScore = _calculateCulturalScore(pattern, difficulty);

    return {
      'complexity': complexity,
      'color_variety': colorVariety,
      'symmetry': symmetry,
      'cultural_score': culturalScore,
      'suggestions': _generateSuggestions(
        complexity,
        colorVariety,
        symmetry,
        culturalScore,
        difficulty,
      ),
    };
  }
  
  // Analyze a block collection
  Map<String, dynamic> analyzeBlockCollection(
    BlockCollection blockCollection,
    PatternDifficulty difficulty,
  ) {
    // Generate the pattern from blocks
    final pattern = generatePatternFromBlocks(blockCollection);
    
    // Analyze the generated pattern
    final patternAnalysis = analyzePattern(
      pattern: pattern,
      difficulty: difficulty,
    );
    
    // Add block-specific analysis
    int blockTypeVariety = _getBlockTypeVariety(blockCollection);
    int connectionCount = _getConnectionCount(blockCollection);
    
    return {
      ...patternAnalysis,
      'block_count': blockCollection.blocks.length,
      'block_type_variety': blockTypeVariety,
      'connection_count': connectionCount,
      'block_suggestions': _generateBlockSuggestions(
        blockCollection,
        difficulty,
        blockTypeVariety,
        connectionCount,
      ),
    };
  }
  
  int _getBlockTypeVariety(BlockCollection blockCollection) {
    final types = blockCollection.blocks.map((b) => b.type).toSet();
    return types.length;
  }
  
  int _getConnectionCount(BlockCollection blockCollection) {
    int count = 0;
    for (final block in blockCollection.blocks) {
      count += block.connections.where((c) => c.connectedToId != null).length;
    }
    return count;
  }
  
  List<String> _generateBlockSuggestions(
    BlockCollection blockCollection,
    PatternDifficulty difficulty,
    int blockTypeVariety,
    int connectionCount,
  ) {
    final suggestions = <String>[];
    
    if (blockCollection.blocks.isEmpty) {
      suggestions.add('Start by adding pattern blocks to your workspace');
      return suggestions;
    }
    
    // Check for pattern blocks
    if (!blockCollection.blocks.any((b) => b.type == BlockType.pattern)) {
      suggestions.add('Add a pattern block to define your design');
    }
    
    // Check for color blocks
    if (!blockCollection.blocks.any((b) => b.type == BlockType.color)) {
      suggestions.add('Add color blocks to bring your pattern to life');
    }
    
    // Suggest more variety based on difficulty
    if (blockTypeVariety < 3 && 
        (difficulty == PatternDifficulty.intermediate || 
         difficulty == PatternDifficulty.advanced || 
         difficulty == PatternDifficulty.master)) {
      suggestions.add('Try using a greater variety of block types');
    }
    
    // Suggest more connections for advanced difficulties
    if (connectionCount < 3 && 
        (difficulty == PatternDifficulty.advanced || 
         difficulty == PatternDifficulty.master)) {
      suggestions.add('Connect more blocks together to create complex patterns');
    }
    
    // Suggest loops for advanced patterns
    if (!blockCollection.blocks.any((b) => b.type == BlockType.loop) && 
        (difficulty == PatternDifficulty.advanced || 
         difficulty == PatternDifficulty.master)) {
      suggestions.add('Use loop blocks to create repeating patterns');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('Your block arrangement looks good!');
    }
    
    return suggestions;
  }

  // Pattern Validation
  bool validatePattern({
    required List<List<Color>> pattern,
    required PatternDifficulty difficulty,
    Map<String, dynamic>? requirements,
  }) {
    if (pattern.isEmpty || pattern[0].isEmpty) {
      return false;
    }

    final analysis = analyzePattern(
      pattern: pattern,
      difficulty: difficulty,
    );

    // Basic validation
    if (analysis['complexity'] < _getMinComplexity(difficulty)) {
      return false;
    }

    if (analysis['color_variety'] < _getMinColorVariety(difficulty)) {
      return false;
    }

    // Check specific requirements if provided
    if (requirements != null) {
      return _checkRequirements(pattern, requirements);
    }

    return true;
  }
  
  // Validate a block collection
  bool validateBlockCollection(
    BlockCollection blockCollection,
    PatternDifficulty difficulty, {
    Map<String, dynamic>? requirements,
  }) {
    // Generate the pattern
    final pattern = generatePatternFromBlocks(blockCollection);
    
    // Basic validation of the pattern
    final isPatternValid = validatePattern(
      pattern: pattern,
      difficulty: difficulty,
      requirements: requirements,
    );
    
    if (!isPatternValid) {
      return false;
    }
    
    // Additional block-specific validation
    final minBlocks = _getMinBlocks(difficulty);
    if (blockCollection.blocks.length < minBlocks) {
      return false;
    }
    
    // Check for required block types based on difficulty
    if (difficulty == PatternDifficulty.intermediate && 
        !blockCollection.blocks.any((b) => b.type == BlockType.pattern)) {
      return false;
    }
    
    if (difficulty == PatternDifficulty.advanced && 
        (!blockCollection.blocks.any((b) => b.type == BlockType.pattern) || 
         !blockCollection.blocks.any((b) => b.type == BlockType.color))) {
      return false;
    }
    
    if (difficulty == PatternDifficulty.master && 
        (!blockCollection.blocks.any((b) => b.type == BlockType.pattern) || 
         !blockCollection.blocks.any((b) => b.type == BlockType.color) || 
         !blockCollection.blocks.any((b) => b.type == BlockType.loop))) {
      return false;
    }
    
    return true;
  }
  
  int _getMinBlocks(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 1;
      case PatternDifficulty.intermediate:
        return 3;
      case PatternDifficulty.advanced:
        return 5;
      case PatternDifficulty.master:
        return 8;
    }
  }

  // Pattern Generation Helpers
  void _generateCheckerPattern(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        pattern[i][j] = colors[(i + j) % colors.length];
      }
    }
  }

  void _generateVerticalStripes(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;

    for (int j = 0; j < cols; j++) {
      final color = colors[j % colors.length];
      for (int i = 0; i < rows; i++) {
        pattern[i][j] = color;
      }
    }
  }

  void _generateHorizontalStripes(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;

    for (int i = 0; i < rows; i++) {
      final color = colors[i % colors.length];
      for (int j = 0; j < cols; j++) {
        pattern[i][j] = color;
      }
    }
  }

  void _generateDiamondPattern(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;
    final centerX = cols ~/ 2;
    final centerY = rows ~/ 2;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final distance = (i - centerY).abs() + (j - centerX).abs();
        pattern[i][j] = colors[distance % colors.length];
      }
    }
  }

  void _generateZigzagPattern(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final index = ((i + j) ~/ 2) % colors.length;
        pattern[i][j] = colors[index];
      }
    }
  }

  void _generateSquarePattern(List<List<Color>> pattern, List<Color> colors) {
    final rows = pattern.length;
    final cols = pattern[0].length;
    final squareSize = math.min(rows, cols) ~/ 4;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final ring = math.min(
          math.min(i, rows - 1 - i),
          math.min(j, cols - 1 - j),
        ) ~/ squareSize;
        pattern[i][j] = colors[ring % colors.length];
      }
    }
  }

  /// Apply repetition to a pattern
  /// 
  /// This creates a new pattern with the base pattern repeated multiple times
  /// If the repetition would make the pattern too large, it will be scaled down
  List<List<Color>> _applyRepetition(
    List<List<Color>> basePattern,
    int repetitions,
  ) {
    final baseRows = basePattern.length;
    final baseCols = basePattern[0].length;
    
    // Limit the size of the repeated pattern to avoid memory issues
    final maxRows = math.min(baseRows * repetitions, 64);
    final maxCols = math.min(baseCols * repetitions, 64);
    
    final newPattern = List.generate(
      maxRows,
      (i) => List.filled(maxCols, Colors.white),
    );

    // Apply the repetition
    for (int i = 0; i < maxRows; i++) {
      for (int j = 0; j < maxCols; j++) {
        newPattern[i][j] = basePattern[i % baseRows][j % baseCols];
      }
    }

    return newPattern;
  }

  // Pattern Analysis Helpers
  double _calculateComplexity(List<List<Color>> pattern) {
    final rows = pattern.length;
    final cols = pattern[0].length;
    final totalCells = rows * cols;
    
    // Count unique color transitions
    var transitions = 0;
    final Set<Color> uniqueColors = {};

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        uniqueColors.add(pattern[i][j]);
        if (j < cols - 1 && pattern[i][j] != pattern[i][j + 1]) {
          transitions++;
        }
        if (i < rows - 1 && pattern[i][j] != pattern[i + 1][j]) {
          transitions++;
        }
      }
    }

    final colorVariety = uniqueColors.length / math.min(totalCells, 10);
    final transitionDensity = transitions / (totalCells * 2);

    return (colorVariety * 0.4 + transitionDensity * 0.6).clamp(0.0, 1.0);
  }

  double _analyzeColorVariety(List<List<Color>> pattern) {
    final Set<Color> uniqueColors = {};
    for (final row in pattern) {
      uniqueColors.addAll(row);
    }
    return math.min(1.0, uniqueColors.length / 5);
  }

  double _checkSymmetry(List<List<Color>> pattern) {
    final rows = pattern.length;
    final cols = pattern[0].length;
    var symmetricCells = 0;
    final totalCells = rows * cols;

    // Horizontal symmetry
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols ~/ 2; j++) {
        if (pattern[i][j] == pattern[i][cols - 1 - j]) {
          symmetricCells++;
        }
      }
    }

    // Vertical symmetry
    for (int j = 0; j < cols; j++) {
      for (int i = 0; i < rows ~/ 2; i++) {
        if (pattern[i][j] == pattern[rows - 1 - i][j]) {
          symmetricCells++;
        }
      }
    }

    return (symmetricCells / totalCells).clamp(0.0, 1.0);
  }

  double _calculateCulturalScore(
    List<List<Color>> pattern,
    PatternDifficulty difficulty,
  ) {
    // Analyze traditional color combinations
    final hasGold = pattern.any((row) => row.contains(AppTheme.kenteGold));
    final hasRed = pattern.any((row) => row.contains(Colors.red));
    final hasBlack = pattern.any((row) => row.contains(Colors.black));
    
    var score = 0.0;
    if (hasGold) score += 0.3;
    if (hasRed) score += 0.2;
    if (hasBlack) score += 0.2;

    // Analyze pattern complexity based on difficulty
    final complexity = _calculateComplexity(pattern);
    score += complexity * 0.3;

    return score.clamp(0.0, 1.0);
  }

  List<String> _generateSuggestions(
    double complexity,
    double colorVariety,
    double symmetry,
    double culturalScore,
    PatternDifficulty difficulty,
  ) {
    final suggestions = <String>[];

    if (complexity < _getMinComplexity(difficulty)) {
      suggestions.add('Try adding more pattern variations');
    }

    if (colorVariety < _getMinColorVariety(difficulty)) {
      suggestions.add('Consider using more traditional colors');
    }

    if (symmetry < 0.5) {
      suggestions.add('Your pattern could be more balanced');
    }

    if (culturalScore < 0.6) {
      suggestions.add('Incorporate more traditional Kente elements');
    }

    return suggestions;
  }

  double _getMinComplexity(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 0.3;
      case PatternDifficulty.intermediate:
        return 0.5;
      case PatternDifficulty.advanced:
        return 0.7;
      case PatternDifficulty.master:
        return 0.8;
    }
  }

  double _getMinColorVariety(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 0.2;
      case PatternDifficulty.intermediate:
        return 0.4;
      case PatternDifficulty.advanced:
        return 0.6;
      case PatternDifficulty.master:
        return 0.8;
    }
  }

  bool _checkRequirements(
    List<List<Color>> pattern,
    Map<String, dynamic> requirements,
  ) {
    if (requirements.containsKey('min_colors')) {
      final uniqueColors = Set<Color>.from(
        pattern.expand((row) => row),
      );
      if (uniqueColors.length < requirements['min_colors']) {
        return false;
      }
    }

    if (requirements.containsKey('min_complexity')) {
      final complexity = _calculateComplexity(pattern);
      if (complexity < requirements['min_complexity']) {
        return false;
      }
    }

    if (requirements.containsKey('required_colors')) {
      final requiredColors = requirements['required_colors'] as List<Color>;
      final patternColors = Set<Color>.from(
        pattern.expand((row) => row),
      );
      if (!requiredColors.every(patternColors.contains)) {
        return false;
      }
    }

    return true;
  }
}
