import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/block_definition_service.dart';
import 'unified/pattern_engine.dart';

class PatternAnalyzerService {
  final PatternEngine patternEngine;
  final BlockDefinitionService _blockDefinitionService = BlockDefinitionService();
  final bool enableDebug;

  PatternAnalyzerService({
    PatternEngine? engine,
    this.enableDebug = false,
  }) : patternEngine = engine ?? PatternEngine();

  /// Initialize the service
  Future<void> initialize() async {
    await _blockDefinitionService.loadDefinitions();
  }

  /// Analyze pattern based on blocks and difficulty level
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
        return _generateEmptyAnalysis();
      }
      
      // Convert legacy blocks to BlockCollection
      final blockCollection = BlockCollection.fromLegacyBlocks(blocks);
      
      // Generate pattern to analyze
      final pattern = patternEngine.generatePatternFromBlocks(blockCollection);
      
      // Perform analysis on both blocks and the generated pattern
      final blockAnalysis = patternEngine.analyzeBlockCollection(
        blockCollection,
        difficulty,
      );
      
      final patternAnalysis = patternEngine.analyzePattern(
        pattern: pattern,
        difficulty: difficulty,
      );
      
      // Extract block-specific metrics
      final blockMetrics = _calculateBlockMetrics(blockCollection);
      
      // Generate AI-like advice
      final hint = _generateSmartHint(blockCollection, difficulty, blockMetrics);
      
      // Generate feedback based on difficulty level
      final feedback = _generateFeedback(
        blockAnalysis, 
        blockMetrics,
        difficulty,
      );
      
      // Generate cultural context information
      final culturalContext = _generateCulturalContext(blockCollection);
      
      // Generate learning suggestions based on user's current level
      final suggestions = _generateLearningPathSuggestions(
        blockCollection,
        blockAnalysis,
        difficulty,
      );
      
      return {
        'complexity_analysis': blockAnalysis,
        'pattern_analysis': patternAnalysis,
        'block_metrics': blockMetrics,
        'hint': hint,
        'feedback': feedback,
        'cultural_context': culturalContext,
        'suggestions': suggestions,
        'learning_level': _calculateLearningLevel(blockAnalysis, blockMetrics, difficulty),
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
      return _generateErrorAnalysis(blocks, errorType, errorMessage);
    }
  }
  
  /// Generate empty analysis result
  Map<String, dynamic> _generateEmptyAnalysis() {
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
      'cultural_context': 'Kente cloth traditionally uses blocks of pattern with specific cultural meanings.',
      'suggestions': [
        'Try adding a pattern block to start your design',
        'Add color blocks to define your pattern colors',
        'Experiment with different pattern combinations'
      ],
      'learning_level': 'beginner',
    };
  }
  
  /// Generate error analysis result
  Map<String, dynamic> _generateErrorAnalysis(
    List<Map<String, dynamic>> blocks, 
    String errorType, 
    String errorMessage
  ) {
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
      'hint': 'Try simplifying your pattern or adding more connections between blocks.',
      'feedback': 'I encountered some difficulty analyzing your pattern. Try a different arrangement.',
      'cultural_context': 'Traditional Kente patterns follow specific structural rules for balance and meaning.',
      'suggestions': [
        'Check that your pattern blocks are connected properly',
        'Try using fewer blocks in a more organized structure',
        'Ensure you have both pattern and color blocks in your design'
      ],
      'error': errorMessage,
      'learning_level': 'unknown',
    };
  }
  
  /// Calculate detailed metrics about the blocks used
  Map<String, dynamic> _calculateBlockMetrics(BlockCollection blockCollection) {
    // Count block types
    int patternBlocks = 0;
    int colorBlocks = 0;
    int loopBlocks = 0;
    int structureBlocks = 0;
    int rowBlocks = 0;
    int columnBlocks = 0;
    
    // Track specific pattern types
    Set<String> patternTypes = {};
    Set<String> colorTypes = {};
    
    // Count connections
    int connections = 0;
    int inputConnections = 0;
    int outputConnections = 0;
    
    // Calculate maximum nesting depth
    int maxDepth = 0;
    Map<String, int> blockDepths = {};
    
    // Analyze each block
    for (final block in blockCollection.blocks) {
      // Count by type
      switch (block.type) {
        case BlockType.pattern:
          patternBlocks++;
          patternTypes.add(block.subtype);
          break;
        case BlockType.color:
          colorBlocks++;
          colorTypes.add(block.subtype);
          break;
        case BlockType.loop:
          loopBlocks++;
          break;
        case BlockType.row:
          rowBlocks++;
          structureBlocks++;
          break;
        case BlockType.column:
          columnBlocks++;
          structureBlocks++;
          break;
        default:
          structureBlocks++;
          break;
      }
      
      // Count active connections
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          connections++;
          
          // Count by connection type
          if (connection.type == ConnectionType.input) {
            inputConnections++;
          } else if (connection.type == ConnectionType.output) {
            outputConnections++;
          }
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
    
    // Calculate pattern variety (0-1)
    final patternVariety = patternBlocks > 0 ? patternTypes.length / 6.0 : 0.0; // Assuming 6 pattern types
    
    // Calculate color variety (0-1)
    final colorVariety = colorBlocks > 0 ? colorTypes.length / 8.0 : 0.0; // Assuming 8 color types
    
    // Estimate pattern complexity based on connection structure
    double structuralComplexity = 0.0;
    if (connections > 0) {
      structuralComplexity = (connections / (blockCollection.blocks.length * 2.0))
          .clamp(0.0, 1.0);
    }
    
    return {
      'block_count': blockCollection.blocks.length,
      'pattern_blocks': patternBlocks,
      'color_blocks': colorBlocks,
      'loop_blocks': loopBlocks,
      'structure_blocks': structureBlocks,
      'row_blocks': rowBlocks,
      'column_blocks': columnBlocks,
      'connection_count': connections,
      'input_connections': inputConnections,
      'output_connections': outputConnections,
      'block_variety': blockVariety,
      'pattern_variety': patternVariety,
      'color_variety': colorVariety,
      'pattern_types': patternTypes.toList(),
      'color_types': colorTypes.toList(),
      'structural_complexity': structuralComplexity,
    };
  }
  
  /// Generate a smart hint based on the user's pattern
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
    final patternTypes = metrics['pattern_types'] as List<dynamic>;
    
    // If no blocks, suggest adding a pattern block
    if (blockCount == 0) {
      return "Start by adding a pattern block to your workspace.";
    }
    
    // If no pattern blocks, suggest adding one
    if (patternBlocks == 0) {
      return "Add a pattern block like Dame-Dame (checker) or Nkyinkyim (zigzag) to define your weaving pattern.";
    }
    
    // If no color blocks, suggest adding colors
    if (colorBlocks == 0) {
      return "Add some color blocks to bring your pattern to life with traditional Kente colors like gold, red, green, and blue.";
    }
    
    // If only one pattern type, suggest trying others
    if (patternBlocks > 0 && patternTypes.length == 1) {
      return "Great start! Try adding different pattern types to create more complex designs. Each pattern has cultural significance.";
    }
    
    // Suggest based on difficulty level
    switch (difficulty) {
      case PatternDifficulty.basic:
        if (blockCount < 3) {
          return "Try combining more pattern and color blocks to create a basic design.";
        }
        if (connections == 0) {
          return "Connect your blocks together by dragging from connection points to create patterns.";
        }
        return "Good job! You can experiment with different color combinations to express different cultural meanings.";
        
      case PatternDifficulty.intermediate:
        if (loopBlocks == 0) {
          return "Try using a loop block to repeat patterns and create more complex designs, like traditional Kente cloth.";
        }
        if (connections < 2) {
          return "Connect more blocks together to create interesting pattern combinations.";
        }
        if (patternBlocks < 2) {
          return "Try combining different pattern types to create more complex designs.";
        }
        return "Nice work! Try creating symmetrical patterns with balanced colors for authentic Kente designs.";
        
      case PatternDifficulty.advanced:
        if (structureBlocks == 0) {
          return "Add row or column blocks to organize your patterns more effectively, mimicking the warp and weft of traditional looms.";
        }
        if (connections < 4) {
          return "Create more connections between your blocks to build complex patterns with cultural meaning.";
        }
        if (colorBlocks < 3) {
          return "Traditional Kente uses multiple colors with specific meanings. Try adding more color blocks.";
        }
        return "Great design! Experiment with nested loops for intricate repetitions found in master-woven Kente.";
        
      case PatternDifficulty.master:
        if (patternBlocks < 2 || colorBlocks < 3 || loopBlocks < 1 || structureBlocks < 1) {
          return "Master patterns use multiple pattern types with various colors, loops, and structure blocks to create authentic Kente designs.";
        }
        if (connections < 6) {
          return "Create more complex connections between blocks to achieve master-level Kente patterns.";
        }
        return "Excellent mastery! Your pattern shows deep understanding of Kente tradition. Try incorporating more cultural symbolism by researching the meaning of colors and patterns.";
    }
  }
  
  /// Generate feedback based on analysis results and difficulty level
  String _generateFeedback(
    Map<String, dynamic> analysisResults,
    Map<String, dynamic> blockMetrics,
    PatternDifficulty difficulty,
  ) {
    final blockCount = blockMetrics['block_count'] as int;
    final blockVariety = blockMetrics['block_variety'] as double;
    final connections = blockMetrics['connection_count'] as int;
    final patternVariety = blockMetrics['pattern_variety'] as double;
    final colorVariety = blockMetrics['color_variety'] as double;
    
    // Get complexity metrics
    final complexity = analysisResults['complexity'] as double? ?? 0.0;
    final culturalScore = analysisResults['cultural_score'] as double? ?? 0.0;
    
    // Define minimum expectations based on difficulty
    double minComplexity;
    double minBlockVariety;
    int minConnections;
    double minPatternVariety;
    double minColorVariety;
    
    switch (difficulty) {
      case PatternDifficulty.basic:
        minComplexity = 0.2;
        minBlockVariety = 0.25; // At least 1 type
        minConnections = 0;
        minPatternVariety = 0.16; // At least 1 pattern
        minColorVariety = 0.13; // At least 1 color
        break;
      case PatternDifficulty.intermediate:
        minComplexity = 0.4;
        minBlockVariety = 0.5; // At least 2 types
        minConnections = 1;
        minPatternVariety = 0.33; // At least 2 patterns
        minColorVariety = 0.25; // At least 2 colors
        break;
      case PatternDifficulty.advanced:
        minComplexity = 0.6;
        minBlockVariety = 0.75; // At least 3 types
        minConnections = 3;
        minPatternVariety = 0.5; // At least 3 patterns
        minColorVariety = 0.38; // At least 3 colors
        break;
      case PatternDifficulty.master:
        minComplexity = 0.7;
        minBlockVariety = 1.0; // All 4 types
        minConnections = 5;
        minPatternVariety = 0.67; // At least 4 patterns
        minColorVariety = 0.5; // At least 4 colors
        break;
    }
    
    // Check if pattern meets the difficulty requirements
    final bool meetsComplexity = complexity >= minComplexity;
    final bool meetsBlockVariety = blockVariety >= minBlockVariety;
    final bool meetsConnections = connections >= minConnections;
    final bool meetsPatternVariety = patternVariety >= minPatternVariety;
    final bool meetsColorVariety = colorVariety >= minColorVariety;
    
    // Calculate overall success criteria
    final criteriaCount = 5; // complexity, blockVariety, connections, patternVariety, colorVariety
    int metCriteria = 0;
    if (meetsComplexity) metCriteria++;
    if (meetsBlockVariety) metCriteria++;
    if (meetsConnections) metCriteria++;
    if (meetsPatternVariety) metCriteria++;
    if (meetsColorVariety) metCriteria++;
    
    final successRate = metCriteria / criteriaCount;
    
    if (blockCount == 0) {
      return "Add some blocks to start creating your pattern.";
    }
    
    // Generate feedback based on success rate
    if (successRate >= 0.8) {
      // Excellent feedback (meets 80%+ of criteria)
      switch (difficulty) {
        case PatternDifficulty.basic:
          return "Excellent work! You've created a beautiful basic Kente pattern with good use of colors and patterns.";
        case PatternDifficulty.intermediate:
          return "Fantastic job! Your intermediate pattern shows good understanding of Kente design principles with nice combination of elements.";
        case PatternDifficulty.advanced:
          return "Outstanding achievement! Your advanced pattern demonstrates creativity and deep understanding of complex Kente structures.";
        case PatternDifficulty.master:
          return "Masterful creation! You've designed an authentic Kente pattern with perfect balance of complexity, color, and cultural meaning.";
      }
    } else if (successRate >= 0.6) {
      // Good feedback (meets 60-79% of criteria)
      return "Good work on your ${difficulty.displayName.toLowerCase()} pattern! You've met most of the design criteria with some room for improvement.";
    } else if (successRate >= 0.4) {
      // Developing feedback (meets 40-59% of criteria)
      return "Your pattern is developing well. Keep experimenting with different block combinations to meet ${difficulty.displayName.toLowerCase()} level requirements.";
    } else {
      // Needs improvement feedback (meets <40% of criteria)
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
      if (!meetsPatternVariety) {
        improvements.add("use a wider variety of pattern types");
      }
      if (!meetsColorVariety) {
        improvements.add("incorporate more traditional Kente colors");
      }
      
      if (improvements.isEmpty) {
        return "Your pattern has potential. Continue exploring Kente designs!";
      }
      
      return "Your pattern is a good start. To meet the ${difficulty.displayName.toLowerCase()} level requirements, try to ${improvements.join(', and ')}.";
    }
  }
  
  /// Generate cultural context information based on the blocks used
  String _generateCulturalContext(BlockCollection blockCollection) {
    // Collect pattern and color types
    List<String> patternTypes = [];
    List<String> colorTypes = [];
    
    for (final block in blockCollection.blocks) {
      if (block.type == BlockType.pattern) {
        patternTypes.add(block.subtype);
      } else if (block.type == BlockType.color) {
        colorTypes.add(block.subtype);
      }
    }
    
    // If no blocks, provide general information
    if (patternTypes.isEmpty && colorTypes.isEmpty) {
      return "Kente cloth is a type of silk and cotton fabric made of interwoven cloth strips, native to Ghana. The patterns and colors have specific cultural meanings.";
    }
    
    // Generate cultural context for patterns
    List<String> patternMeanings = [];
    for (final pattern in patternTypes) {
      final meaning = _getPatternCulturalMeaning(pattern);
      if (meaning.isNotEmpty) {
        patternMeanings.add(meaning);
      }
    }
    
    // Generate cultural context for colors
    List<String> colorMeanings = [];
    for (final color in colorTypes) {
      final meaning = _getColorCulturalMeaning(color);
      if (meaning.isNotEmpty) {
        colorMeanings.add(meaning);
      }
    }
    
    // Combine information
    List<String> culturalContext = [];
    
    if (patternMeanings.isNotEmpty) {
      culturalContext.add("Pattern significance: ${patternMeanings.join('. ')}");
    }
    
    if (colorMeanings.isNotEmpty) {
      culturalContext.add("Color symbolism: ${colorMeanings.join('. ')}");
    }
    
    if (culturalContext.isEmpty) {
      return "Kente patterns and colors have deep cultural meanings in Ghanaian traditions, representing various aspects of life, values, and history.";
    }
    
    return culturalContext.join("\n\n");
  }
  
  /// Get cultural meaning for a specific pattern type
  String _getPatternCulturalMeaning(String patternType) {
    switch (patternType) {
      case 'checker_pattern':
        return "The Dame-Dame (checker) pattern symbolizes intelligence and strategic thinking, inspired by the game board";
      case 'zigzag_pattern':
        return "The Nkyinkyim (zigzag) pattern represents life's journey, adaptability, and the idea that life is not a straight path";
      case 'stripes_vertical_pattern':
        return "The Kubi (vertical stripes) pattern represents balance, structure, and the orderliness required for social harmony";
      case 'stripes_horizontal_pattern':
        return "The Babadua (horizontal stripes) pattern symbolizes strength through unity, like a bundle of bamboo sticks is stronger than one";
      case 'square_pattern':
        return "The Eban (square) pattern symbolizes protection, security, and safety like a home fence";
      case 'diamonds_pattern':
        return "The Obaakofo (diamond) pattern represents wisdom, excellence, and the democratic values of collective leadership";
      default:
        return "";
    }
  }
  
  /// Get cultural meaning for a specific color type
  String _getColorCulturalMeaning(String colorType) {
    if (colorType.startsWith('shuttle_')) {
      final color = colorType.substring(8); // Remove 'shuttle_' prefix
      switch (color) {
        case 'gold':
        case 'yellow':
          return "Gold/yellow symbolizes royalty, wealth, high status, spiritual purity, and glory";
        case 'red':
          return "Red represents political and spiritual moods, bloodshed in defense of the community, and sacrificial rites";
        case 'blue':
          return "Blue represents peace, harmony, love, and good fortune";
        case 'green':
          return "Green symbolizes growth, renewal, prosperity, and fertility";
        case 'black':
          return "Black represents spiritual maturity, spiritual energy, and communion with the ancestors";
        case 'white':
          return "White symbolizes purification, cleansing rites, and festive occasions";
        case 'purple':
          return "Purple represents feminine aspects of life and spirituality";
        case 'orange':
          return "Orange symbolizes vitality, energy and the life-giving properties of the sun";
        default:
          return "";
      }
    }
    return "";
  }
  
  /// Generate learning path suggestions based on user's progress
  List<String> _generateLearningPathSuggestions(
    BlockCollection blockCollection,
    Map<String, dynamic> analysis,
    PatternDifficulty difficulty,
  ) {
    List<String> suggestions = [];
    
    final blockMetrics = _calculateBlockMetrics(blockCollection);
    final patternBlocks = blockMetrics['pattern_blocks'] as int;
    final colorBlocks = blockMetrics['color_blocks'] as int;
    final loopBlocks = blockMetrics['loop_blocks'] as int;
    final structureBlocks = blockMetrics['structure_blocks'] as int;
    final connectionCount = blockMetrics['connection_count'] as int;
    
    // Add difficulty-appropriate suggestions
    switch (difficulty) {
      case PatternDifficulty.basic:
        if (patternBlocks == 0) {
          suggestions.add("Try adding a pattern block to create your first design");
        }
        if (colorBlocks < 2) {
          suggestions.add("Experiment with different colors to see how they change your pattern");
        }
        if (connectionCount == 0) {
          suggestions.add("Connect blocks by dragging from connection points between blocks");
        }
        if (patternBlocks > 0 && colorBlocks > 0 && connectionCount > 0) {
          suggestions.add("Great progress! Try the Intermediate difficulty level to learn about loops");
        }
        break;
        
      case PatternDifficulty.intermediate:
        if (loopBlocks == 0) {
          suggestions.add("Add loop blocks to create repeating patterns");
        }
        if (patternBlocks < 2) {
          suggestions.add("Combine different pattern types for more complex designs");
        }
        if (colorBlocks < 3) {
          suggestions.add("Traditional Kente uses three or more colors with specific meanings");
        }
        if (loopBlocks > 0 && patternBlocks >= 2 && connectionCount >= 3) {
          suggestions.add("You're ready to explore Advanced patterns with row and column blocks");
        }
        break;
        
      case PatternDifficulty.advanced:
        if (structureBlocks == 0) {
          suggestions.add("Use row and column blocks to organize patterns like a traditional loom");
        }
        if (loopBlocks < 2) {
          suggestions.add("Create nested loops for more intricate patterns");
        }
        if (connectionCount < 5) {
          suggestions.add("Create more complex connections between your blocks");
        }
        if (structureBlocks > 0 && loopBlocks >= 2 && connectionCount >= 5) {
          suggestions.add("You're demonstrating advanced skills! Try Master level for the ultimate challenge");
        }
        break;
        
      case PatternDifficulty.master:
        if (patternBlocks < 3) {
          suggestions.add("Master Kente weavers combine multiple pattern types in a single cloth");
        }
        if (structureBlocks < 2) {
          suggestions.add("Use more structure blocks to create complex arrangements");
        }
        if (colorBlocks < 4) {
          suggestions.add("Traditional master Kente uses many symbolic colors with precise meanings");
        }
        if (loopBlocks < 2) {
          suggestions.add("Use nested loop structures for authentic master Kente patterns");
        }
        if (patternBlocks >= 3 && structureBlocks >= 2 && colorBlocks >= 4) {
          suggestions.add("Your mastery is impressive! Research real Kente patterns to deepen your understanding");
        }
        break;
    }
    
    // Add general suggestions if needed
    if (suggestions.isEmpty) {
      suggestions = [
        "Experiment with different pattern and color combinations",
        "Learn about the cultural significance of each pattern and color",
        "Try creating symmetrical designs for balance",
        "Challenge yourself to recreate traditional Kente patterns"
      ];
    }
    
    return suggestions;
  }
  
  /// Calculate the user's learning level based on their pattern
  String _calculateLearningLevel(
    Map<String, dynamic> analysis,
    Map<String, dynamic> metrics,
    PatternDifficulty currentDifficulty,
  ) {
    // Get key metrics
    final complexity = analysis['complexity'] as double? ?? 0.0;
    final culturalScore = analysis['cultural_score'] as double? ?? 0.0;
    final blockVariety = metrics['block_variety'] as double;
    final connectionCount = metrics['connection_count'] as int;
    
    // Calculate a composite score weighted by importance
    final compositeScore = complexity * 0.4 + 
                           culturalScore * 0.3 + 
                           blockVariety * 0.2 + 
                           (connectionCount / 10.0).clamp(0.0, 1.0) * 0.1;
    
    // Determine learning level based on composite score and current difficulty
    if (compositeScore < 0.2) {
      return 'beginner';
    } else if (compositeScore < 0.4) {
      return 'developing';
    } else if (compositeScore < 0.6) {
      return 'proficient';
    } else if (compositeScore < 0.8) {
      return 'advanced';
    } else {
      return 'master';
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
      
      // Generate achievement level
      final achievementLevel = _calculateAchievementLevel(
        overallScore,
        difficulty,
      );
      
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
        'suggestions': analysis['suggestions'] as List<dynamic>? ?? [],
        'achievement_level': achievementLevel,
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
        'suggestions': ['Try simplifying your pattern to analyze it'],
        'status': 'error',
        'error': errorMessage,
      };
    }
  }
  
  /// Calculate achievement level based on score and difficulty
  String _calculateAchievementLevel(double score, PatternDifficulty difficulty) {
    // Base thresholds
    double bronzeThreshold = 0.3;
    double silverThreshold = 0.5;
    double goldThreshold = 0.7;
    double masterThreshold = 0.9;
    
    // Adjust thresholds based on difficulty
    switch (difficulty) {
      case PatternDifficulty.basic:
        // Easier to achieve at basic level
        break;
      case PatternDifficulty.intermediate:
        bronzeThreshold = 0.4;
        silverThreshold = 0.6;
        goldThreshold = 0.8;
        masterThreshold = 0.95;
        break;
      case PatternDifficulty.advanced:
        bronzeThreshold = 0.5;
        silverThreshold = 0.7;
        goldThreshold = 0.85;
        masterThreshold = 0.98;
        break;
      case PatternDifficulty.master:
        bronzeThreshold = 0.6;
        silverThreshold = 0.75;
        goldThreshold = 0.9;
        masterThreshold = 1.0; // Perfection required for master achievement at master difficulty
        break;
    }
    
    // Determine achievement level
    if (score >= masterThreshold) {
      return 'master_weaver';
    } else if (score >= goldThreshold) {
      return 'gold';
    } else if (score >= silverThreshold) {
      return 'silver';
    } else if (score >= bronzeThreshold) {
      return 'bronze';
    } else {
      return 'learning';
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
    if (value < 0.3) return 'Limited Cultural Elements';
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
  
  /// Analyze multiple patterns to compare progress
  Future<Map<String, dynamic>> analyzeProgressPatterns(
    List<BlockCollection> patternHistory,
    PatternDifficulty currentDifficulty,
  ) async {
    if (patternHistory.isEmpty) {
      return {
        'progress_trend': 'no_data',
        'improvement_areas': [],
        'strengths': [],
        'learning_curve': 'flat',
      };
    }
    
    // Analyze each pattern
    List<Map<String, dynamic>> analysisResults = [];
    for (final pattern in patternHistory) {
      final blocks = pattern.blocks.map((block) => block.toMap()).toList();
      final analysis = await analyzePattern(
        blocks: blocks,
        difficulty: currentDifficulty,
      );
      analysisResults.add(analysis);
    }
    
    // Extract complexity over time
    List<double> complexityTrend = analysisResults.map((a) {
      final complexity = a['complexity_analysis']?['complexity'] as double? ?? 0.0;
      return complexity;
    }).toList();
    
    // Extract variety over time
    List<double> varietyTrend = analysisResults.map((a) {
      final blockMetrics = a['block_metrics'] as Map<String, dynamic>? ?? {};
      return blockMetrics['block_variety'] as double? ?? 0.0;
    }).toList();
    
    // Identify improvement areas
    List<String> improvementAreas = [];
    final latestAnalysis = analysisResults.last;
    final latestBlockMetrics = latestAnalysis['block_metrics'] as Map<String, dynamic>;
    
    if ((latestBlockMetrics['pattern_variety'] as double? ?? 0.0) < 0.5) {
      improvementAreas.add('pattern_variety');
    }
    
    if ((latestBlockMetrics['color_variety'] as double? ?? 0.0) < 0.5) {
      improvementAreas.add('color_variety');
    }
    
    if ((latestBlockMetrics['structural_complexity'] as double? ?? 0.0) < 0.5) {
      improvementAreas.add('structural_complexity');
    }
    
    // Identify strengths
    List<String> strengths = [];
    if ((latestBlockMetrics['pattern_variety'] as double? ?? 0.0) >= 0.5) {
      strengths.add('pattern_variety');
    }
    
    if ((latestBlockMetrics['color_variety'] as double? ?? 0.0) >= 0.5) {
      strengths.add('color_variety');
    }
    
    if ((latestBlockMetrics['structural_complexity'] as double? ?? 0.0) >= 0.5) {
      strengths.add('structural_complexity');
    }
    
    // Determine learning curve
    String learningCurve;
    if (complexityTrend.length >= 2) {
      final initialComplexity = complexityTrend.first;
      final latestComplexity = complexityTrend.last;
      final difference = latestComplexity - initialComplexity;
      
      if (difference > 0.3) {
        learningCurve = 'steep_improvement';
      } else if (difference > 0.1) {
        learningCurve = 'steady_improvement';
      } else if (difference > -0.1) {
        learningCurve = 'plateau';
      } else {
        learningCurve = 'decline';
      }
    } else {
      learningCurve = 'insufficient_data';
    }
    
    // Generate progress summary
    String progressTrend;
    if (learningCurve == 'steep_improvement' || learningCurve == 'steady_improvement') {
      progressTrend = 'improving';
    } else if (learningCurve == 'plateau') {
      progressTrend = 'stable';
    } else {
      progressTrend = 'mixed';
    }
    
    return {
      'progress_trend': progressTrend,
      'improvement_areas': improvementAreas,
      'strengths': strengths,
      'learning_curve': learningCurve,
      'complexity_trend': complexityTrend,
      'variety_trend': varietyTrend,
      'readiness_for_next_level': _evaluateReadinessForNextLevel(
        latestAnalysis,
        currentDifficulty,
      ),
    };
  }
  
  /// Evaluate if the user is ready to move to the next difficulty level
  String _evaluateReadinessForNextLevel(
    Map<String, dynamic> latestAnalysis,
    PatternDifficulty currentDifficulty,
  ) {
    // Extract key metrics
    final complexityAnalysis = latestAnalysis['complexity_analysis'] as Map<String, dynamic>? ?? {};
    final complexity = complexityAnalysis['complexity'] as double? ?? 0.0;
    final blockMetrics = latestAnalysis['block_metrics'] as Map<String, dynamic>? ?? {};
    final blockVariety = blockMetrics['block_variety'] as double? ?? 0.0;
    
    // Set thresholds based on current difficulty
    double complexityThreshold;
    double varietyThreshold;
    
    switch (currentDifficulty) {
      case PatternDifficulty.basic:
        complexityThreshold = 0.5;
        varietyThreshold = 0.5;
        break;
      case PatternDifficulty.intermediate:
        complexityThreshold = 0.6;
        varietyThreshold = 0.75;
        break;
      case PatternDifficulty.advanced:
        complexityThreshold = 0.7;
        varietyThreshold = 1.0;
        break;
      case PatternDifficulty.master:
        return 'at_maximum_level';
    }
    
    // Check if ready for next level
    if (complexity >= complexityThreshold && blockVariety >= varietyThreshold) {
      return 'ready';
    } else if (complexity >= complexityThreshold || blockVariety >= varietyThreshold) {
      return 'almost_ready';
    } else {
      return 'not_ready';
    }
  }
  
  /// Generate custom feedback for a specific difficulty level
  String generateDifficultyFeedback(PatternDifficulty targetDifficulty) {
    switch (targetDifficulty) {
      case PatternDifficulty.basic:
        return "Basic level focuses on understanding simple patterns and colors. Try using checker patterns and primary colors.";
      case PatternDifficulty.intermediate:
        return "Intermediate level introduces loop blocks to create repeating patterns. Combine multiple pattern types for more complex designs.";
      case PatternDifficulty.advanced:
        return "Advanced level requires structure blocks like rows and columns. Create nested patterns with organized layouts.";
      case PatternDifficulty.master:
        return "Master level demands complex combinations of all block types. Create authentic Kente cloth patterns with cultural significance.";
    }
  }
}