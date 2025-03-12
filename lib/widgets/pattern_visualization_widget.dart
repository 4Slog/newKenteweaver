import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../services/pattern_visualization_service.dart';

/// Widget for displaying patterns with enhanced visualization features
class PatternVisualizationWidget extends StatefulWidget {
  /// Pattern ID to visualize
  final String patternId;
  
  /// Blocks that make up the pattern
  final List<Block> blocks;
  
  /// Initial visualization mode
  final VisualizationMode initialMode;
  
  /// Whether to show visualization controls
  final bool showControls;
  
  /// Whether to show cultural context
  final bool showCulturalContext;
  
  /// Callback when a block is tapped
  final Function(String blockId)? onBlockTap;
  
  /// Creates a new pattern visualization widget
  const PatternVisualizationWidget({
    Key? key,
    required this.patternId,
    required this.blocks,
    this.initialMode = VisualizationMode.standard,
    this.showControls = true,
    this.showCulturalContext = true,
    this.onBlockTap,
  }) : super(key: key);

  @override
  State<PatternVisualizationWidget> createState() => _PatternVisualizationWidgetState();
}

class _PatternVisualizationWidgetState extends State<PatternVisualizationWidget> with SingleTickerProviderStateMixin {
  late final PatternVisualizationService _visualizationService;
  late VisualizationMode _currentMode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  Map<String, dynamic>? _patternData;
  bool _isLoading = true;
  String? _errorMessage;
  double _zoomLevel = 1.0;
  
  @override
  void initState() {
    super.initState();
    _visualizationService = PatternVisualizationService();
    _currentMode = widget.initialMode;
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Load pattern data
    _loadPatternData();
  }
  
  Future<void> _loadPatternData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final patternData = await _visualizationService.visualizePattern(
        patternId: widget.patternId,
        blocks: widget.blocks,
        viewportSize: MediaQuery.of(context).size,
        mode: _currentMode,
      );
      
      setState(() {
        _patternData = patternData;
        _isLoading = false;
      });
      
