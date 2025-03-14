import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/pattern_render_service.dart';
import '../services/logging_service.dart';
import '../services/storage_service.dart';
import '../services/cultural_context_service.dart';
import '../services/gemini_service.dart';

/// Visualization modes for pattern display
enum VisualizationMode {
  /// Standard visualization with no special effects
  standard,
  
  /// Color-coded visualization highlighting different colors
  colorCoded,
  
  /// Block highlight visualization showing execution order
  blockHighlight,
  
  /// Concept highlight visualization showing coding concepts
  conceptHighlight,
  
  /// Cultural context visualization showing cultural elements
  culturalContext,
  
  /// Three-dimensional visualization showing the pattern in 3D
  threeDimensional,
}

/// Service for enhanced pattern visualization with cultural context integration
class PatternVisualizationService extends ChangeNotifier {
  // Singleton pattern implementation
  static final PatternVisualizationService _instance = PatternVisualizationService._internal();
  factory PatternVisualizationService() => _instance;
  
  final PatternRenderService _renderService;
  final LoggingService _loggingService;
  final StorageService _storageService;
  final CulturalContextService _culturalContextService;
  
  // Animation controllers for pattern visualization
  final Map<String, AnimationController> _animationControllers = {};
  
  // Visualization settings
  bool _showGridLines = true;
  bool _showColorLabels = true;
  bool _enableAnimations = true;
  double _zoomLevel = 1.0;
  bool _showCulturalContext = true;
  
  VisualizationMode _currentMode = VisualizationMode.standard;
  
  // Cache for 3D models
  final Map<String, dynamic> _threeDModelCache = {};
  
  PatternVisualizationService._internal()
      : _renderService = PatternRenderService(),
        _loggingService = LoggingService(),
        _storageService = StorageService(),
        _culturalContextService = CulturalContextService(
          geminiService: GeminiService(),
          loggingService: LoggingService(),
          storageService: StorageService(),
        );
  
  /// Initialize the service
  Future<void> initialize() async {
    _loggingService.debug('Initializing pattern visualization service', tag: 'PatternVisualizationService');
    await _loadSettings();
  }
  
