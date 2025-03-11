import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/pattern_difficulty.dart';
import '../models/block_model.dart';

/// Enum representing different challenge types in the Kente Code Weaver app
enum ChallengeType {
  /// Arranging code blocks in the correct sequence
  blockArrangement,
  
  /// Predicting pattern outcomes from given code
  patternPrediction,
  
  /// Optimizing code for efficiency or readability
  codeOptimization,
  
  /// Finding and fixing bugs in existing code
  debugging,
  
  /// Creating an original pattern according to requirements
  patternCreation,
  
  /// Explaining a concept through a coding example
  conceptExplanation,
  
  /// Matching concepts to their implementations
  matching,
}

/// Types of validation that can be performed on challenges
enum ValidationType {
  /// Verify a specific pattern exists in the solution
  patternExists,
  
  /// Check the number of blocks used of a specific type
  blockCount,
  
  /// Verify specific blocks are included in the solution
  specificBlocksUsed,
  
  /// Validate the overall structure of the pattern
  patternStructure,
  
  /// Check the number and usage of loops
  loopCount,
  
  /// Verify correct usage of colors
  colorUsage,
  
  /// Check solution efficiency
  codeEfficiency,
  
  /// Custom validation function for complex requirements
  customFunction,
}

/// Represents a validation constraint for a challenge
class ValidationConstraint {
  /// Unique identifier for the constraint
  final String id;
  
  /// Description of what the constraint checks
  final String description;
  
  /// Type of validation to perform
  final ValidationType type;
  
  /// Value to validate against
  final dynamic expectedValue;
  
  /// Whether this constraint is required for success or optional
  final bool isRequired;
  
  /// Weight of this constraint in overall evaluation (0.0 to 1.0)
  final double weight;
  
  ValidationConstraint({
    required this.id,
    required this.description,
    required this.type,
    required this.expectedValue,
    this.isRequired = true,
    this.weight = 1.0,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type.toString().split('.').last,
      'expectedValue': expectedValue,
      'isRequired': isRequired,
      'weight': weight,
    };
  }
  
