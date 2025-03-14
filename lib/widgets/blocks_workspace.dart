import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/block_definition_service.dart';
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
  String? _activeDragBlockId;
  String? _activeConnectionId;
  Offset? _currentDragPosition;

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
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return details.data != null;
      },
      onAcceptWithDetails: (details) {
        final blockId = details.data;
        final blockDefinitionService = BlockDefinitionService();
        final block = blockDefinitionService.getBlockById(blockId);
        
        if (block != null) {
          widget.onBlockSelected(block);
          debugPrint('Added block to workspace: $blockId');
        } else {
          debugPrint('Block not found: $blockId');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDraggingOver ? Colors.blue : Colors.transparent,
              width: 2,
            ),
            color: isDraggingOver 
                ? Colors.blue.withValues(alpha: 26)
                : Colors.transparent,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 48,
                  color: isDraggingOver ? Colors.blue : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isDraggingOver 
                      ? 'Release to add block!' 
                      : 'Drag blocks here to start weaving!',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDraggingOver ? Colors.blue : Colors.grey[600],
                    fontWeight: isDraggingOver ? FontWeight.bold : FontWeight.normal,
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
          ),
        );
      },
    );
  }

  Widget _buildBlocksList() {
    return Stack(
      children: [
        ListView.builder(
          itemCount: widget.blockCollection.blocks.length,
          itemBuilder: (context, index) {
            final block = widget.blockCollection.blocks[index];
            return ConnectedBlock(
              block: block,
              onDelete: widget.onDelete != null 
                  ? () => widget.onDelete!(block.id) 
                  : null,
              onValueChanged: (value) {
                if (widget.onValueChanged != null) {
                  widget.onValueChanged!(block.id, value);
                }
              },
              onConnectionDragStart: _handleConnectionDragStart,
              onConnectionDragUpdate: _handleConnectionDragUpdate,
              onConnectionDragEnd: _handleConnectionDragEnd,
              onConnectionDragCancel: _handleConnectionDragCancel,
              difficulty: widget.difficulty,
              showPreview: _activeDragBlockId != null,
            );
          },
          padding: const EdgeInsets.only(bottom: 100),
        ),
        if (_activeDragBlockId != null && _currentDragPosition != null)
          Positioned(
            left: _currentDragPosition!.dx,
            top: _currentDragPosition!.dy,
            child: _buildConnectionPreview(),
          ),
      ],
    );
  }

  Widget _buildConnectionPreview() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 77),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  void _handleConnectionDragStart(String blockId, String connectionId) {
    setState(() {
      _activeDragBlockId = blockId;
      _activeConnectionId = connectionId;
      debugPrint('Started connection drag: $blockId, $connectionId');
    });
  }

  void _handleConnectionDragUpdate(Offset position) {
    setState(() {
      _currentDragPosition = position;
    });
  }

  void _handleConnectionDragEnd(String targetBlockId, String targetConnectionId) {
    if (_activeDragBlockId != null && _activeConnectionId != null) {
      widget.onBlocksConnected?.call(
        _activeDragBlockId!,
        _activeConnectionId!,
        targetBlockId,
        targetConnectionId,
      );
      
      debugPrint('Connected blocks: $_activeDragBlockId:$_activeConnectionId -> $targetBlockId:$targetConnectionId');
      widget.onWorkspaceChanged();
    }
    
    setState(() {
      _activeDragBlockId = null;
      _activeConnectionId = null;
      _currentDragPosition = null;
    });
  }

  void _handleConnectionDragCancel() {
    setState(() {
      _activeDragBlockId = null;
      _activeConnectionId = null;
      _currentDragPosition = null;
      debugPrint('Connection drag cancelled');
    });
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: completed ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              completed ? Icons.check_circle : Icons.circle_outlined,
              key: ValueKey(completed),
              size: 16,
              color: completed ? Colors.green : Colors.grey,
            ),
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
      ),
    );
  }

  Widget _buildCulturalHint(BuildContext context) {
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
        colorHex: '#808080', // Fixed: Added required colorHex parameter
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
