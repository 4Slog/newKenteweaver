import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/unified/pattern_engine.dart';
import '../services/pattern_analyzer_service.dart';
import '../services/block_definition_service.dart';
import '../widgets/smart_workspace.dart';
import '../widgets/blocks_toolbox.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/ai_mentor_widget.dart';
import '../widgets/cultural_context_card.dart';
import '../theme/app_theme.dart';

/// A comprehensive workspace for pattern creation that combines toolbox, workspace,
/// and pattern preview functionality.
class PatternCreationWorkspace extends StatefulWidget {
  final BlockCollection initialBlocks;
  final PatternDifficulty difficulty;
  final bool readOnly;
  final bool showAnalysis;
  final List<BreadcrumbItem> breadcrumbs;
  final String title;
  final bool showAIMentor;
  final bool showCulturalContext;
  final Function(BlockCollection)? onPatternChanged;

  const PatternCreationWorkspace({
    Key? key,
    required this.initialBlocks,
    this.difficulty = PatternDifficulty.basic,
    this.readOnly = false,
    this.showAnalysis = true,
    this.breadcrumbs = const [],
    this.title = 'Pattern Creation',
    this.showAIMentor = true,
    this.showCulturalContext = true,
    this.onPatternChanged,
  }) : super(key: key);

  @override
  State<PatternCreationWorkspace> createState() => _PatternCreationWorkspaceState();
}

class _PatternCreationWorkspaceState extends State<PatternCreationWorkspace> {
  late BlockCollection blockCollection;
  late PatternEngine patternEngine;
  late PatternAnalyzerService patternAnalyzer;
  late BlockDefinitionService blockDefinitionService;

  Block? selectedBlock;
  Map<String, dynamic> analysisResults = {};
  late bool _showAIMentor;
  late bool _showCulturalContext;
  bool _isGeneratingPattern = false;

  @override
  void initState() {
    super.initState();
    // Create a new BlockCollection with a copy of the blocks
    blockCollection = BlockCollection(
      blocks: List.from(widget.initialBlocks.blocks),
    );
    patternEngine = PatternEngine();
    patternAnalyzer = PatternAnalyzerService();
    blockDefinitionService = BlockDefinitionService();
    _showAIMentor = widget.showAIMentor;
    _showCulturalContext = widget.showCulturalContext;

    _initServices();
  }