  /// Create from JSON
  factory ValidationConstraint.fromJson(Map<String, dynamic> json) {
    return ValidationConstraint(
      id: json['id'],
      description: json['description'],
      type: ValidationType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => ValidationType.patternExists,
      ),
      expectedValue: json['expectedValue'],
      isRequired: json['isRequired'] ?? true,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : 1.0,
    );
  }
  
  /// Validate a user solution against this constraint
  ValidationResult validate(dynamic userSolution) {
    bool isValid = false;
    String message = '';
    
    try {
      switch (type) {
        case ValidationType.patternExists:
          isValid = _validatePatternExists(userSolution);
          message = isValid 
              ? 'Pattern check passed' 
              : 'Required pattern not found';
          break;
        case ValidationType.blockCount:
          isValid = _validateBlockCount(userSolution);
          message = isValid 
              ? 'Block count check passed' 
              : 'Incorrect number of blocks used';
          break;
        case ValidationType.specificBlocksUsed:
          isValid = _validateSpecificBlocks(userSolution);
          message = isValid 
              ? 'Required blocks check passed' 
              : 'Not all required blocks were used';
          break;
        case ValidationType.patternStructure:
          isValid = _validatePatternStructure(userSolution);
          message = isValid 
              ? 'Pattern structure check passed' 
              : 'Pattern structure does not match requirements';
          break;
        case ValidationType.loopCount:
          isValid = _validateLoopCount(userSolution);
          message = isValid 
              ? 'Loop count check passed' 
              : 'Incorrect number of loops used';
          break;
        case ValidationType.colorUsage:
          isValid = _validateColorUsage(userSolution);
          message = isValid 
              ? 'Color usage check passed' 
              : 'Required colors not used correctly';
          break;
        case ValidationType.codeEfficiency:
          isValid = _validateCodeEfficiency(userSolution);
          message = isValid 
              ? 'Code efficiency check passed' 
              : 'Code could be more efficient';
          break;
        case ValidationType.customFunction:
          isValid = _validateCustomFunction(userSolution);
          message = isValid 
              ? 'Custom function check passed' 
              : 'Custom function validation failed';
          break;
      }
    } catch (e) {
      isValid = false;
      message = 'Validation error: $e';
    }
    
    return ValidationResult(
      constraintId: id,
      isValid: isValid,
      message: message,
      weight: weight,
    );
  }
  
  /// Validate if required pattern exists in solution
  bool _validatePatternExists(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Extract pattern ID from expected value
    final patternId = expectedValue.toString();
    
    // Check if pattern exists in solution
    return solution.blocks.any((block) => 
        block.type == BlockType.pattern && 
        block.subtype == patternId);
  }
  
  /// Validate block count in solution
  bool _validateBlockCount(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Parse expected value as criteria map: {'type': 'color', 'count': 3}
    Map<String, dynamic> criteria;
    if (expectedValue is Map) {
      criteria = Map<String, dynamic>.from(expectedValue);
    } else if (expectedValue is String) {
      criteria = jsonDecode(expectedValue);
    } else {
      return false;
    }
    
    // Count blocks of specified type
    int count = 0;
    final String blockType = criteria['type'];
    
    for (final block in solution.blocks) {
      if (blockType == 'any' || block.type.toString().split('.').last == blockType) {
        count++;
      }
    }
    
    // Get comparison operator and target count
    final String operator = criteria['operator'] ?? '==';
    final int targetCount = criteria['count'];
    
    // Compare using the specified operator
    switch (operator) {
      case '==': return count == targetCount;
      case '>=': return count >= targetCount;
      case '<=': return count <= targetCount;
      case '>': return count > targetCount;
      case '<': return count < targetCount;
      default: return count == targetCount;
    }
  }
  
  /// Validate specific blocks are used in solution
  bool _validateSpecificBlocks(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Expected value should be a list of block IDs
    List<String> requiredBlocks;
    if (expectedValue is List) {
      requiredBlocks = List<String>.from(expectedValue);
    } else if (expectedValue is String) {
      requiredBlocks = List<String>.from(jsonDecode(expectedValue));
    } else {
      return false;
    }
    
    // Check if all required blocks exist in solution
    final solutionBlockIds = solution.blocks.map((b) => b.id).toList();
    return requiredBlocks.every((blockId) => solutionBlockIds.contains(blockId));
  }
  
  /// Validate pattern structure in solution
  bool _validatePatternStructure(dynamic solution) {
    // This would involve more complex checking of block connections
    // For now, implement a basic check based on block types and order
    if (solution is! BlockCollection) return false;
    
    // Expected value might be a pattern template or rules
    // Implementation depends on specific requirements and available solution representation
    if (expectedValue is String && expectedValue == 'dame_dame') {
      // Basic check for alternating color blocks
      var colorBlocks = solution.blocks.where((b) => b.type == BlockType.color).toList();
      if (colorBlocks.length < 2) return false;
      
      // Check if there are at least two different colors
      var uniqueColors = colorBlocks.map((b) => b.subtype).toSet();
      return uniqueColors.length >= 2;
    }
    
    // Default implementation - would need to be customized based on challenge requirements
    return true;
  }
  
  /// Validate loop usage in solution
  bool _validateLoopCount(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Count loop blocks
    int loopCount = solution.blocks.where((b) => 
        b.type == BlockType.structure && 
        b.subtype.contains('loop')).length;
    
    // Compare to expected count
    int expectedCount;
    if (expectedValue is int) {
      expectedCount = expectedValue;
    } else if (expectedValue is String) {
      expectedCount = int.tryParse(expectedValue) ?? 0;
    } else {
      return false;
    }
    
    return loopCount == expectedCount;
  }
  
  /// Validate color usage in solution
  bool _validateColorUsage(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Extract expected colors
    List<String> requiredColors;
    if (expectedValue is List) {
      requiredColors = List<String>.from(expectedValue);
    } else if (expectedValue is String) {
      requiredColors = List<String>.from(jsonDecode(expectedValue));
    } else {
      return false;
    }
    
    // Get colors used in solution
    final usedColors = solution.blocks
        .where((b) => b.type == BlockType.color)
        .map((b) => b.subtype)
        .toList();
    
    // Check if all required colors are used
    return requiredColors.every((color) => usedColors.contains(color));
  }
  
  /// Validate code efficiency
  bool _validateCodeEfficiency(dynamic solution) {
    if (solution is! BlockCollection) return false;
    
    // Simplified efficiency check - could be enhanced based on specific criteria
    // This checks for proper use of loops for repetitive patterns
    
    // Maximum expected block count before requiring loops
    final int thresholdCount = expectedValue is int ? expectedValue : 10;
    
    // Count the total blocks
    final int totalBlocks = solution.blocks.length;
    
    // Count loop blocks
    final int loopBlocks = solution.blocks.where((b) => 
        b.type == BlockType.structure && 
        b.subtype.contains('loop')).length;
    
    // If many blocks and no loops, solution might be inefficient
    if (totalBlocks > thresholdCount && loopBlocks == 0) {
      return false;
    }
    
    return true;
  }
  
  /// Custom function validation
  bool _validateCustomFunction(dynamic solution) {
    // This allows for custom validation logic defined in the challenge
    if (expectedValue is! Map) return false;
    
    final Map<String, dynamic> customFn = Map<String, dynamic>.from(expectedValue);
    
    // Extract function type
    final String fnType = customFn['type'] ?? '';
    
    switch (fnType) {
      case 'alternating_colors':
        // Check for alternating colors in a pattern
        if (solution is! BlockCollection) return false;
        
        final colorBlocks = solution.blocks.where((b) => b.type == BlockType.color).toList();
        if (colorBlocks.length < 4) return false; // Need at least 4 to check pattern
        
        // Check for alternating pattern (A, B, A, B...)
        for (int i = 0; i < colorBlocks.length - 2; i += 2) {
          if (colorBlocks[i].subtype != colorBlocks[i + 2].subtype) return false;
          if (colorBlocks[i + 1].subtype != colorBlocks[i + 3].subtype) return false;
        }
        return true;
        
      default:
        return false;
    }
  }
}