      // Start animation
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading pattern: $e';
        _isLoading = false;
      });
    }
  }
  
  void _changeVisualizationMode(VisualizationMode mode) {
    if (_currentMode == mode) return;
    
    setState(() {
      _currentMode = mode;
    });
    
    _loadPatternData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Visualization controls
        if (widget.showControls)
          _buildControls(),
          
        // Pattern visualization
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
                  : _buildPatternVisualization(),
        ),
        
        // Cultural context
        if (widget.showCulturalContext && _patternData != null && _patternData!.containsKey('culturalContext'))
          _buildCulturalContext(),
      ],
    );
  }
  
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Visualization mode selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(VisualizationMode.standard, 'Standard', Icons.grid_on),
                _buildModeButton(VisualizationMode.colorCoded, 'Colors', Icons.palette),
                _buildModeButton(VisualizationMode.blockHighlight, 'Blocks', Icons.view_module),
                _buildModeButton(VisualizationMode.conceptHighlight, 'Concepts', Icons.lightbulb_outline),
                _buildModeButton(VisualizationMode.culturalContext, 'Cultural', Icons.public),
                _buildModeButton(VisualizationMode.threeDimensional, '3D', Icons.view_in_ar),
              ],
            ),
          ),
          
          // Zoom controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0);
                  });
                },
              ),
              Slider(
                value: _zoomLevel,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                label: _zoomLevel.toStringAsFixed(1) + 'x',
                onChanged: (value) {
                  setState(() {
                    _zoomLevel = value;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton(VisualizationMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
        onPressed: () => _changeVisualizationMode(mode),
      ),
    );
  }
  
  Widget _buildPatternVisualization() {
    if (_patternData == null) return const SizedBox.shrink();
    
    // Apply zoom level
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      transformationController: TransformationController(
        Matrix4.identity()..scale(_zoomLevel, _zoomLevel, _zoomLevel)
      ),
      child: FadeTransition(
        opacity: _animation,
        child: _buildVisualizationByMode(),
      ),
    );
  }
  
  Widget _buildVisualizationByMode() {
    switch (_currentMode) {
      case VisualizationMode.colorCoded:
        return _buildColorCodedVisualization();
      case VisualizationMode.blockHighlight:
        return _buildBlockHighlightVisualization();
      case VisualizationMode.conceptHighlight:
        return _buildConceptHighlightVisualization();
      case VisualizationMode.culturalContext:
        return _buildCulturalVisualization();
      case VisualizationMode.threeDimensional:
        return _build3DVisualization();
      case VisualizationMode.standard:
      default:
        return _buildStandardVisualization();
    }
  }
  
  Widget _buildStandardVisualization() {
    // In a real implementation, this would render the pattern using the data
    // For now, we'll just show a placeholder
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Pattern: ${widget.patternId}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorCodedVisualization() {
    if (!_patternData!.containsKey('colorMapping')) {
      return _buildStandardVisualization();
    }
    
    final colorMapping = _patternData!['colorMapping'] as Map<String, dynamic>;
    final colorGroups = colorMapping['groups'] as Map<String, dynamic>;
    final colorMeanings = colorMapping['meanings'] as Map<String, dynamic>;
    
    return Column(
      children: [
        _buildStandardVisualization(),
        const SizedBox(height: 16),
        Text(
          'Color Meanings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorMeanings.entries.map((entry) {
            final colorName = entry.key;
            final meaning = entry.value;
            
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: _colorFromName(colorName),
              ),
              label: Text('$colorName: $meaning'),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildBlockHighlightVisualization() {
    if (!_patternData!.containsKey('blockHighlights')) {
      return _buildStandardVisualization();
    }
    
    return _buildStandardVisualization();
  }
  
  Widget _buildConceptHighlightVisualization() {
    if (!_patternData!.containsKey('conceptHighlights')) {
      return _buildStandardVisualization();
    }
    
    final conceptHighlights = _patternData!['conceptHighlights'] as Map<String, dynamic>;
    final conceptDescriptions = conceptHighlights['conceptDescriptions'] as Map<String, dynamic>;
    
    return Column(
      children: [
        _buildStandardVisualization(),
        const SizedBox(height: 16),
        Text(
          'Coding Concepts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...conceptDescriptions.entries.map((entry) {
          final conceptName = entry.key;
          final description = entry.value;
          
          return ListTile(
            leading: Icon(_getConceptIcon(conceptName)),
            title: Text(conceptName.toUpperCase()),
            subtitle: Text(description),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildCulturalVisualization() {
    if (!_patternData!.containsKey('culturalElements')) {
      return _buildStandardVisualization();
    }
    
    final culturalElements = _patternData!['culturalElements'] as Map<String, dynamic>;
    final symbols = culturalElements['symbols'] as Map<String, dynamic>;
    
    return Column(
      children: [
        _buildStandardVisualization(),
        const SizedBox(height: 16),
        Text(
          'Cultural Elements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...symbols.entries.map((entry) {
          final symbolType = entry.key;
          final symbolList = entry.value as List<dynamic>;
          
          return ExpansionTile(
            title: Text(symbolType.toUpperCase()),
            children: symbolList.map((symbol) {
              final name = symbol['name'];
              final meaning = symbol['meaning'];
              
              return ListTile(
                title: Text(name),
                subtitle: Text(meaning),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _build3DVisualization() {
    if (!_patternData!.containsKey('threeDModel')) {
      return _buildStandardVisualization();
    }
    
    // In a real implementation, this would render a 3D model
    // For now, we'll just show a placeholder
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '3D Visualization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCulturalContext() {
    final culturalContext = _patternData!['culturalContext'] as Map<String, dynamic>;
    final patternContext = culturalContext['patternContext'];
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cultural Context',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(patternContext),
          ],
        ),
      ),
    );
  }
  
  Color _colorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getConceptIcon(String conceptName) {
    switch (conceptName.toLowerCase()) {
      case 'sequence':
        return Icons.arrow_forward;
      case 'loop':
        return Icons.loop;
      case 'condition':
        return Icons.call_split;
      case 'function':
        return Icons.functions;
      case 'variable':
        return Icons.data_usage;
      default:
        return Icons.code;
    }
  }
} 