  /// Initialize services and analyze initial pattern
  Future<void> _initServices() async {
    try {
      await blockDefinitionService.loadDefinitions();
      await patternEngine.initialize();

      _analyzePattern();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  /// Analyze the current pattern and update analysis results
  Future<void> _analyzePattern() async {
    if (blockCollection.blocks.isEmpty) {
      setState(() {
        analysisResults = {
          'hint': 'Start by adding blocks to create a pattern.',
          'feedback': 'Add pattern and color blocks to begin.',
          'complexity_analysis': {
            'complexity': 0.0,
            'block_count': 0,
          }
        };
      });
      return;
    }

    try {
      final results = await patternAnalyzer.analyzePattern(
        blocks: blockCollection.toLegacyBlocks(),
        difficulty: widget.difficulty,
      );

      setState(() {
        analysisResults = results;
      });

      if (widget.onPatternChanged != null) {
        widget.onPatternChanged!(blockCollection);
      }
    } catch (e) {
      debugPrint('Error analyzing pattern: $e');
      setState(() {
        analysisResults = {
          'hint': 'Error analyzing pattern. Try a simpler pattern.',
          'feedback': 'There was an error analyzing your pattern.',
          'complexity_analysis': {
            'complexity': 0.0,
            'block_count': blockCollection.blocks.length,
          }
        };
      });
    }
  }

  void _handleBlockSelected(Block block) {
    setState(() {
      selectedBlock = block;
    });
  }

  void _handleWorkspaceChanged() {
    _analyzePattern();
  }

  void _handleDelete(String blockId) {
    setState(() {
      blockCollection.removeBlock(blockId);
      if (selectedBlock?.id == blockId) {
        selectedBlock = null;
      }
    });

    _handleWorkspaceChanged();
  }

  void _handleValueChanged(String blockId, String value) {
    final block = blockCollection.getBlockById(blockId);
    if (block != null) {
      final updatedBlock = block.copyWith(
        properties: {...block.properties, 'value': value},
      );

      setState(() {
        final index = blockCollection.blocks.indexWhere((b) => b.id == blockId);
        if (index != -1) {
          blockCollection.blocks[index] = updatedBlock;
        }
      });

      _handleWorkspaceChanged();
    }
  }

  void _handleAddBlock(Block block) {
    // Create a unique ID for the new block
    final uniqueId = '${block.id}_${DateTime.now().millisecondsSinceEpoch}';
    final newBlock = block.copyWith(id: uniqueId);

    setState(() {
      blockCollection.addBlock(newBlock);
    });

    _handleWorkspaceChanged();
  }

  void _handleBlocksConnected(
      String sourceBlockId,
      String sourceConnectionId,
      String targetBlockId,
      String targetConnectionId,
      ) {
    final result = blockCollection.connectBlocks(
      sourceBlockId,
      sourceConnectionId,
      targetBlockId,
      targetConnectionId,
    );

    if (result) {
      _handleWorkspaceChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb navigation at the top
        if (widget.breadcrumbs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: BreadcrumbNavigation(
              items: widget.breadcrumbs,
            ),
          ),

        // Main content
        Expanded(
          child: Stack(
            children: [
              // Main layout - Row with toolbox and workspace
              Row(
                children: [
                  // Toolbox Panel
                  if (!widget.readOnly)
                    BlocksToolbox(
                      onBlockSelected: _handleAddBlock,
                      difficulty: widget.difficulty,
                      width: 300,
                    ),

                  // Workspace Panel (takes up all remaining space)
                  Expanded(
                    child: SmartWorkspace(
                      blockCollection: blockCollection,
                      difficulty: widget.difficulty,
                      onBlockSelected: _handleBlockSelected,
                      onWorkspaceChanged: _handleWorkspaceChanged,
                      onDelete: widget.readOnly ? null : _handleDelete,
                      onValueChanged: _handleValueChanged,
                      onBlocksConnected: _handleBlocksConnected,
                      showConnections: true,
                      showGrid: true,
                      enableBlockMovement: !widget.readOnly,
                    ),
                  ),
                ],
              ),

              // Generate Pattern Button
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: _isGeneratingPattern ? null : _validateAndShowPattern,
                  tooltip: 'Generate Pattern',
                  backgroundColor: _isGeneratingPattern ? Colors.grey : AppTheme.kenteGold,
                  child: _isGeneratingPattern
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.play_arrow, color: Colors.black),
                ),
              ),

              // AI Mentor Widget (if enabled)
              if (_showAIMentor)
                Positioned(
                  right: 16,
                  top: 16,
                  width: 300,
                  child: AIMentorWidget(
                    blocks: blockCollection.toLegacyBlocks(),
                    difficulty: widget.difficulty,
                    isVisible: true,
                    onClose: () => setState(() => _showAIMentor = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pattern Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: analysisResults.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAnalysisResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return ListView(
      children: [
        if (analysisResults.containsKey('hint'))
          _buildHintCard(analysisResults['hint']),

        if (analysisResults.containsKey('complexity_analysis'))
          _buildComplexityAnalysisCard(analysisResults['complexity_analysis']),

        if (analysisResults.containsKey('feedback'))
          _buildFeedbackCard(analysisResults['feedback']),
      ],
    );
  }

  Widget _buildHintCard(String hint) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexityAnalysisCard(Map<String, dynamic> analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complexity: ${analysis['complexity'] is double ? (analysis['complexity'] * 100).toStringAsFixed(0) : 0}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Block count: ${analysis['block_count']}',
              style: const TextStyle(color: Colors.black),
            ),
            if (analysis.containsKey('color_count'))
              Text(
                'Color count: ${analysis['color_count']}',
                style: const TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                feedback,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndShowPattern() {
    // Set generating state
    setState(() {
      _isGeneratingPattern = true;
    });

    // Check if there are any blocks
    if (blockCollection.blocks.isEmpty) {
      _showErrorDialog(
        'No Blocks Added',
        'Please add some blocks to generate a pattern.',
        ['Try adding pattern blocks and color blocks to create a design.'],
      );
      setState(() {
        _isGeneratingPattern = false;
      });
      return;
    }

    // Check if there's at least one pattern or color block
    final hasPatternOrColor = blockCollection.blocks.any((block) =>
    block.type == BlockType.pattern || block.type == BlockType.color);

    if (!hasPatternOrColor) {
      _showErrorDialog(
        'Missing Pattern Elements',
        'Add at least one pattern or color block to create a design.',
        ['Pattern blocks define the layout of your design.',
          'Color blocks determine the colors used in your pattern.'],
      );
      setState(() {
        _isGeneratingPattern = false;
      });
      return;
    }

    // Generate the pattern using the pattern engine
    _generateAndShowPattern();
  }

  Future<void> _generateAndShowPattern() async {
    try {
      // Generate pattern using pattern engine
      final generatedPattern = patternEngine.generatePatternFromBlocks(blockCollection);

      // Show the pattern preview dialog
      await _showPatternPreviewDialog(generatedPattern);

      setState(() {
        _isGeneratingPattern = false;
      });
    } catch (e) {
      // Show error message if pattern generation fails
      _showErrorDialog(
        'Error Generating Pattern',
        'Unable to generate pattern from current blocks.',
        ['Try simplifying your pattern or using fewer blocks.',
          'Make sure your blocks are properly connected.'],
      );

      setState(() {
        _isGeneratingPattern = false;
      });
      debugPrint('Error generating pattern: $e');
    }
  }

  Future<void> _showPatternPreviewDialog(List<List<Color>> generatedPattern) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pattern Preview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),

              // Pattern Renderer
              Expanded(
                flex: 3,
                child: Center(
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20.0),
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: CustomPaint(
                      painter: _PatternPreviewPainter(
                        pattern: generatedPattern,
                        cellSize: 20.0,
                      ),
                      size: Size(
                        generatedPattern[0].length * 20.0,
                        generatedPattern.length * 20.0,
                      ),
                    ),
                  ),
                ),
              ),

              // Cultural Context Card (if enabled)
              if (_showCulturalContext)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: KenteCulturalCards.patternMeanings(
                    onLearnMore: () => _showDetailedCulturalInfo(context),
                  ),
                ),

              // Analysis panel (if enabled)
              if (widget.showAnalysis)
                Expanded(
                  flex: 1,
                  child: _buildAnalysisPanel(),
                ),

              // Action buttons
              ButtonBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Save or export pattern functionality
                      _savePattern();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kenteGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Save Pattern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedCulturalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kente Cultural Significance',
          style: TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KenteCulturalCards.colorMeanings(),
              const SizedBox(height: 16),
              KenteCulturalCards.historicalContext(),
              const SizedBox(height: 16),
              KenteCulturalCards.modernSignificance(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message, List<String> suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(suggestion)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _savePattern() {
    // Here we would save the pattern to the database or local storage
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pattern saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Notify parent that pattern has changed
    if (widget.onPatternChanged != null) {
      widget.onPatternChanged!(blockCollection);
    }
  }
}

/// A painter for rendering the Kente pattern preview
class _PatternPreviewPainter extends CustomPainter {
  final List<List<Color>> pattern;
  final double cellSize;

  _PatternPreviewPainter({
    required this.pattern,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.grey.withOpacity(0.5);

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        // Draw cell
        paint.color = pattern[row][col];
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPreviewPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.cellSize != cellSize;
  }
}