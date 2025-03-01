import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import 'connected_block.dart';

class BlocksWorkspace extends StatefulWidget {
  final BlockCollection blockCollection;
  final PatternDifficulty difficulty;
  final Function(Block) onBlockSelected;
  final VoidCallback onWorkspaceChanged;
  final Function(String)? onDelete;
  final Function(String, String)? onValueChanged;
  final Function(String, String, String, String)? onBlocksConnected;

  const BlocksWorkspace({
    super.key,
    required this.blockCollection,
    required this.difficulty,
    required this.onBlockSelected,
    required this.onWorkspaceChanged,
    this.onDelete,
    this.onValueChanged,
    this.onBlocksConnected,
  });

  @override
  State<BlocksWorkspace> createState() => _BlocksWorkspaceState();
}

class _BlocksWorkspaceState extends State<BlocksWorkspace> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern Building Area
          Expanded(
            child: widget.blockCollection.blocks.isEmpty
                ? _buildEmptyState()
                : _buildBlocksList(),
          ),

          // Pattern Guidance
          if (widget.blockCollection.blocks.isNotEmpty)
            _buildPatternGuidance(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drag_indicator,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Drag blocks here to start weaving!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Traditional Kente patterns start with color blocks',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksList() {
    return ListView.builder(
      itemCount: widget.blockCollection.blocks.length,
      itemBuilder: (context, index) {
        final block = widget.blockCollection.blocks[index];
        return ConnectedBlock(
          block: block,
          onDelete: widget.onDelete != null 
              ? () => widget.onDelete!(block.id) 
              : null,
          onValueChanged: (value) => widget.onValueChanged != null
              ? widget.onValueChanged!(block.id, value)
              : {},
          onConnectionDragStart: _handleConnectionDragStart,
          onConnectionDragUpdate: _handleConnectionDragUpdate,
          onConnectionDragEnd: _handleConnectionDragEnd,
          onConnectionDragCancel: _handleConnectionDragCancel,
          difficulty: widget.difficulty,
        );
      },
      padding: const EdgeInsets.only(bottom: 100), // Space for floating suggestions
    );
  }

  void _handleConnectionDragStart(String blockId, String connectionId) {
    // Implement connection drag start
  }

  void _handleConnectionDragUpdate(Offset position) {
    // Implement connection drag update
  }

  void _handleConnectionDragEnd(String targetBlockId, String targetConnectionId) {
    // Implement connection drag end
  }

  void _handleConnectionDragCancel() {
    // Implement connection drag cancel
  }

  Widget _buildPatternGuidance(BuildContext context) {
    // Analyze current pattern
    final hasColorBlock = widget.blockCollection.blocks.any(
        (b) => b.type == BlockType.color);
    final hasPatternBlock = widget.blockCollection.blocks.any(
        (b) => b.type == BlockType.pattern);
    final hasLoopBlock = widget.blockCollection.blocks.any(
        (b) => b.type == BlockType.loop);

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Building Guide:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          _buildGuidanceStep(
            '1. Color Selection',
            hasColorBlock,
            'Choose your thread colors',
          ),
          _buildGuidanceStep(
            '2. Pattern Type',
            hasPatternBlock,
            'Select a traditional pattern',
          ),
          _buildGuidanceStep(
            '3. Loop Structure',
            hasLoopBlock,
            'Add repeating elements',
          ),

          // Cultural Context Hint
          if (hasColorBlock && hasPatternBlock)
            _buildCulturalHint(context),
        ],
      ),
    );
  }

  Widget _buildGuidanceStep(String title, bool completed, String description) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: completed ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title: $description',
            style: TextStyle(
              color: completed ? Colors.black87 : Colors.grey[600],
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalHint(BuildContext context) {
    // Extract pattern type block
    final patternBlock = widget.blockCollection.blocks.firstWhere(
      (b) => b.type == BlockType.pattern,
      orElse: () => Block(
        id: '',
        name: '',
        type: BlockType.pattern,
        subtype: '',
        description: '',
        properties: {},
        connections: [],
        iconPath: '',
        color: Colors.grey,
      ),
    );

    // Extract color blocks
    final colorBlocks = widget.blockCollection.blocks.where(
      (b) => b.type == BlockType.color,
    ).toList();

    // Get pattern-specific guidance
    String guidance = _getPatternGuidance(
      patternBlock.subtype,
      colorBlocks.length,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              guidance,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPatternGuidance(String patternType, int colorCount) {
    // Pattern-specific cultural guidance
    switch (patternType) {
      case 'checker_pattern':
        return 'Dame-Dame pattern traditionally uses $colorCount colors to represent strategy and wisdom.';
      case 'zigzag_pattern':
        return 'Nkyinkyim pattern shows life\'s journey. Consider adding another color for depth.';
      case 'diamond_pattern':
        return 'Obaakofo Mmu Man pattern represents collective wisdom. Try using gold for royalty.';
      case 'stripes_vertical_pattern':
        return 'Kubi pattern symbolizes structure. Traditional colors enhance its meaning.';
      case 'stripes_horizontal_pattern':
        return 'Babadua pattern shows strength through unity. Each color adds meaning.';
      case 'square_pattern':
        return 'Eban (fence) pattern represents protection. Consider traditional color combinations.';
      default:
        return 'Traditional Kente patterns tell stories through their colors and shapes.';
    }
  }
}