/// Result of validating a specific constraint
class ValidationResult {
  /// ID of the constraint that was validated
  final String constraintId;
  
  /// Whether the validation passed
  final bool isValid;
  
  /// Feedback message about the validation
  final String message;
  
  /// Weight of this validation in overall evaluation
  final double weight;
  
  ValidationResult({
    required this.constraintId,
    required this.isValid,
    required this.message,
    this.weight = 1.0,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'constraintId': constraintId,
      'isValid': isValid,
      'message': message,
      'weight': weight,
    };
  }
}

/// Represents a hint for a challenge
class ChallengeHint {
  /// Unique identifier for the hint
  final String id;
  
  /// Hint text content
  final String content;
  
  /// Unlock cost (XP or time-based)
  final int unlockCost;
  
  /// Order in which the hint should be presented
  final int order;
  
  /// Whether this is a major hint that reveals key information
  final bool isMajor;
  
  /// Additional data for specialized hint types
  final Map<String, dynamic>? additionalData;
  
  ChallengeHint({
    required this.id,
    required this.content,
    this.unlockCost = 0,
    required this.order,
    this.isMajor = false,
    this.additionalData,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'unlockCost': unlockCost,
      'order': order,
      'isMajor': isMajor,
      'additionalData': additionalData,
    };
  }
  
  /// Create from JSON
  factory ChallengeHint.fromJson(Map<String, dynamic> json) {
    return ChallengeHint(
      id: json['id'],
      content: json['content'],
      unlockCost: json['unlockCost'] ?? 0,
      order: json['order'] ?? 0,
      isMajor: json['isMajor'] ?? false,
      additionalData: json['additionalData'],
    );
  }
  
  /// Create a simple hint
  factory ChallengeHint.simple(String content, {int order = 0}) {
    return ChallengeHint(
      id: 'hint_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      order: order,
    );
  }
}

/// Represents a cultural context element for a challenge
class CulturalContext {
  /// Title of the cultural context
  final String title;
  
  /// Detailed description of the cultural significance
  final String description;
  
  /// Path to related image asset
  final String? imageAsset;
  
  /// Map of colors to their cultural meanings
  final Map<String, String>? colorMeanings;
  
  /// Historical background information
  final String? historicalContext;
  
  /// Traditional uses of the pattern
  final String? traditionalUse;
  
  /// Additional data for specialized context types
  final Map<String, dynamic>? additionalData;
  
  CulturalContext({
    required this.title,
    required this.description,
    this.imageAsset,
    this.colorMeanings,
    this.historicalContext,
    this.traditionalUse,
    this.additionalData,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageAsset': imageAsset,
      'colorMeanings': colorMeanings,
      'historicalContext': historicalContext,
      'traditionalUse': traditionalUse,
      'additionalData': additionalData,
    };
  }
  
  /// Create from JSON
  factory CulturalContext.fromJson(Map<String, dynamic> json) {
    return CulturalContext(
      title: json['title'],
      description: json['description'],
      imageAsset: json['imageAsset'],
      colorMeanings: json['colorMeanings'] != null
          ? Map<String, String>.from(json['colorMeanings'])
          : null,
      historicalContext: json['historicalContext'],
      traditionalUse: json['traditionalUse'],
      additionalData: json['additionalData'],
    );
  }
}

/// Result of a completed challenge
class ChallengeResult {
  /// Whether the challenge was completed successfully
  final bool success;
  
  /// Score achieved (0.0 to 1.0)
  final double score;
  
  /// Time taken to complete the challenge in seconds
  final int timeTaken;
  
  /// IDs of concepts that were mastered during this challenge
  final List<String> conceptsMastered;
  
  /// Detailed validation results for each constraint
  final List<ValidationResult> validationResults;
  
  /// Additional data about the completion
  final Map<String, dynamic>? additionalData;
  
  /// Timestamp when the challenge was completed
  final DateTime completedAt;
  
