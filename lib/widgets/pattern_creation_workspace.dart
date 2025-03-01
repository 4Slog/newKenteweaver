import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/unified/pattern_engine.dart';
import '../services/pattern_analyzer_service.dart';
import '../widgets/smart_workspace.dart';
import '../widgets/weaving_pattern_renderer.dart';
import '../widgets/blocks_toolbox.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/ai_mentor_widget.dart';
import '../widgets/cultural_context_card.dart';
import '../theme/app_theme.dart';

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
  Block? selectedBlock;
  Map<String, dynamic> analysisResults = {};
  late bool _showAIMentor;
  late bool _showCulturalContext;

  @override
  void initState() {
    super.initState();
    // Create a new BlockCollection with a copy of the blocks
    blockCollection = BlockCollection(
      blocks: List.from(widget.initialBlocks.blocks),
    );
    patternEngine = PatternEngine();
    patternAnalyzer = PatternAnalyzerService();
    _showAIMentor = widget.showAIMentor;
    _showCulturalContext = widget.showCulturalContext;
    
    _analyzePattern();
  }
  
  Future<void> _analyzePattern() async {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: BreadcrumbNavigation(
            items: [
              BreadcrumbItem(
                label: 'Home',
                route: '/',
                fallbackIcon: Icons.home,
              ),
              ...widget.breadcrumbs,
              BreadcrumbItem(
                label: widget.title,
                fallbackIcon: Icons.create,
              ),
            ],
          ),
        ),
        
        // Main content
        Expanded(
          child: Stack(
            children: [
              // Main layout - now a Row with just toolbox and workspace
              Row(
                children: [
                  // Toolbox Panel (slightly thicker)
                  if (!widget.readOnly)
                    BlocksToolbox(
                      onBlockSelected: _handleAddBlock,
                      difficulty: widget.difficulty,
                      width: 300, // Increased from 250
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
                  onPressed: _validateAndShowPattern,
                  tooltip: 'Generate Pattern',
                  backgroundColor: AppTheme.kenteGold,
                  child: const Icon(Icons.play_arrow, color: Colors.black),
                ),
              ),
              
              // AI Mentor Widget (if enabled)
              if (_showAIMentor)
                Positioned(
                  right: 16,
                  top: 16,
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
              'Complexity: ${analysis['complexity']}',
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
    // Check if there are any blocks
    if (blockCollection.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some blocks to generate a pattern'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if there's at least one pattern or color block
    final hasPatternOrColor = blockCollection.blocks.any((block) => 
      block.type == BlockType.pattern || block.type == BlockType.color);
    
    if (!hasPatternOrColor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one pattern or color block'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Generate the pattern using the pattern engine
    try {
      // This is where we would actually generate the pattern
      // For now, we'll just show the preview dialog
      
      // Show the pattern preview dialog
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
                  child: WeavingPatternRenderer(
                    blockCollection: blockCollection,
                    showGrid: true,
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
    } catch (e) {
      // Show error message if pattern generation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating pattern: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
}
