import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/block_definition_service.dart';
import '../theme/app_theme.dart';
import 'draggable_block.dart';

/// A toolbox of available blocks for the pattern creation workspace.
/// Displays blocks organized by category with filtering options based on difficulty.
class BlocksToolbox extends StatefulWidget {
  /// Callback when a block is selected
  final Function(Block) onBlockSelected;

  /// Callback when a block is dragged
  final Function(Block) onBlockDragged;

  /// Current difficulty level, used to filter available blocks
  final PatternDifficulty difficulty;

  /// Optional notifier for the selected category
  final ValueNotifier<String>? selectedCategoryNotifier;

  /// Width of the toolbox panel
  final double width;

  /// Whether to use expandable categories
  final bool useExpandableCategories;

  /// Whether to show labels
  final bool showLabels;

  /// Block scale
  final double blockScale;

  const BlocksToolbox({
    super.key,
    required this.onBlockSelected,
    required this.onBlockDragged,
    required this.difficulty,
    this.selectedCategoryNotifier,
    this.width = 300,
    this.useExpandableCategories = true,
    this.showLabels = true,
    this.blockScale = 1.0,
  });

  @override
  State<BlocksToolbox> createState() => _BlocksToolboxState();
}

class _BlocksToolboxState extends State<BlocksToolbox> with SingleTickerProviderStateMixin {
  late ValueNotifier<String> _selectedCategoryNotifier;
  late BlockDefinitionService _blockDefinitionService;
  late TabController _tabController;

  // List of available blocks by category
  List<Block> _patternBlocks = [];
  List<Block> _colorBlocks = [];
  List<Block> _structureBlocks = [];

  // Expanded categories tracking
  Map<String, bool> _expandedCategories = {};

  // Loading state
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Use provided notifier or create a local one
    _selectedCategoryNotifier = widget.selectedCategoryNotifier ??
        ValueNotifier<String>('Pattern Blocks');

    // Initialize the block definition service
    _blockDefinitionService = BlockDefinitionService();