  ChallengeResult({
    required this.success,
    required this.score,
    required this.timeTaken,
    this.conceptsMastered = const [],
    this.validationResults = const [],
    this.additionalData,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'score': score,
      'timeTaken': timeTaken,
      'conceptsMastered': conceptsMastered,
      'validationResults': validationResults.map((r) => r.toJson()).toList(),
      'additionalData': additionalData,
      'completedAt': completedAt.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory ChallengeResult.fromJson(Map<String, dynamic> json) {
    return ChallengeResult(
      success: json['success'] ?? false,
      score: (json['score'] ?? 0.0).toDouble(),
      timeTaken: json['timeTaken'] ?? 0,
      conceptsMastered: json['conceptsMastered'] != null
          ? List<String>.from(json['conceptsMastered'])
          : [],
      validationResults: json['validationResults'] != null
          ? (json['validationResults'] as List)
              .map((r) => ValidationResult(
                    constraintId: r['constraintId'],
                    isValid: r['isValid'],
                    message: r['message'],
                    weight: r['weight'] ?? 1.0,
                  ))
              .toList()
          : [],
      additionalData: json['additionalData'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
    );
  }
}

/// Main challenge model class
class ChallengeModel {
  /// Unique identifier for the challenge
  final String id;
  
  /// Display title of the challenge
  final String title;
  
  /// Detailed description of what the user needs to do
  final String description;
  
  /// Clear statement of the objective
  final String objective;
  
  /// Type of challenge
  final ChallengeType type;
  
  /// Difficulty level of the challenge
  final PatternDifficulty difficulty;
  
  /// List of coding concepts taught by this challenge
  final List<String> conceptsTaught;
  
  /// Required blocks that must be used in the solution
  final List<String> requiredBlocks;
  
  /// Optional blocks that are available but not required
  final List<String> optionalBlocks;
  
  /// Validation constraints that define success criteria
  final List<ValidationConstraint> validationConstraints;
  
  /// Hints available to the user
  final List<ChallengeHint> hints;
  
  /// Cultural context information related to the challenge
  final CulturalContext? culturalContext;
  
  /// Maximum time allowed for the challenge in seconds (0 for unlimited)
  final int timeLimit;
  
  /// Minimum score required to pass (0.0 to 1.0)
  final double passingScore;
  
  /// XP rewarded for completion
  final int xpReward;
  
  /// Whether the challenge requires premium access
  final bool isPremium;
  
  /// Starter code provided to the user
  final BlockCollection? starterBlocks;
  
  /// Additional parameters specific to this challenge type
  final Map<String, dynamic> parameters;
  
  /// Story or lesson this challenge belongs to
  final String? parentId;
  
  /// Metadata for specialized challenge types
  final Map<String, dynamic>? metadata;
  
  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.type,
    required this.difficulty,
    this.conceptsTaught = const [],
    this.requiredBlocks = const [],
    this.optionalBlocks = const [],
    this.validationConstraints = const [],
    this.hints = const [],
    this.culturalContext,
    this.timeLimit = 0,
    this.passingScore = 0.7,
    this.xpReward = 50,
    this.isPremium = false,
    this.starterBlocks,
    this.parameters = const {},
    this.parentId,
    this.metadata,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'objective': objective,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'conceptsTaught': conceptsTaught,
      'requiredBlocks': requiredBlocks,
      'optionalBlocks': optionalBlocks,
      'validationConstraints': validationConstraints.map((c) => c.toJson()).toList(),
      'hints': hints.map((h) => h.toJson()).toList(),
      'culturalContext': culturalContext?.toJson(),
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'xpReward': xpReward,
      'isPremium': isPremium,
      'starterBlocks': starterBlocks?.toJson(),
      'parameters': parameters,
      'parentId': parentId,
      'metadata': metadata,
    };
  }
  
  /// Create from JSON
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      objective: json['objective'] ?? json['description'],
      type: ChallengeType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => ChallengeType.patternCreation,
      ),
      difficulty: PatternDifficulty.values.firstWhere(
        (d) => d.toString().split('.').last == json['difficulty'],
        orElse: () => PatternDifficulty.basic,
      ),
      conceptsTaught: json['conceptsTaught'] != null
          ? List<String>.from(json['conceptsTaught'])
          : [],
      requiredBlocks: json['requiredBlocks'] != null
          ? List<String>.from(json['requiredBlocks'])
          : [],
      optionalBlocks: json['optionalBlocks'] != null
          ? List<String>.from(json['optionalBlocks'])
          : [],
      validationConstraints: json['validationConstraints'] != null
          ? (json['validationConstraints'] as List)
              .map((c) => ValidationConstraint.fromJson(c))
              .toList()
          : [],
      hints: json['hints'] != null
          ? (json['hints'] as List)
              .map((h) => ChallengeHint.fromJson(h))
              .toList()
          : [],
      culturalContext: json['culturalContext'] != null
          ? CulturalContext.fromJson(json['culturalContext'])
          : null,
      timeLimit: json['timeLimit'] ?? 0,
      passingScore: (json['passingScore'] ?? 0.7).toDouble(),
      xpReward: json['xpReward'] ?? 50,
      isPremium: json['isPremium'] ?? false,
      starterBlocks: json['starterBlocks'] != null
          ? BlockCollection.fromJson(json['starterBlocks'])
          : null,
      parameters: json['parameters'] ?? {},
      parentId: json['parentId'],
      metadata: json['metadata'],
    );
  }
  
  /// Get difficulty-adjusted parameters based on challenge difficulty
  T getDifficultyParameter<T>(String key, Map<String, T> difficultyMap, T defaultValue) {
    // First check if a difficulty-specific value exists in parameters
    final difficultyKey = '${difficulty.toString().split('.').last}_$key';
    if (parameters.containsKey(difficultyKey)) {
      return parameters[difficultyKey] as T;
    }
    
    // Then check if the key exists in parameters
    if (parameters.containsKey(key)) {
      return parameters[key] as T;
    }
    
    // Use the difficulty map if provided
    if (difficultyMap.containsKey(difficulty.toString().split('.').last)) {
      return difficultyMap[difficulty.toString().split('.').last]!;
    }
    
    // Fall back to default value
    return defaultValue;
  }
  
  /// Validate a user solution against all constraints
  ChallengeResult validateSolution(dynamic solution, int timeTaken) {
    // List to store individual validation results
    final results = <ValidationResult>[];
    
    // Validate against each constraint
    for (final constraint in validationConstraints) {
      final result = constraint.validate(solution);
      results.add(result);
    }
    
    // Calculate overall score
    double totalWeight = 0;
    double weightedScore = 0;
    
    for (final result in results) {
      totalWeight += result.weight;
      if (result.isValid) {
        weightedScore += result.weight;
      }
    }
    
    // Normalize score
    final normalizedScore = totalWeight > 0 ? weightedScore / totalWeight : 0.0;
    
    // Determine success based on passing score
    final success = normalizedScore >= passingScore;
    
    // Determine concepts mastered
    List<String> mastered = [];
    if (success) {
      // If successful, consider all taught concepts as mastered
      // In a real implementation, this might be more nuanced
      mastered = List.from(conceptsTaught);
    }
    
    return ChallengeResult(
      success: success,
      score: normalizedScore,
      timeTaken: timeTaken,
      conceptsMastered: mastered,
      validationResults: results,
    );
  }

  /// Create a basic challenge with minimal configuration
  factory ChallengeModel.createBasic({
    required String id,
    required String title,
    required String description,
    required ChallengeType type,
    required PatternDifficulty difficulty,
    List<String> conceptsTaught = const [],
    List<String> requiredBlocks = const [],
  }) {
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      objective: description,
      type: type,
      difficulty: difficulty,
      conceptsTaught: conceptsTaught,
      requiredBlocks: requiredBlocks,
      validationConstraints: [
        // Add a basic constraint that required blocks are used
        ValidationConstraint(
          id: '${id}_required_blocks',
          description: 'Use all required blocks',
          type: ValidationType.specificBlocksUsed,
          expectedValue: requiredBlocks,
        ),
      ],
      hints: [
        ChallengeHint(
          id: '${id}_hint_1',
          content: 'Start by adding the required blocks to your workspace.',
          order: 0,
        ),
      ],
    );
  }
  
  /// Generate a challenge instance appropriate for the given difficulty
  factory ChallengeModel.forDifficulty(
    PatternDifficulty difficulty,
    String id,
    String title,
    ChallengeType type,
    List<String> concepts,
  ) {
    // Base description and objectives
    String description;
    String objective;
    List<ValidationConstraint> constraints = [];
    List<ChallengeHint> challengeHints = [];
    int xpReward;
    double passingScore;
    Map<String, dynamic> params = {};
    
    switch (type) {
      case ChallengeType.blockArrangement:
        description = 'Arrange the blocks in the correct sequence.';
        objective = 'Create a pattern by arranging blocks in the right order.';
        xpReward = 50;
        passingScore = 0.8;
        params = {
          'maxBlocks': 6,
          'requiredPatterns': ['checker_pattern'],
          'availableColors': ['black', 'gold'],
        };
        break;
      
      case ChallengeType.patternPrediction:
        description = 'Predict the pattern that will be created by the given code.';
        objective = 'Analyze the code and select the correct pattern outcome.';
        xpReward = 75;
        passingScore = 0.8;
        params = {
          'maxBlocks': 8,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue'],
        };
        break;
      
      case ChallengeType.codeOptimization:
        description = 'Optimize the code to create the pattern more efficiently.';
        objective = 'Reduce the number of blocks while maintaining the same pattern.';
        xpReward = 100;
        passingScore = 0.7;
        params = {
          'maxBlocks': 10,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue'],
          'requireLoops': true,
        };
        break;
      
      case ChallengeType.debugging:
        description = 'Find and fix the bugs in the pattern code.';
        objective = 'Identify and correct the issues to create the intended pattern.';
        xpReward = 100;
        passingScore = 0.8;
        params = {
          'maxBlocks': 12,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue'],
          'requireLoops': true,
        };
        break;
      
      case ChallengeType.patternCreation:
        description = 'Create a pattern that meets the given requirements.';
        objective = 'Design and implement a pattern using the available blocks.';
        xpReward = 150;
        passingScore = 0.7;
        params = {
          'maxBlocks': 15,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern', 'diamonds_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue', 'green'],
          'requireLoops': true,
          'allowNestedLoops': true,
        };
        break;
      
      case ChallengeType.conceptExplanation:
        description = 'Explain the concept through a coding example.';
        objective = 'Create a pattern that demonstrates the given concept.';
        xpReward = 125;
        passingScore = 0.7;
        params = {
          'maxBlocks': 12,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern', 'diamonds_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue', 'green'],
          'requireLoops': true,
        };
        break;
      
      case ChallengeType.matching:
        description = 'Match each concept with its correct implementation.';
        objective = 'Connect concepts to their corresponding code examples.';
        xpReward = 200;
        passingScore = 0.8;
        params = {
          'maxBlocks': 20,
          'requiredPatterns': ['checker_pattern', 'zigzag_pattern', 'diamonds_pattern', 'square_pattern'],
          'availableColors': ['black', 'gold', 'red', 'blue', 'green', 'purple', 'white'],
          'requireStructure': true,
          'allowNestedLoops': true,
          'requireCulturalConnection': true,
        };
        break;
    }
    
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      objective: objective,
      type: type,
      difficulty: difficulty,
      conceptsTaught: concepts,
      xpReward: xpReward,
      passingScore: passingScore,
      validationConstraints: constraints,
      hints: challengeHints,
      parameters: params,
      culturalContext: _createCulturalContextForDifficulty(difficulty, type),
    );
  }
  
  /// Create appropriate cultural context based on difficulty and challenge type
  static CulturalContext? _createCulturalContextForDifficulty(
    PatternDifficulty difficulty,
    ChallengeType type,
  ) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return CulturalContext(
          title: 'Dame-Dame Pattern',
          description: 'The Dame-Dame (checkerboard) pattern represents duality in Akan philosophy. '
                     'It symbolizes the balance between opposites - light and dark, joy and sorrow, '
                     'the seen and unseen.',
          imageAsset: 'assets/images/patterns/dame_dame_context.png',
          colorMeanings: {
            'black': 'Maturity and spiritual energy',
            'gold': 'Royalty, wealth, and spiritual vitality',
          },
        );
      
      case PatternDifficulty.intermediate:
        return CulturalContext(
          title: 'Nkyinkyim Pattern',
          description: 'The Nkyinkyim (zigzag) pattern represents life\'s twisting journey. '
                     'It symbolizes initiative, dynamism, and versatility in life\'s endeavors.',
          imageAsset: 'assets/images/patterns/nkyinkyim_context.png',
          colorMeanings: {
            'black': 'Maturity and spiritual energy',
            'gold': 'Royalty and wealth',
            'blue': 'Peace, harmony, and love',
            'red': 'Political and spiritual significance',
          },
          historicalContext: 'Nkyinkyim is inspired by the Adinkra symbol of the same name, '
                           'representing the twisting nature of life\'s journey.',
        );
      
      case PatternDifficulty.advanced:
        return CulturalContext(
          title: 'Complex Kente Patterns',
          description: 'Complex patterns in Kente cloth often combine multiple symbolic elements '
                     'to tell rich cultural stories and convey specific messages.',
          imageAsset: 'assets/images/patterns/complex_pattern_context.png',
          colorMeanings: {
            'black': 'Maturity and spiritual energy',
            'gold': 'Royalty and prosperity',
            'blue': 'Peace and harmony',
            'green': 'Growth, renewal, and fertility',
            'red': 'Political power and spiritual significance',
          },
          historicalContext: 'Kente cloth originated with the Ashanti people of Ghana and has become '
                           'an important cultural symbol throughout West Africa and the African diaspora.',
          traditionalUse: 'Complex Kente patterns were traditionally reserved for royalty and worn '
                        'during important ceremonies and festivals.',
        );
      
      case PatternDifficulty.expert:
        return CulturalContext(
          title: 'Master Weaver Traditions',
          description: 'Master weavers create cloth that speaks through its patterns, telling stories '
                     'of culture, history, and values. Each pattern has meaning, and the arrangement '
                     'of patterns creates a narrative.',
          imageAsset: 'assets/images/patterns/master_pattern_context.png',
          colorMeanings: {
            'black': 'Maturity, spiritual energy, and connection to ancestors',
            'gold': 'Royalty, wealth, high status, and spiritual vitality',
            'green': 'Growth, renewal, prosperity, and agricultural fertility',
            'red': 'Political and spiritual significance, sacrificial rites, blood ties',
            'blue': 'Peace, harmony, love, and devotion',
            'purple': 'Feminine aspects of life, healing, and nurturing',
            'white': 'Purification, sanctification, and festive occasions',
          },
          historicalContext: 'The tradition of Kente weaving has been passed down through generations, '
                           'with master weavers holding positions of honor. Each master weaver would '
                           'develop their own signature patterns and techniques.',
          traditionalUse: 'Master-woven Kente was reserved for kings, queens, and high-ranking officials '
                        'for ceremonial occasions. Each pattern could signify a specific proverb or '
                        'historical event.',
        );
    }
  }
}