  /// Load user settings for visualization
  Future<void> _loadSettings() async {
    try {
      final settingsJson = await _storageService.read('visualization_settings');
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _showGridLines = settings['showGridLines'] ?? true;
        _showColorLabels = settings['showColorLabels'] ?? true;
        _enableAnimations = settings['enableAnimations'] ?? true;
        _zoomLevel = settings['zoomLevel'] ?? 1.0;
        _showCulturalContext = settings['showCulturalContext'] ?? true;
        _currentMode = VisualizationMode.values.firstWhere(
          (mode) => mode.toString().split('.').last == (settings['visualizationMode'] ?? 'standard'),
          orElse: () => VisualizationMode.standard,
        );
      }
    } catch (e) {
      _loggingService.error('Error loading visualization settings: $e', tag: 'PatternVisualizationService');
    }
  }
  
  /// Save user settings for visualization
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'showGridLines': _showGridLines,
        'showColorLabels': _showColorLabels,
        'enableAnimations': _enableAnimations,
        'zoomLevel': _zoomLevel,
        'showCulturalContext': _showCulturalContext,
        'visualizationMode': _currentMode.toString().split('.').last,
      };
      await _storageService.write('visualization_settings', jsonEncode(settings));
    } catch (e) {
      _loggingService.error('Error saving visualization settings: $e', tag: 'PatternVisualizationService');
    }
  }
  
  /// Visualize a pattern with enhanced features
  Future<Map<String, dynamic>> visualizePattern({
    required String patternId,
    required List<Block> blocks,
    required Size viewportSize,
    VisualizationMode? mode,
  }) async {
    final effectiveMode = mode ?? _currentMode;
    
    // Convert blocks to the format expected by the render service
    final blockData = blocks.map((block) => block.toJson()).toList();
    
    // Get base pattern from render service
    final basePattern = await _renderService.renderPattern(
      patternId: patternId,
      blocks: blockData,
      previewSize: viewportSize,
    );
    
    // Apply visualization enhancements based on mode
    final enhancedPattern = await _enhanceVisualization(
      basePattern,
      effectiveMode,
      blocks,
      viewportSize,
    );
    
    // Add cultural context if enabled
    if (_showCulturalContext) {
      enhancedPattern['culturalContext'] = await _getCulturalContext(patternId, blocks);
    }
    
    return enhancedPattern;
  }
  
  /// Enhance the visualization based on the selected mode
  Future<Map<String, dynamic>> _enhanceVisualization(
    Map<String, dynamic> basePattern,
    VisualizationMode mode,
    List<Block> blocks,
    Size viewportSize,
  ) async {
    final enhancedPattern = Map<String, dynamic>.from(basePattern);
    
    switch (mode) {
      case VisualizationMode.colorCoded:
        enhancedPattern['colorMapping'] = _generateColorMapping(blocks);
        enhancedPattern['showColorLabels'] = _showColorLabels;
        break;
        
      case VisualizationMode.blockHighlight:
        enhancedPattern['blockHighlights'] = _generateBlockHighlights(blocks);
        break;
        
      case VisualizationMode.conceptHighlight:
        enhancedPattern['conceptHighlights'] = await _generateConceptHighlights(blocks);
        break;
        
      case VisualizationMode.culturalContext:
        final culturalElements = await _getCulturalElements(blocks);
        enhancedPattern['culturalElements'] = culturalElements;
        break;
        
      case VisualizationMode.threeDimensional:
        enhancedPattern['threeDModel'] = await _generate3DModel(basePattern, blocks);
        break;
        
      case VisualizationMode.standard:
      default:
        // No additional enhancements for standard mode
        break;
    }
    
    // Add common visualization settings
    enhancedPattern['showGridLines'] = _showGridLines;
    enhancedPattern['zoomLevel'] = _zoomLevel;
    enhancedPattern['enableAnimations'] = _enableAnimations;
    
    return enhancedPattern;
  }
  
  /// Generate color mapping for color-coded visualization
  Map<String, dynamic> _generateColorMapping(List<Block> blocks) {
    final colorMap = <String, dynamic>{};
    final colorGroups = <String, List<String>>{};
    
    // Group blocks by color
    for (final block in blocks) {
      if (block.properties.containsKey('color')) {
        final color = block.properties['color'] as String;
        if (!colorGroups.containsKey(color)) {
          colorGroups[color] = [];
        }
        colorGroups[color]!.add(block.id);
      }
    }
    
    // Generate color information including cultural meaning
    colorMap['groups'] = colorGroups;
    colorMap['meanings'] = {
      'red': 'Represents political power and spiritual energy',
      'blue': 'Symbolizes peace, harmony, and love',
      'green': 'Represents growth, fertility, and prosperity',
      'yellow': 'Symbolizes wealth, royalty, and fertility',
      'black': 'Represents spiritual maturity and connection to ancestors',
      'white': 'Symbolizes purification, healing, and festive occasions',
    };
    
    return colorMap;
  }
  
  /// Generate block highlights for block highlight visualization
  Map<String, dynamic> _generateBlockHighlights(List<Block> blocks) {
    final highlights = <String, dynamic>{};
    final executionOrder = <String>[];
    final blockTypes = <String, List<String>>{};
    
    // Determine execution order
    for (final block in blocks) {
      executionOrder.add(block.id);
      
      // Group blocks by type
      final type = block.type.toString().split('.').last;
      if (!blockTypes.containsKey(type)) {
        blockTypes[type] = [];
      }
      blockTypes[type]!.add(block.id);
    }
    
    highlights['executionOrder'] = executionOrder;
    highlights['blockTypes'] = blockTypes;
    
    return highlights;
  }
  
  /// Generate concept highlights for concept highlight visualization
  Future<Map<String, dynamic>> _generateConceptHighlights(List<Block> blocks) async {
    final highlights = <String, dynamic>{};
    final conceptMapping = <String, List<String>>{
      'sequence': [],
      'loop': [],
      'condition': [],
      'function': [],
      'variable': [],
    };
    
    // Map blocks to coding concepts
    for (final block in blocks) {
      final type = block.type.toString().split('.').last;
      
      if (type.contains('loop') || type.contains('repeat')) {
        conceptMapping['loop']!.add(block.id);
      } else if (type.contains('if') || type.contains('condition')) {
        conceptMapping['condition']!.add(block.id);
      } else if (type.contains('function') || type.contains('procedure')) {
        conceptMapping['function']!.add(block.id);
      } else if (type.contains('variable') || type.contains('value')) {
        conceptMapping['variable']!.add(block.id);
      } else {
        conceptMapping['sequence']!.add(block.id);
      }
    }
    
    highlights['conceptMapping'] = conceptMapping;
    highlights['conceptDescriptions'] = {
      'sequence': 'Sequential execution - blocks run one after another',
      'loop': 'Repetition - blocks that repeat a pattern multiple times',
      'condition': 'Decision making - blocks that choose different paths based on conditions',
      'function': 'Reusable procedures - blocks that define reusable patterns',
      'variable': 'Stored values - blocks that store and use values',
    };
    
    return highlights;
  }
  
  /// Get cultural context information for the pattern
  Future<Map<String, dynamic>> _getCulturalContext(String patternId, List<Block> blocks) async {
    try {
      // Get cultural context from the cultural context service
      final patternInfo = await _culturalContextService.getPatternInfo(patternId);
      final context = patternInfo?.description ?? 'No cultural context available';
      
      // Add block-specific cultural elements
      final blockContexts = <String, String>{};
      for (final block in blocks) {
        if (block.properties.containsKey('culturalElement')) {
          blockContexts[block.id] = block.properties['culturalElement'] as String;
        }
      }
      
      return {
        'patternContext': context,
        'blockContexts': blockContexts,
      };
    } catch (e) {
      _loggingService.error('Error getting cultural context: $e', tag: 'PatternVisualizationService');
      return {
        'patternContext': 'Cultural context information unavailable',
        'blockContexts': {},
      };
    }
  }
  
  /// Get cultural elements for cultural context visualization
  Future<Map<String, dynamic>> _getCulturalElements(List<Block> blocks) async {
    final elements = <String, dynamic>{};
    
    // Placeholder for cultural elements that would be retrieved from a database
    // In a real implementation, this would query a database of cultural elements
    elements['symbols'] = {
      'adinkra': [
        {'name': 'Gye Nyame', 'meaning': 'Supremacy of God'},
        {'name': 'Sankofa', 'meaning': 'Return and get it'},
        {'name': 'Dwennimmen', 'meaning': 'Humility and strength'},
      ],
      'kente': [
        {'name': 'Fatia Fata Nkrumah', 'meaning': 'Royalty'},
        {'name': 'Emaa Da', 'meaning': 'Novel creativity'},
        {'name': 'Sika Futuro', 'meaning': 'Gold dust'},
      ],
    };
    
    return elements;
  }
  
  /// Generate a 3D model for three-dimensional visualization
  Future<Map<String, dynamic>> _generate3DModel(Map<String, dynamic> basePattern, List<Block> blocks) async {
    // Check cache first
    final cacheKey = blocks.map((b) => b.id).join('_');
    if (_threeDModelCache.containsKey(cacheKey)) {
      return _threeDModelCache[cacheKey];
    }
    
    // In a real implementation, this would generate a 3D model
    // For now, we'll return a placeholder
    final model = {
      'vertices': <List<double>>[],
      'faces': <List<int>>[],
      'textureCoords': <List<double>>[],
      'normals': <List<double>>[],
    };
    
    // Generate a simple grid of vertices based on the pattern
    final patternWidth = basePattern['width'] as double;
    final patternHeight = basePattern['height'] as double;
    final gridSize = 10;
    
    for (var y = 0; y <= gridSize; y++) {
      for (var x = 0; x <= gridSize; x++) {
        final xPos = x * (patternWidth / gridSize);
        final yPos = y * (patternHeight / gridSize);
        
        // Add vertex
        model['vertices']?.add([xPos, yPos, 0.0]);
        
        // Add texture coordinate
        model['textureCoords']?.add([x / gridSize, y / gridSize]);
        
        // Add normal
        model['normals']?.add([0.0, 0.0, 1.0]);
        
        // Add faces (triangles)
        if (x < gridSize && y < gridSize) {
          final v0 = y * (gridSize + 1) + x;
          final v1 = v0 + 1;
          final v2 = v0 + (gridSize + 1);
          final v3 = v2 + 1;
          
          // First triangle
          model['faces']?.add([v0, v1, v2]);
          
          // Second triangle
          model['faces']?.add([v1, v3, v2]);
        }
      }
    }
    
    // Cache the model
    _threeDModelCache[cacheKey] = model;
    
    return model;
  }
  
  /// Set the current visualization mode
  Future<void> setVisualizationMode(VisualizationMode mode) async {
    _currentMode = mode;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle grid lines
  Future<void> toggleGridLines() async {
    _showGridLines = !_showGridLines;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle color labels
  Future<void> toggleColorLabels() async {
    _showColorLabels = !_showColorLabels;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle animations
  Future<void> toggleAnimations() async {
    _enableAnimations = !_enableAnimations;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Set zoom level
  Future<void> setZoomLevel(double level) async {
    _zoomLevel = level.clamp(0.5, 3.0);
    await _saveSettings();
    notifyListeners();
  }
  
  /// Toggle cultural context
  Future<void> toggleCulturalContext() async {
    _showCulturalContext = !_showCulturalContext;
    await _saveSettings();
    notifyListeners();
  }
  
  /// Get current visualization settings
  Map<String, dynamic> getVisualizationSettings() {
    return {
      'showGridLines': _showGridLines,
      'showColorLabels': _showColorLabels,
      'enableAnimations': _enableAnimations,
      'zoomLevel': _zoomLevel,
      'showCulturalContext': _showCulturalContext,
      'visualizationMode': _currentMode.toString().split('.').last,
    };
  }
  
  /// Clear caches
  Future<void> clearCaches() async {
    _threeDModelCache.clear();
    notifyListeners();
  }
  
  /// Dispose resources
  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }
} 