    // Initialize tab controller for category switching
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load blocks
    _loadBlocks();
  }

  @override
  void dispose() {
    // Only dispose the notifier if we created it
    if (widget.selectedCategoryNotifier == null) {
      _selectedCategoryNotifier.dispose();
    }

    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final categories = ['Pattern Blocks', 'Color Blocks', 'Structure Blocks'];
      if (_tabController.index < categories.length) {
        _selectedCategoryNotifier.value = categories[_tabController.index];
      }
    }
  }

  /// Load blocks from the block definition service
  Future<void> _loadBlocks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load definitions if not already loaded
      await _blockDefinitionService.loadDefinitions();

      // Filter blocks by type and difficulty
      _filterBlocksByDifficulty();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load blocks: $e';
      });
      debugPrint('Error loading blocks: $e');
    }
  }

  /// Filter blocks based on difficulty level
  void _filterBlocksByDifficulty() {
    // Get all blocks
    final allBlocks = _blockDefinitionService.getAllBlocks();

    // Get allowed difficulties (current and lower)
    final allowedDifficulties = PatternDifficulty.values
        .where((d) => d.index <= widget.difficulty.index)
        .map((d) => d.toString().split('.').last)
        .toList();

    // Filter by difficulty and type
    _patternBlocks = allBlocks.where((block) {
      final blockDifficulty = block.properties['difficulty'] ?? 'basic';
      return block.type == BlockType.pattern &&
          allowedDifficulties.contains(blockDifficulty);
    }).toList();

    _colorBlocks = allBlocks.where((block) {
      final blockDifficulty = block.properties['difficulty'] ?? 'basic';
      return block.type == BlockType.color &&
          allowedDifficulties.contains(blockDifficulty);
    }).toList();

    _structureBlocks = allBlocks.where((block) {
      final blockDifficulty = block.properties['difficulty'] ?? 'basic';
      return (block.type == BlockType.structure ||
          block.type == BlockType.loop ||
          block.type == BlockType.row ||
          block.type == BlockType.column) &&
          allowedDifficulties.contains(blockDifficulty);
    }).toList();

    // Initialize expanded state for categories
    _expandedCategories = {
      'Patterns': true,
      'Colors': true,
      'Structure': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
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
          _buildCategoryTabs(context, _selectedCategoryNotifier),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBlocks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _selectedCategoryNotifier,
                builder: (context, selectedCategory, child) {
                  return _buildBlocksList(context, selectedCategory);
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
          const Spacer(),
          // Difficulty indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.difficulty.displayName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
      color: Colors.grey[200],
      child: TabBar(
        controller: _tabController,
        tabs: categories.map((category) {
          return Tab(
            child: Text(
              category,
              style: const TextStyle(color: Colors.black87),
            ),
          );
        }).toList(),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.kenteGold,
              width: 3,
            ),
          ),
          color: Colors.white,
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  Widget _buildBlocksList(BuildContext context, String selectedCategory) {
    // Determine which blocks to show
    List<Block> blocks = [];
    switch (selectedCategory) {
      case 'Pattern Blocks':
        blocks = _patternBlocks;
        break;
      case 'Color Blocks':
        blocks = _colorBlocks;
        break;
      case 'Structure Blocks':
        blocks = _structureBlocks;
        break;
      default:
        blocks = [];
    }

    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'No blocks available',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing difficulty level',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Group blocks by subcategory if using expandable categories
    if (widget.useExpandableCategories) {
      return _buildExpandableBlocksList(context, blocks, selectedCategory);
    } else {
      return _buildFlatBlocksList(context, blocks);
    }
  }

  Widget _buildExpandableBlocksList(
      BuildContext context,
      List<Block> blocks,
      String selectedCategory
      ) {
    // Group blocks by their subtype
    final Map<String, List<Block>> groupedBlocks = {};

    for (final block in blocks) {
      final groupKey = _getGroupKey(block, selectedCategory);

      if (!groupedBlocks.containsKey(groupKey)) {
        groupedBlocks[groupKey] = [];
      }

      groupedBlocks[groupKey]!.add(block);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: groupedBlocks.keys.length,
      itemBuilder: (context, index) {
        final groupKey = groupedBlocks.keys.elementAt(index);
        final groupBlocks = groupedBlocks[groupKey]!;

        return _buildExpandableCategory(
          context,
          groupKey,
          groupBlocks,
        );
      },
    );
  }

  String _getGroupKey(Block block, String selectedCategory) {
    // Determine the appropriate group key based on block type and category
    switch (selectedCategory) {
      case 'Pattern Blocks':
      // Group pattern blocks by their name before the first space
        return block.name.split(' ').first;
      case 'Color Blocks':
      // Group color blocks by color category
        if (block.name.contains('Gold') || block.name.contains('Yellow')) {
          return 'Gold & Yellow';
        } else if (block.name.contains('Red') || block.name.contains('Orange')) {
          return 'Red & Orange';
        } else if (block.name.contains('Blue') || block.name.contains('Purple')) {
          return 'Blue & Purple';
        } else if (block.name.contains('Green')) {
          return 'Green';
        } else {
          return 'Other Colors';
        }
      case 'Structure Blocks':
      // Group structure blocks by functionality
        if (block.type == BlockType.loop) {
          return 'Repetition';
        } else if (block.type == BlockType.row || block.type == BlockType.column) {
          return 'Arrangement';
        } else {
          return 'Other';
        }
      default:
        return 'Misc';
    }
  }

  Widget _buildExpandableCategory(
      BuildContext context,
      String categoryName,
      List<Block> blocks,
      ) {
    final isExpanded = _expandedCategories[categoryName] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategories[categoryName] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${blocks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blocks in this category
          if (isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                return _buildToolboxBlock(context, blocks[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlatBlocksList(BuildContext context, List<Block> blocks) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        return _buildToolboxBlock(context, blocks[index]);
      },
    );
  }

  Widget _buildToolboxBlock(
      BuildContext context,
      Block block,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildBlockIcon(block),
        title: Text(
          block.name,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        subtitle: widget.difficulty != PatternDifficulty.basic &&
            block.description.isNotEmpty
            ? Text(
          block.description,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        dense: true,
        trailing: DraggableBlock(
          block: block,
          onDragStarted: () => widget.onBlockDragged(block),
          onTap: () => widget.onBlockSelected(block),
          scale: widget.blockScale,
          showLabel: widget.showLabels,
          isCollapsed: true,
        ),
      ),
    );
  }

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