/// A factory for challenge templates based on coding concepts
class ChallengeTemplateFactory {
  /// Create a sequence challenge template
  static ChallengeModel createSequenceChallenge({
    required String id,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    return ChallengeModel.forDifficulty(
      difficulty,
      id,
      title,
      ChallengeType.blockArrangement,
      ['sequence', 'pattern', 'order'],
    );
  }
  
  /// Create a loop challenge template
  static ChallengeModel createLoopChallenge({
    required String id,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    return ChallengeModel.forDifficulty(
      difficulty,
      id,
      title,
      ChallengeType.patternCreation,
      ['loop', 'repetition', 'pattern'],
    );
  }
  
  /// Create a conditional challenge template
  static ChallengeModel createConditionalChallenge({
    required String id,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    final challenge = ChallengeModel.forDifficulty(
      difficulty,
      id,
      title,
      ChallengeType.patternCreation,
      ['conditionals', 'decision', 'flow'],
    );
    
    // Add conditional-specific parameters
    final updatedParams = Map<String, dynamic>.from(challenge.parameters);
    updatedParams['conditionalsEnabled'] = true;
    updatedParams['decisionBlocks'] = ['if_block', 'if_else_block'];
    
    return ChallengeModel(
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      objective: challenge.objective,
      type: challenge.type,
      difficulty: challenge.difficulty,
      conceptsTaught: challenge.conceptsTaught,
      requiredBlocks: challenge.requiredBlocks,
      optionalBlocks: challenge.optionalBlocks,
      validationConstraints: challenge.validationConstraints,
      hints: challenge.hints,
      culturalContext: challenge.culturalContext,
      timeLimit: challenge.timeLimit,
      passingScore: challenge.passingScore,
      xpReward: challenge.xpReward,
      isPremium: challenge.isPremium,
      starterBlocks: challenge.starterBlocks,
      parameters: updatedParams,
      parentId: challenge.parentId,
      metadata: challenge.metadata,
    );
  }
  
  /// Create a pattern debugging challenge template
  static ChallengeModel createDebuggingChallenge({
    required String id,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    // Start with base challenge
    final baseChallenge = ChallengeModel.forDifficulty(
      difficulty,
      id,
      title,
      ChallengeType.debugging,
      ['debugging', 'problem-solving', 'pattern-correction'],
    );
    
    // Create starter blocks with intentional bugs
    final List<Block> buggyBlocks = [];
    
    switch (difficulty) {
      case PatternDifficulty.basic:
        // Basic bug: Wrong color sequence
        buggyBlocks.add(Block(
          id: 'pattern_block_1',
          name: 'Checker Pattern',
          description: 'A traditional Kente pattern',
          type: BlockType.pattern,
          subtype: 'checker_pattern',
          properties: {'value': 'checker'},
          connections: [],
          iconPath: 'assets/images/blocks/checker_pattern.png',
          colorHex: '#2196F3', // Blue color hex
        ));
        
        // Two same colors - should be alternating
        buggyBlocks.add(Block(
          id: 'color_block_1',
          name: 'Black Thread',
          description: 'A traditional Kente color',
          type: BlockType.color,
          subtype: 'shuttle_black',
          properties: {'color': Colors.black.value.toString()},
          connections: [],
          iconPath: 'assets/images/blocks/shuttle_black.png',
          colorHex: '#000000', // Black color hex
        ));
        
        buggyBlocks.add(Block(
          id: 'color_block_2',
          name: 'Black Thread',
          description: 'A traditional Kente color',
          type: BlockType.color,
          subtype: 'shuttle_black',
          properties: {'color': Colors.black.value.toString()},
          connections: [],
          iconPath: 'assets/images/blocks/shuttle_black.png',
          colorHex: '#000000', // Black color hex
        ));
        break;
        
      case PatternDifficulty.intermediate:
        // Intermediate bug: Loop with wrong count
        buggyBlocks.add(Block(
          id: 'pattern_block_1',
          name: 'Zigzag Pattern',
          description: 'A traditional Kente pattern',
          type: BlockType.pattern,
          subtype: 'zigzag_pattern',
          properties: {'value': 'zigzag'},
          connections: [],
          iconPath: 'assets/images/blocks/zigzag_pattern.png',
          colorHex: '#2196F3', // Blue color hex
        ));
        
        buggyBlocks.add(Block(
          id: 'loop_block_1',
          name: 'Loop Block',
          description: 'Repeats the pattern',
          type: BlockType.structure,
          subtype: 'loop_block',
          properties: {'value': '0'}, // Bug: Loop count of zero!
          connections: [],
          iconPath: 'assets/images/blocks/loop_icon.png',
          colorHex: '#4CAF50', // Green color hex
        ));
        break;
        
      case PatternDifficulty.advanced:
      case PatternDifficulty.expert:
        // Advanced bug: Nested loops with incorrect connections
        buggyBlocks.add(Block(
          id: 'pattern_block_1',
          name: 'Complex Pattern',
          description: 'A complex traditional Kente pattern',
          type: BlockType.pattern,
          subtype: 'complex_pattern',
          properties: {'value': 'complex'},
          connections: [],
          iconPath: 'assets/images/blocks/complex_pattern.png',
          colorHex: '#2196F3', // Blue color hex
        ));
        
        buggyBlocks.add(Block(
          id: 'outer_loop',
          name: 'Outer Loop',
          description: 'Main repeating structure',
          type: BlockType.structure,
          subtype: 'loop_block',
          properties: {'value': '3'},
          connections: [],
          iconPath: 'assets/images/blocks/loop_icon.png',
          colorHex: '#4CAF50', // Green color hex
        ));
        
        buggyBlocks.add(Block(
          id: 'inner_loop',
          name: 'Inner Loop',
          description: 'Nested repeating structure',
          type: BlockType.structure,
          subtype: 'loop_block',
          properties: {'value': '2'},
          // Bug: Inner loop not properly connected to outer loop
          connections: [],
          iconPath: 'assets/images/blocks/loop_icon.png',
          colorHex: '#4CAF50', // Green color hex
        ));
        break;
    }
    
    // Add specialized debugging instructions
    String debuggingObjective;
    switch (difficulty) {
      case PatternDifficulty.basic:
        debuggingObjective = 'Find and fix the pattern error. Hint: The colors should alternate.';
        break;
      case PatternDifficulty.intermediate:
        debuggingObjective = 'Correct the loop settings to make the pattern repeat properly.';
        break;
      case PatternDifficulty.advanced:
      case PatternDifficulty.expert:
        debuggingObjective = 'Fix the connections between the nested loops to create a proper complex pattern.';
        break;
    }
    
    // Create the debugging challenge
    return ChallengeModel(
      id: baseChallenge.id,
      title: baseChallenge.title,
      description: 'Debug the pattern to make it work correctly. ' + baseChallenge.description,
      objective: debuggingObjective,
      type: ChallengeType.debugging,
      difficulty: baseChallenge.difficulty,
      conceptsTaught: baseChallenge.conceptsTaught,
      validationConstraints: baseChallenge.validationConstraints,
      hints: baseChallenge.hints,
      culturalContext: baseChallenge.culturalContext,
      passingScore: baseChallenge.passingScore,
      xpReward: baseChallenge.xpReward,
      starterBlocks: BlockCollection(blocks: buggyBlocks),
      parameters: baseChallenge.parameters,
    );
  }
  
  /// Create a pattern prediction challenge
  static ChallengeModel createPredictionChallenge({
    required String id,
    required String title,
    required PatternDifficulty difficulty,
  }) {
    // Create a challenge where users predict the outcome of a code sequence
    final concepts = ['pattern-recognition', 'code-reading', 'prediction'];
    
    // Base challenge with different structure based on difficulty
    final challenge = ChallengeModel.forDifficulty(
      difficulty, 
      id, 
      title,
      ChallengeType.patternPrediction,
      concepts
    );
    
    // Add prediction-specific parameters
    final updatedParams = Map<String, dynamic>.from(challenge.parameters);
    updatedParams['showCodeOnly'] = true;
    updatedParams['multipleChoiceOptions'] = 4;
    updatedParams['animateExecution'] = true;
    
    return ChallengeModel(
      id: challenge.id,
      title: challenge.title,
      description: 'Predict what pattern this code will create when run.',
      objective: 'Analyze the code and predict the resulting pattern without running it.',
      type: ChallengeType.patternPrediction,
      difficulty: difficulty,
      conceptsTaught: concepts,
      parameters: updatedParams,
      culturalContext: challenge.culturalContext,
      timeLimit: 120, // 2 minutes to make a prediction
      xpReward: challenge.xpReward + 25, // Extra XP for prediction challenges
      hints: challenge.hints,
    );
  }
}
