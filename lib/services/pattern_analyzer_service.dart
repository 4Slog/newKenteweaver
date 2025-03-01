import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import 'unified/pattern_engine.dart';

class PatternAnalyzerService {
  final PatternEngine patternEngine;
  final bool enableDebug;

  PatternAnalyzerService({
    PatternEngine? engine,
    this.enableDebug = false,
  }) : patternEngine = engine ?? PatternEngine();

  Future<Map<String, dynamic>> analyzePattern({
    required List<Map<String, dynamic>> blocks,
    required PatternDifficulty difficulty,
  }) async {
    try {
      if (enableDebug) {
        debugPrint('Analyzing pattern with ${blocks.length} blocks');
      }
      
      // Handle empty blocks case
      if (blocks.isEmpty) {
        return {
          'complexity_analysis': {
            'complexity': 0.0,
            'block_count': 0,
            'color_variety': 0.0,
            'symmetry': 0.0,
            'cultural_score': 0.0,
          },
          'block_metrics': {
            'block_count': 0,
            'pattern_blocks': 0,
            'color_blocks': 0,
            'loop_blocks': 0,
            'structure_blocks': 0,
            'connection_count': 0,
            'block_variety': 0.0,
          },
          'hint': 'Start by adding some blocks to your workspace.',
          'feedback': 'Add blocks to begin creating your pattern.',
        };
      }
      
      // Convert legacy blocks to BlockCollection
      final blockCollection = BlockCollection.fromLegacyBlocks(blocks);
      
      // Use pattern engine to analyze
      final analysisResults = patternEngine.analyzeBlockCollection(
        blockCollection,
        difficulty,
      );
      
      // Extract block-specific metrics
      final blockMetrics = _calculateBlockMetrics(blockCollection);
      
      // Generate AI-like advice
      final hint = _generateSmartHint(blockCollection, difficulty, blockMetrics);
      
      // Generate feedback based on difficulty level
      final feedback = _generateFeedback(
        analysisResults, 
        blockMetrics,
        difficulty,
      );
      
      return {
        'complexity_analysis': analysisResults,
        'block_metrics': blockMetrics,
        'hint': hint,
        'feedback': feedback,
      };
    } catch (e) {
      if (enableDebug) {
        debugPrint('Error analyzing pattern: $e');
      }
      
      // Provide more detailed error information
      final errorType = e.runtimeType.toString();
      final errorMessage = e.toString();
      
      debugPrint('Pattern analysis error: [$errorType] $errorMessage');
      
      // Return a fallback analysis with error information
      return {
        'complexity_analysis': {
          'complexity': 0.1,
          'block_count': blocks.length,
          'color_variety': 0.1,
          'symmetry': 0.0,
          'cultural_score': 0.0,
          'error': errorMessage,
        },
        'block_metrics': {
          'block_count': blocks.length,
          'error': errorType,
        },
        'hint': 'Try adding more blocks to create a pattern',
        'feedback': 'I could not properly analyze your pattern. Please try a different arrangement.',
        'error': errorMessage,
      };
    }
  }
  
