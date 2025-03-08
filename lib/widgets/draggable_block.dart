import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../theme/app_theme.dart';

class DraggableBlock extends StatelessWidget {
  final Block block;
  final VoidCallback onDragStarted;
  final VoidCallback? onDragEndSimple;
  final VoidCallback onTap;
  final double scale;
  final bool showLabel;
  final bool isCollapsed;

  const DraggableBlock({
    super.key,
    required this.block,
    required this.onDragStarted,
    this.onDragEndSimple,
    required this.onTap,
    this.scale = 1.0,
    this.showLabel = true,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Block>(
      data: block,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEndSimple?.call(),
      feedback: _buildBlockPreview(context, isDragging: true),
      childWhenDragging: _buildBlockPreview(context, isGhost: true),
      child: GestureDetector(
        onTap: onTap,
        child: _buildBlockPreview(context),
      ),
    );
  }

  Widget _buildBlockPreview(BuildContext context, {
    bool isDragging = false,
    bool isGhost = false,
  }) {
    final blockContent = Container(
      width: isCollapsed ? 48 : 120 * scale,
      height: isCollapsed ? 48 : 120 * scale,
      decoration: BoxDecoration(
        color: isGhost
            ? Colors.grey.withOpacity(0.3)
            : block.color,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getBlockIcon(),
            size: isCollapsed ? 24 : 32 * scale,
            color: Colors.white,
          ),
          if (showLabel && !isCollapsed) ...[
            const SizedBox(height: 8),
            Text(
              block.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );

    if (isDragging) {
      return Transform.scale(
        scale: 1.1,
        child: blockContent,
      );
    }

    return blockContent;
  }

  IconData _getBlockIcon() {
    switch (block.type) {
      case BlockType.pattern:
        return Icons.grid_on;
      case BlockType.color:
        return Icons.palette;
      case BlockType.structure:
        return Icons.architecture;
      case BlockType.loop:
        return Icons.loop;
      case BlockType.row:
        return Icons.view_stream;
      case BlockType.column:
        return Icons.view_column;
      default:
        return Icons.widgets;
    }
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}