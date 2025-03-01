import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';

class ConnectedBlock extends StatelessWidget {
  final Block block;
  final VoidCallback? onDelete;
  final Function(String) onValueChanged;
  final Function(String, String) onConnectionDragStart;
  final Function(Offset) onConnectionDragUpdate;
  final Function(String, String) onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;
  final PatternDifficulty difficulty;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        key: ValueKey(block.id),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _buildBlockIcon(),
              title: Text(
                block.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: _buildBlockSubtitle(),
              trailing: onDelete != null
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    )
                  : null,
            ),
            if (block.connections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 200, // Match the width used for positioning
                  height: 80, // Match the height used for positioning
                  child: Stack(
                    children: block.connections.map((connection) {
                      return Positioned(
                        left: connection.position.dx * 200, // Width of block
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
    );
  }

  Widget _buildBlockIcon() {
    if (block.type == BlockType.color) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: block.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      );
    }

    return Icon(
      _getBlockIcon(),
      color: block.color,
    );
  }

  Widget _buildBlockSubtitle() {
    // Make loop blocks editable
    if (block.type == BlockType.loop) {
      return Row(
        children: [
          const Text('Repeat: '),
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              controller: TextEditingController(
                text: block.properties['value']?.toString() ?? '3',
              ),
              onChanged: onValueChanged,
            ),
          ),
          const Text(' times'),
        ],
      );
    }
    
    // Make row and column blocks editable
    if (block.type == BlockType.row || block.type == BlockType.column) {
      return Row(
        children: [
          Text('Size: '),
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              controller: TextEditingController(
                text: block.properties['value']?.toString() ?? '2',
              ),
              onChanged: onValueChanged,
            ),
          ),
          Text(' cells'),
        ],
      );
    }

    if (difficulty != PatternDifficulty.basic &&
        block.type == BlockType.pattern) {
      return Text(
        block.description.isNotEmpty 
            ? block.description
            : _getPatternDescription(),
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConnectionPoint(BlockConnection connection) {
    final isConnected = connection.connectedToId != null;
    
    return GestureDetector(
      onPanStart: (_) => onConnectionDragStart(block.id, connection.id),
      onPanUpdate: (details) => onConnectionDragUpdate(details.globalPosition),
      onPanEnd: (_) => onConnectionDragCancel(),
      onPanCancel: onConnectionDragCancel,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isConnected ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
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
    );
  }

  String _getPatternDescription() {
    switch (block.subtype) {
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
    switch (block.subtype) {
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
