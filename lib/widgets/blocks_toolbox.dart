import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';
import 'draggable_block.dart';

class BlocksToolbox extends StatelessWidget {
  final Function(Block) onBlockSelected;
  final PatternDifficulty difficulty;
  final ValueNotifier<String>? selectedCategoryNotifier;
  final double width;

  const BlocksToolbox({
    super.key,
    required this.onBlockSelected,
    required this.difficulty,
    this.selectedCategoryNotifier,
    this.width = 300, // Default to 300 (increased from 250)
  });

  @override
  Widget build(BuildContext context) {
    // Create a local notifier if none was provided
    final localNotifier = selectedCategoryNotifier ??
        ValueNotifier<String>('Pattern Blocks');

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolboxHeader(context),
          _buildCategoryTabs(context, localNotifier),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: localNotifier,
              builder: (context, selectedCategory, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: _buildCategoryBlocks(context, selectedCategory),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolboxHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.kenteGold,
      child: Row(
        children: [
          const Icon(Icons.category, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            'Blocks Toolbox',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
      BuildContext context, ValueNotifier<String> selectedCategory) {
    final categories = [
      'Pattern Blocks',
      'Color Blocks',
      'Structure Blocks',
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => selectedCategory.value = category,
            child: ValueListenableBuilder<String>(
              valueListenable: selectedCategory,
              builder: (context, selected, child) {
                final isSelected = selected == category;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    color: isSelected ? Colors.white : Colors.grey[200],
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryBlocks(BuildContext context, String category) {
    switch (category) {
      case 'Pattern Blocks':
        return _buildPatternBlocks(context);
      case 'Color Blocks':
        return _buildColorBlocks(context);
      case 'Structure Blocks':
        return _buildStructureBlocks(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPatternBlocks(BuildContext context) {
    final patterns = [
      _createPatternBlock(
        'checker_pattern',
        'Dame-Dame Pattern',
        'Symbolizes intelligence and strategy',
        'checker_pattern',
        'assets/images/blocks/checker_pattern.png',
        Colors.indigo,
      ),
      _createPatternBlock(
        'zigzag_pattern',
        'Nkyinkyim Pattern',
        'Represents life\'s journey and adaptability',
        'zigzag_pattern',
        'assets/images/blocks/zigzag_pattern.png',
        Colors.purple,
      ),
      _createPatternBlock(
        'stripes_vertical_pattern',
        'Kubi Pattern',
        'Represents balance and structure',
        'stripes_vertical_pattern',
        'assets/images/blocks/stripes_vertical_pattern.png',
        Colors.teal,
      ),
      _createPatternBlock(
        'stripes_horizontal_pattern',
        'Babadua Pattern',
        'Symbolizes strength through unity',
        'stripes_horizontal_pattern',
        'assets/images/blocks/stripes_horizontal_pattern.png',
        Colors.lightBlue,
      ),
      _createPatternBlock(
        'square_pattern',
        'Eban Pattern',
        'Symbolizes protection and security',
        'square_pattern',
        'assets/images/blocks/square_pattern.png',
        Colors.orange,
      ),
      _createPatternBlock(
        'diamonds_pattern',
        'Obaakofo Pattern',
        'Represents collective wisdom and democracy',
        'diamonds_pattern',
        'assets/images/blocks/diamonds_pattern.png',
        Colors.pink,
      ),
    ];

    return Column(
      children: patterns.map((pattern) {
        return _buildToolboxBlock(
          context,
          pattern,
        );
      }).toList(),
    );
  }

  Block _createPatternBlock(
      String id,
      String name,
      String description,
      String subtype,
      String iconPath,
      Color color,
      ) {
    return Block(
      id: id,
      name: name,
      description: description,
      type: BlockType.pattern,
      subtype: subtype,
      properties: {
        'pattern': subtype,
        'colors': ['#000000', '#FF0000', '#FFD700'],
      },
      connections: [
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
      ],
      iconPath: iconPath,
      color: color,
    );
  }

  Widget _buildColorBlocks(BuildContext context) {
    final colors = [
    _createColorBlock(
      'shuttle_black',
      'Black Thread',
      'shuttle_black',
      Colors.black,
      'assets/images/blocks/shuttle_black.png',
    ),
    _createColorBlock(
    'shuttle_blue',
    'Blue Thread',
    'shuttle_blue',
    Colors.blue,
    'assets/images/blocks/shuttle_blue.png',
    ),
    _createColorBlock(
    'shuttle_gold',
    'Gold Thread',
    'shuttle_gold',
    AppTheme.kenteGold,
    'assets/images/blocks/shuttle_gold.png',
    ),
    _createColorBlock(
      'shuttle_green',
      'Green Thread',
      'shuttle_green',
      Colors.green,
      'assets/images/blocks/shuttle_green.png',
    ),
      _createColorBlock(
        'shuttle_orange',
        'Orange Thread',
        'shuttle_orange',
        Colors.orange,
        'assets/images/blocks/shuttle_orange.png',
      ),
      _createColorBlock(
        'shuttle_purple',
        'Purple Thread',
        'shuttle_purple',
        Colors.purple,
        'assets/images/blocks/shuttle_purple.png',
      ),
      _createColorBlock(
        'shuttle_red',
        'Red Thread',
        'shuttle_red',
        Colors.red,
        'assets/images/blocks/shuttle_red.png',
      ),
      _createColorBlock(
        'shuttle_white',
        'White Thread',
        'shuttle_white',
        Colors.white,
        'assets/images/blocks/shuttle_white.png',
      ),
    ];

    return Column(
      children: colors.map((color) {
        return _buildToolboxBlock(
          context,
          color,
        );
      }).toList(),
    );
  }

  Block _createColorBlock(String id,
      String name,
      String subtype,
      Color color,
      String iconPath,) {
    return Block(
      id: id,
      name: name,
      description: '',
      type: BlockType.color,
      subtype: subtype,
      properties: {
        'color': color.value.toString(),
      },
      connections: [
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
      ],
      iconPath: iconPath,
      color: color,
    );
  }

  Widget _buildStructureBlocks(BuildContext context) {
    final structures = [
      _createStructureBlock(
        'loop_block',
        'Loop Block',
        'Repeats the connected blocks',
        'loop_block',
        Colors.green,
        'assets/images/blocks/loop_icon.png',
      ),
      _createStructureBlock(
        'row_block',
        'Row Block',
        'Arranges blocks in a row',
        'row_block',
        Colors.amber,
        'assets/images/blocks/row_icon.png',
      ),
      _createStructureBlock(
        'column_block',
        'Column Block',
        'Arranges blocks in a column',
        'column_block',
        Colors.cyan,
        'assets/images/blocks/column_icon.png',
      ),
    ];

    return Column(
      children: structures.map((structure) {
        return _buildToolboxBlock(
          context,
          structure,
        );
      }).toList(),
    );
  }

  Block _createStructureBlock(String id,
      String name,
      String description,
      String subtype,
      Color color,
      String iconPath,) {
    final connections = <BlockConnection>[];

    // Add input connection
    connections.add(BlockConnection(
      id: '${id}_input',
      name: 'Input',
      type: ConnectionType.input,
      position: const Offset(0, 0.5),
    ));

    // Add output connection
    connections.add(BlockConnection(
      id: '${id}_output',
      name: 'Output',
      type: ConnectionType.output,
      position: const Offset(1, 0.5),
    ));

    // Add special body connection for loop blocks
    if (subtype == 'loop_block') {
      connections.add(BlockConnection(
        id: '${id}_body',
        name: 'Body',
        type: ConnectionType.output,
        position: const Offset(0.5, 1),
      ));
    }

    return Block(
      id: id,
      name: name,
      description: description,
      type: BlockType.structure,
      subtype: subtype,
      properties: {
        'value': '4',
      },
      connections: connections,
      iconPath: iconPath,
      color: color,
    );
  }

  Widget _buildToolboxBlock(BuildContext context,
      Block block,) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: DraggableBlock(
        blockId: block.id,
        onDragStarted: () {},
        onDragEndSimple: () {},
        onDoubleTap: () => onBlockSelected(block),
        // Add double tap handler
        child: ListTile(
          leading: _buildBlockIcon(block),
          title: Text(
            block.name,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          subtitle: difficulty != PatternDifficulty.basic &&
              block.description.isNotEmpty
              ? Text(
            block.description,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          )
              : null,
          dense: true,
          onTap: () => onBlockSelected(block),
        ),
      ),
    );
  }

  /// Build the icon for a block, with fallbacks for missing images
  Widget _buildBlockIcon(Block block) {
    if (block.iconPath.isEmpty) {
      // No icon path specified, use default icon based on block type
      if (block.type == BlockType.color) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: block.color,
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      } else {
        return Icon(
          _getBlockIcon(block.subtype),
          color: block.color,
        );
      }
    }

    // Try to load the image, with fallback to icon
    return Image.asset(
      block.iconPath,
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon or color block if image fails to load
        if (block.type == BlockType.color) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: block.color,
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        } else {
          return Icon(
            _getBlockIcon(block.subtype),
            color: block.color,
          );
        }
      },
    );
  }

  IconData _getBlockIcon(String blockType) {
    switch (blockType) {
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