  Map<String, dynamic> _calculateBlockMetrics(BlockCollection blockCollection) {
    // Count block types
    int patternBlocks = 0;
    int colorBlocks = 0;
    int loopBlocks = 0;
    int structureBlocks = 0;
    
    // Count connections
    int connections = 0;
    
    // Calculate maximum nesting depth
    int maxDepth = 0;
    Map<String, int> blockDepths = {};
    
    // Analyze each block
    for (final block in blockCollection.blocks) {
      // Count by type
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
      
      // Count active connections
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          connections++;
        }
      }
    }
    
    // Calculate block variety score (0-1)
    final totalBlockTypes = 4; // pattern, color, loop, structure
    final usedBlockTypes = [
      patternBlocks > 0,
      colorBlocks > 0,
      loopBlocks > 0,
      structureBlocks > 0,
    ].where((used) => used).length;
    
    final blockVariety = usedBlockTypes / totalBlockTypes;
    
    return {
      'block_count': blockCollection.blocks.length,
      'pattern_blocks': patternBlocks,
      'color_blocks': colorBlocks,
      'loop_blocks': loopBlocks,
      'structure_blocks': structureBlocks,
      'connection_count': connections,
      'block_variety': blockVariety,
    };
  }
  
  String _generateSmartHint(
    BlockCollection blockCollection,
    PatternDifficulty difficulty,
    Map<String, dynamic> metrics,
  ) {
    // Get relevant metrics
    final blockCount = metrics['block_count'] as int;
    final patternBlocks = metrics['pattern_blocks'] as int;
    final colorBlocks = metrics['color_blocks'] as int;
    final loopBlocks = metrics['loop_blocks'] as int;
    final structureBlocks = metrics['structure_blocks'] as int;
    final connections = metrics['connection_count'] as int;
    
    // If no blocks, suggest adding a pattern block
    if (blockCount == 0) {
      return "Start by adding a pattern block to your workspace.";
    }
    
    // If no pattern blocks, suggest adding one
    if (patternBlocks == 0) {
      return "Add a pattern block like Dame-Dame or Nkyinkyim to define your weaving pattern.";
    }
    
    // If no color blocks, suggest adding colors
    if (colorBlocks == 0) {
      return "Add some color blocks to bring your pattern to life with traditional Kente colors.";
    }
    
    // Suggest based on difficulty level
    switch (difficulty) {
      case PatternDifficulty.basic:
        if (blockCount < 3) {
          return "Try combining more pattern and color blocks to create a basic design.";
        }
        return "Good job! You can experiment with different color combinations.";
        
      case PatternDifficulty.intermediate:
        if (loopBlocks == 0) {
          return "Try using a loop block to repeat patterns and create more complex designs.";
        }
        if (connections < 2) {
          return "Connect your blocks together to create more interesting patterns.";
        }
        return "Nice work! Try creating symmetrical patterns with balanced colors.";
        
      case PatternDifficulty.advanced:
        if (structureBlocks == 0) {
          return "Add row or column blocks to organize your patterns more effectively.";
        }
        if (connections < 4) {
          return "Create more connections between your blocks to build complex patterns.";
        }
        return "Great design! Experiment with nested loops for intricate repetitions.";
        
      case PatternDifficulty.master:
        if (patternBlocks < 2 || colorBlocks < 3 || loopBlocks < 1) {
          return "Master patterns use multiple pattern types with various colors and loops.";
        }
        return "Excellent mastery! Try incorporating cultural symbolism in your pattern.";
    }
  }
  
  String _generateFeedback(
    Map<String, dynamic> analysisResults,
    Map<String, dynamic> blockMetrics,
    PatternDifficulty difficulty,
  ) {
    final blockCount = blockMetrics['block_count'] as int;
    final blockVariety = blockMetrics['block_variety'] as double;
    final connections = blockMetrics['connection_count'] as int;
    
    // Get complexity metrics
    final complexity = analysisResults['complexity'] as double? ?? 0.0;
    final colorVariety = analysisResults['color_variety'] as double? ?? 0.0;
    
    // Define minimum expectations based on difficulty
    double minComplexity;
    double minBlockVariety;
    int minConnections;
    
    switch (difficulty) {
      case PatternDifficulty.basic:
        minComplexity = 0.2;
        minBlockVariety = 0.25; // At least 1 type
        minConnections = 0;
        break;
      case PatternDifficulty.intermediate:
        minComplexity = 0.4;
        minBlockVariety = 0.5; // At least 2 types
        minConnections = 1;
        break;
      case PatternDifficulty.advanced:
        minComplexity = 0.6;
        minBlockVariety = 0.75; // At least 3 types
        minConnections = 3;
        break;
      case PatternDifficulty.master:
        minComplexity = 0.7;
        minBlockVariety = 1.0; // All 4 types
        minConnections = 5;
        break;
    }
    
    // Check if pattern meets the difficulty requirements
    final bool meetsComplexity = complexity >= minComplexity;
    final bool meetsBlockVariety = blockVariety >= minBlockVariety;
    final bool meetsConnections = connections >= minConnections;
    
    if (blockCount == 0) {
      return "Add some blocks to start creating your pattern.";
    }
    
    if (meetsComplexity && meetsBlockVariety && meetsConnections) {
      switch (difficulty) {
        case PatternDifficulty.basic:
          return "Great job! You've created a good basic pattern.";
        case PatternDifficulty.intermediate:
          return "Well done! Your pattern shows good understanding of intermediate concepts.";
        case PatternDifficulty.advanced:
          return "Excellent work! Your advanced pattern demonstrates creativity and skill.";
        case PatternDifficulty.master:
          return "Outstanding! You've created a master-level pattern with sophistication and cultural authenticity.";
        default:
          return "Great work on your pattern!";
      }
    } else {
      // Provide specific feedback on what's missing
      List<String> improvements = [];
      
      if (!meetsComplexity) {
        improvements.add("increase pattern complexity");
      }
      if (!meetsBlockVariety) {
        improvements.add("use more types of blocks");
      }
      if (!meetsConnections) {
        improvements.add("connect more blocks together");
      }
      
      if (improvements.isEmpty) {
        return "Your pattern is developing well. Keep experimenting!";
      }
      
      return "Your pattern is developing well. To meet the ${difficulty.displayName} level requirements, try to ${improvements.join(', and ')}.";
    }
  }
  
  /// Analyze a pattern rendered as a grid of colors
  Future<Map<String, dynamic>> analyzeRenderedPattern(
    List<List<Color>> patternGrid,
    PatternDifficulty difficulty,
  ) async {
    try {
      // Check for empty or invalid pattern grid
      if (patternGrid.isEmpty || patternGrid[0].isEmpty) {
        return {
          'metrics': {
            'complexity': 0.0,
            'color_variety': 0.0,
            'symmetry': 0.0,
            'cultural_score': 0.0,
            'overall_score': 0.0,
          },
          'interpretations': {
            'complexity': 'Empty',
            'color_variety': 'Empty',
            'symmetry': 'Empty',
            'cultural_score': 'Empty',
            'overall': 'Empty',
          },
          'suggestions': ['Create a pattern to analyze'],
          'status': 'empty_pattern',
        };
      }
      
      // Use pattern engine's analysis method
      final analysis = patternEngine.analyzePattern(
        pattern: patternGrid,
        difficulty: difficulty,
      );
      
      // Extract metrics
      final complexity = analysis['complexity'] as double;
      final colorVariety = analysis['color_variety'] as double;
      final symmetry = analysis['symmetry'] as double;
      final culturalScore = analysis['cultural_score'] as double;
      
      // Generate interpretations
      final complexityLevel = _interpretComplexity(complexity);
      final colorLevel = _interpretColorVariety(colorVariety);
      final symmetryLevel = _interpretSymmetry(symmetry);
      final culturalLevel = _interpretCulturalScore(culturalScore);
      
      // Overall assessment
      final overallScore = (complexity * 0.3 + colorVariety * 0.2 + 
                           symmetry * 0.2 + culturalScore * 0.3);
      final overallLevel = _interpretOverallScore(overallScore);
      
      return {
        'metrics': {
          'complexity': complexity,
          'color_variety': colorVariety,
          'symmetry': symmetry,
          'cultural_score': culturalScore,
          'overall_score': overallScore,
        },
        'interpretations': {
          'complexity': complexityLevel,
          'color_variety': colorLevel,
          'symmetry': symmetryLevel,
          'cultural_score': culturalLevel,
          'overall': overallLevel,
        },
        'suggestions': analysis['suggestions'],
        'status': 'success',
      };
    } catch (e) {
      if (enableDebug) {
        debugPrint('Error analyzing rendered pattern: $e');
      }
      
      // Log detailed error information
      final errorType = e.runtimeType.toString();
      final errorMessage = e.toString();
      debugPrint('Rendered pattern analysis error: [$errorType] $errorMessage');
      
      return {
        'metrics': {
          'complexity': 0.0,
          'color_variety': 0.0,
          'symmetry': 0.0,
          'cultural_score': 0.0,
          'overall_score': 0.0,
        },
        'interpretations': {
          'complexity': 'Unknown',
          'color_variety': 'Unknown',
          'symmetry': 'Unknown',
          'cultural_score': 'Unknown',
          'overall': 'Unknown',
        },
        'suggestions': ['Try creating a pattern to analyze'],
        'status': 'error',
        'error': errorMessage,
      };
    }
  }
  
  String _interpretComplexity(double value) {
    if (value < 0.3) return 'Simple';
    if (value < 0.5) return 'Basic';
    if (value < 0.7) return 'Intermediate';
    if (value < 0.9) return 'Complex';
    return 'Very Complex';
  }
  
  String _interpretColorVariety(double value) {
    if (value < 0.2) return 'Minimal';
    if (value < 0.4) return 'Limited';
    if (value < 0.6) return 'Moderate';
    if (value < 0.8) return 'Diverse';
    return 'Very Diverse';
  }
  
  String _interpretSymmetry(double value) {
    if (value < 0.3) return 'Asymmetric';
    if (value < 0.5) return 'Slightly Symmetric';
    if (value < 0.7) return 'Moderately Symmetric';
    if (value < 0.9) return 'Highly Symmetric';
    return 'Perfect Symmetry';
  }
  
  String _interpretCulturalScore(double value) {
    if (value < 0.3) return 'Low Cultural Authenticity';
    if (value < 0.5) return 'Basic Cultural Elements';
    if (value < 0.7) return 'Good Cultural Representation';
    if (value < 0.9) return 'Strong Cultural Authenticity';
    return 'Excellent Cultural Authenticity';
  }
  
  String _interpretOverallScore(double value) {
    if (value < 0.3) return 'Beginner';
    if (value < 0.5) return 'Developing';
    if (value < 0.7) return 'Proficient';
    if (value < 0.85) return 'Advanced';
    return 'Master';
  }
}
