import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';

class ConnectedBlock extends StatefulWidget {
  final Block block;
  final VoidCallback? onDelete;
  final Function(String) onValueChanged;
  final Function(String, String) onConnectionDragStart;
  final Function(Offset) onConnectionDragUpdate;
  final Function(String, String) onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;
  final PatternDifficulty difficulty;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool highlightConnections;

  const ConnectedBlock({
    Key? key,
    required this.block,
    this.onDelete,
    required this.onValueChanged,
    required this.onConnectionDragStart,
    required this.onConnectionDragUpdate,
    required this.onConnectionDragEnd,
    required this.onConnectionDragCancel,
    this.difficulty = PatternDifficulty.basic,
    this.isSelected = false,
    this.onTap,
    this.highlightConnections = false,
  }) : super(key: key);

  @override
  State<ConnectedBlock> createState() => _ConnectedBlockState();
}

class _ConnectedBlockState extends State<ConnectedBlock> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  String? _hoveredConnectionId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ConnectedBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(BuildContext context) {
    switch (widget.difficulty) {
      case PatternDifficulty.basic:
        return AppTheme.kenteGold;
      case PatternDifficulty.intermediate:
        return AppTheme.kenteRed;
      case PatternDifficulty.advanced:
        return AppTheme.kenteGreen;
      case PatternDifficulty.master:
        return AppTheme.kenteBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SizedBox(
            width: 220,
            child: Card(
              key: ValueKey(widget.block.id),
              elevation: widget.isSelected ? 8 : (_isHovering ? 4 : 2),
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.isSelected
                      ? difficultyColor
                      : _isHovering
                      ? difficultyColor.withOpacity(0.5)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBlockHeader(context, difficultyColor),
                  _buildBlockContent(context),
                  if (widget.block.connections.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 220, // Match the width used for positioning
                        height: 80, // Adjusted height for connections
                        child: Stack(
                          children: widget.block.connections.map((connection) {
                            return Positioned(
                              left: connection.position.dx * 220, // Width of block
                              top: connection.position.dy * 80, // Adjusted height
                              child: _buildConnectionPoint(connection),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockHeader(BuildContext context, Color difficultyColor) {
    return Container(
      decoration: BoxDecoration(
        color: difficultyColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: ListTile(
        leading: _buildBlockIcon(),
        title: Text(
          widget.block.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: widget.onDelete != null
            ? IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: widget.onDelete,
          tooltip: 'Delete block',
        )
            : null,
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.difficulty != PatternDifficulty.basic &&
              widget.block.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.block.description,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          _buildBlockSubtitle(),
        ],
      ),
    );
  }

  Widget _buildBlockIcon() {
    if (widget.block.type == BlockType.color) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: widget.block.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        _getBlockIcon(),
        color: widget.block.color,
        size: 16,
      ),
    );
  }

  Widget _buildBlockSubtitle() {
    // Make loop blocks editable
    if (widget.block.type == BlockType.loop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repeat:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: InputBorder.none,
                      hintText: '3',
                    ),
                    controller: TextEditingController(
                      text: widget.block.properties['value']?.toString() ?? '3',
                    ),
                    onChanged: widget.onValueChanged,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('times', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ],
      );
    }

    // Make row and column blocks editable
    if (widget.block.type == BlockType.row || widget.block.type == BlockType.column) {
      final label = widget.block.type == BlockType.row ? 'Width:' : 'Height:';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: InputBorder.none,
                      hintText: '2',
                    ),
                    controller: TextEditingController(
                      text: widget.block.properties['value']?.toString() ?? '2',
                    ),
                    onChanged: widget.onValueChanged,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('cells', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ],
      );
    }

    if (widget.difficulty != PatternDifficulty.basic &&
        widget.block.type == BlockType.pattern) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          _getPatternDescription(),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConnectionPoint(BlockConnection connection) {
    final isConnected = connection.connectedToId != null;
    final isHovered = _hoveredConnectionId == connection.id;
    final difficultyColor = _getDifficultyColor(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredConnectionId = connection.id),
      onExit: (_) => setState(() => _hoveredConnectionId = null),
      child: GestureDetector(
        onPanStart: (_) => widget.onConnectionDragStart(widget.block.id, connection.id),
        onPanUpdate: (details) => widget.onConnectionDragUpdate(details.globalPosition),
        onPanEnd: (_) => widget.onConnectionDragCancel(),
        onPanCancel: widget.onConnectionDragCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isHovered ? 16 : 14,
          height: isHovered ? 16 : 14,
          decoration: BoxDecoration(
            color: isConnected
                ? difficultyColor
                : (isHovered ? Colors.grey.shade600 : Colors.grey.shade400),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: isHovered || isConnected || widget.highlightConnections
                ? [
              BoxShadow(
                color: (isConnected ? difficultyColor : Colors.grey).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ]
                : null,
          ),
          child: Center(
            child: Icon(
              connection.type == ConnectionType.input
                  ? Icons.arrow_back
                  : connection.type == ConnectionType.output
                  ? Icons.arrow_forward
                  : Icons.swap_horiz,
              size: 8,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _getPatternDescription() {
    if (widget.block.description.isNotEmpty) {
      return widget.block.description;
    }

    switch (widget.block.subtype) {
      case 'checker_pattern':
        return 'Symbolizes intelligence and strategy';
      case 'stripes_vertical_pattern':
        return 'Represents balance and structure';
      case 'stripes_horizontal_pattern':
        return 'Symbolizes strength through unity';
      case 'zigzag_pattern':
        return 'Represents life\'s journey and adaptability';
      case 'square_pattern':
        return 'Symbolizes protection and security';
      case 'diamonds_pattern':
        return 'Represents collective wisdom and democracy';
      default:
        return '';
    }
  }

  IconData _getBlockIcon() {
    switch (widget.block.subtype) {
      case 'loop_block':
        return Icons.repeat;
      case 'checker_pattern':
        return Icons.grid_on;
      case 'stripes_vertical_pattern':
        return Icons.view_week;
      case 'stripes_horizontal_pattern':
        return Icons.view_stream;
      case 'zigzag_pattern':
        return Icons.timeline;
      case 'square_pattern':
        return Icons.crop_square;
      case 'diamonds_pattern':
        return Icons.diamond;
      case 'row_block':
        return Icons.table_rows;
      case 'column_block':
        return Icons.view_column;
      default:
        return Icons.widgets;
    }
  }
}