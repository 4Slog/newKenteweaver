import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';
import 'connected_block.dart';
import 'animated_block_connection.dart';

/// A smart workspace for arranging and connecting blocks to create Kente patterns.
///
/// The workspace allows drag-and-drop block manipulation, connection management,
/// and visual feedback for the pattern creation process.
class SmartWorkspace extends StatefulWidget {
  /// Collection of blocks in the workspace
  final BlockCollection blockCollection;

  /// Current difficulty level
  final PatternDifficulty difficulty;

  /// Callback when a block is selected
  final Function(Block) onBlockSelected;

  /// Callback when the workspace is changed
  final VoidCallback onWorkspaceChanged;

  /// Callback when a block is deleted (null for read-only mode)
  final Function(String)? onDelete;

  /// Callback when a block's value is changed
  final Function(String, String)? onValueChanged;

  /// Callback when blocks are connected
  final Function(String, String, String, String)? onBlocksConnected;

  /// Whether to show connections between blocks
  final bool showConnections;

  /// Whether to show the grid background
  final bool showGrid;

  /// Whether block movement is enabled
  final bool enableBlockMovement;

  /// Initial scale factor for the workspace
  final double initialScale;

  /// Maximum allowed scale factor
  final double maxScale;

  /// Minimum allowed scale factor
  final double minScale;

  const SmartWorkspace({
    super.key,
    required this.blockCollection,
    required this.difficulty,
    required this.onBlockSelected,
    required this.onWorkspaceChanged,
    this.onDelete,
    this.onValueChanged,
    this.onBlocksConnected,
    this.showConnections = true,
    this.showGrid = true,
    this.enableBlockMovement = true,
    this.initialScale = 1.0,
    this.maxScale = 3.0,
    this.minScale = 0.5,
  });

  @override
  State<SmartWorkspace> createState() => _SmartWorkspaceState();
}

class _SmartWorkspaceState extends State<SmartWorkspace> {
  // Block positions in the workspace
  final Map<String, Offset> _blockPositions = {};

  // Currently dragged block ID
  String? _draggedBlockId;

  // Selected connection for connection creation
  String? _selectedConnection;

  // Whether we're in connection creation mode
  bool _isConnecting = false;

  // Current drag end position during connection creation
  Offset? _dragEndPosition;

  // Selected blocks (for multi-select)
  final Set<String> _selectedBlockIds = {};

  // Workspace scale and offset for pan/zoom
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // TransformationController for InteractiveViewer
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _initializeBlockPositions();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SmartWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If block collection changed, update positions for new blocks
    if (oldWidget.blockCollection != widget.blockCollection) {
      _updateBlockPositionsForNewBlocks();
    }
  }

  /// Initialize block positions for all blocks in the collection
  void _initializeBlockPositions() {
    // Create positions in a grid layout
    final blocksPerRow = 3;
    int row = 0;
    int col = 0;

    for (final block in widget.blockCollection.blocks) {
      if (!_blockPositions.containsKey(block.id)) {
        _blockPositions[block.id] = Offset(
          100.0 + col * 250.0,
          100.0 + row * 150.0,
        );

        col++;
        if (col >= blocksPerRow) {
          col = 0;
          row++;
        }
      }
    }
  }

  /// Update positions for newly added blocks
  void _updateBlockPositionsForNewBlocks() {
    // Find blocks without positions
    for (final block in widget.blockCollection.blocks) {
      if (!_blockPositions.containsKey(block.id)) {
        // Find a good spot for the new block
        _blockPositions[block.id] = _findNextAvailablePosition();
      }
    }

    // Remove positions for deleted blocks
    final currentBlockIds = widget.blockCollection.blocks.map((b) => b.id).toSet();
    _blockPositions.removeWhere((id, _) => !currentBlockIds.contains(id));
  }

  /// Find the next available position for a new block
  Offset _findNextAvailablePosition() {
    // Default position if no existing blocks
    if (_blockPositions.isEmpty) {
      return const Offset(100, 100);
    }

    // Try to find a position near a connected block if possible
    // For now, just place it in the center of visible blocks
    final positions = _blockPositions.values.toList();
    double avgX = positions.map((p) => p.dx).reduce((a, b) => a + b) / positions.length;
    double avgY = positions.map((p) => p.dy).reduce((a, b) => a + b) / positions.length;

    // Add a small offset to prevent exact overlap
    return Offset(avgX + 50, avgY + 50);
  }

  /// Update a block's position
  void _updateBlockPosition(String blockId, Offset position) {
    setState(() {
      _blockPositions[blockId] = position;
    });
    widget.onWorkspaceChanged();
  }

  /// Handle when a block drag ends
  void _handleBlockDragEnd(String blockId, Offset position) {
    _updateBlockPosition(blockId, position);
    setState(() {
      _draggedBlockId = null;
      _dragEndPosition = null;
    });
  }

  /// Start creating a connection from a block
  void _startConnectionDrag(String blockId, String connectionId) {
    setState(() {
      _draggedBlockId = blockId;
      _selectedConnection = connectionId;
      _isConnecting = true;
    });
  }

  /// Update connection drag position
  void _handleConnectionDragUpdate(Offset position) {
    setState(() {
      _dragEndPosition = position;
    });
  }

  /// Handle when a connection drag ends at a target
  void _handleConnectionDragEnd(String targetBlockId, String targetConnectionId) {
    if (_draggedBlockId != null && _selectedConnection != null) {
      widget.onBlocksConnected?.call(
        _draggedBlockId!,
        _selectedConnection!,
        targetBlockId,
        targetConnectionId,
      );

      setState(() {
        _draggedBlockId = null;
        _selectedConnection = null;
        _isConnecting = false;
        _dragEndPosition = null;
      });

      widget.onWorkspaceChanged();
    }
  }

  /// Cancel connection creation
  void _cancelConnectionDrag() {
    setState(() {
      _draggedBlockId = null;
      _selectedConnection = null;
      _isConnecting = false;
      _dragEndPosition = null;
    });
  }

  /// Get the appropriate color for the current difficulty
  Color getDifficultyColor(PatternDifficulty difficulty, BuildContext context) {
    return AppTheme.getDifficultyColor(difficulty, context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Workspace header with controls
        _buildWorkspaceHeader(context),

        // Main workspace area
        Expanded(
          child: _buildWorkspaceArea(context),
        ),
      ],
    );
  }

  Widget _buildWorkspaceHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Workspace',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          // Add zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _scale = (_scale - 0.1).clamp(widget.minScale, widget.maxScale);
                _updateTransformationController();
              });
            },
            tooltip: 'Zoom out',
            iconSize: 20,
          ),
          Text(
            '${(_scale * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _scale = (_scale + 0.1).clamp(widget.minScale, widget.maxScale);
                _updateTransformationController();
              });
            },
            tooltip: 'Zoom in',
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          // Add reset view button
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _resetView,
            tooltip: 'Reset view',
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: getDifficultyColor(widget.difficulty, context).withOpacity(0.05),
      ),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        onInteractionEnd: (_) {
          // Update scale and offset when interaction ends
          final matrix = _transformationController.value;
          setState(() {
            _scale = matrix.getMaxScaleOnAxis();
            _offset = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Grid background if enabled
            if (widget.showGrid)
              CustomPaint(
                painter: _GridPainter(),
                size: Size.infinite,
              ),

            // Connections between blocks
            if (widget.showConnections)
              _buildBlockConnections(),

            // Currently dragging connection
            if (_isConnecting && _draggedBlockId != null &&
                _selectedConnection != null && _dragEndPosition != null)
              _buildDraggingConnection(),

            // Blocks
            ..._buildBlocks(),

            // Empty state message
            if (widget.blockCollection.blocks.isEmpty)
              Center(
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
                      'Drag blocks here to start building',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Update the transformation controller with the current scale and offset
  void _updateTransformationController() {
    final updatedMatrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
    _transformationController.value = updatedMatrix;
  }

  /// Reset the view to the initial state
  void _resetView() {
    setState(() {
      _scale = widget.initialScale;
      _offset = Offset.zero;
      _transformationController.value = Matrix4.identity();
    });
  }

  /// Build connections between blocks
  Widget _buildBlockConnections() {
    final connections = <Widget>[];

    for (final block in widget.blockCollection.blocks) {
      final blockPosition = _blockPositions[block.id] ?? Offset.zero;

      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          // Extract target block ID from connection ID
          final targetConnParts = connection.connectedToId!.split('_');
          final targetBlockId = targetConnParts.first;

          final targetBlock = widget.blockCollection.getBlockById(targetBlockId);
          if (targetBlock != null) {
            final targetPosition = _blockPositions[targetBlockId] ?? Offset.zero;

            // Find the target connection point
            final targetConn = targetBlock.connections.firstWhere(
                  (c) => c.id == connection.connectedToId,
              orElse: () => BlockConnection(
                id: '',
                name: '',
                type: ConnectionType.none,
                position: Offset.zero,
              ),
            );

            // Calculate actual connection points
            final startPoint = _getConnectionPoint(blockPosition, connection.position);
            final endPoint = _getConnectionPoint(targetPosition, targetConn.position);

            connections.add(
              AnimatedBlockConnection(
                difficulty: widget.difficulty,
                startPoint: startPoint,
                endPoint: endPoint,
                isValid: true,
                isHighlighted: false,
                onTap: () {
                  // Allow disconnecting by tapping the connection
                  _disconnectBlocks(block.id, connection.id);
                },
              ),
            );
          }
        }
      }
    }

    return Stack(children: connections);
  }

  /// Build the currently dragging connection
  Widget _buildDraggingConnection() {
    final block = widget.blockCollection.getBlockById(_draggedBlockId!);
    if (block == null) return const SizedBox.shrink();

    final connection = block.connections.firstWhere(
          (c) => c.id == _selectedConnection,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    final blockPosition = _blockPositions[block.id] ?? Offset.zero;
    final startPoint = _getConnectionPoint(blockPosition, connection.position);

    return AnimatedBlockConnection(
      difficulty: widget.difficulty,
      startPoint: startPoint,
      endPoint: _dragEndPosition!,
      isValid: _isValidConnection(connection.type),
      isHighlighted: true,
    );
  }

  /// Check if the current dragging connection is valid
  bool _isValidConnection(ConnectionType sourceType) {
    // Output connections should connect to input connections and vice versa
    if (sourceType == ConnectionType.output) {
      return true; // Will validate on drop
    } else if (sourceType == ConnectionType.input) {
      return true; // Will validate on drop
    }
    return false;
  }

  /// Calculate the absolute position of a connection point
  Offset _getConnectionPoint(Offset blockPosition, Offset relativePosition) {
    // Block dimensions
    const blockWidth = 200.0;
    const blockHeight = 100.0;

    return Offset(
      blockPosition.dx + relativePosition.dx * blockWidth,
      blockPosition.dy + relativePosition.dy * blockHeight,
    );
  }

  /// Build the list of block widgets
  List<Widget> _buildBlocks() {
    final blocks = <Widget>[];

    for (final block in widget.blockCollection.blocks) {
      final position = _blockPositions[block.id] ?? Offset.zero;
      final isSelected = _selectedBlockIds.contains(block.id);

      blocks.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: widget.enableBlockMovement
                ? (details) => _updateBlockPosition(
              block.id,
              Offset(position.dx + details.delta.dx, position.dy + details.delta.dy),
            )
                : null,
            onPanEnd: (_) => widget.onWorkspaceChanged(),
            onTap: () {
              setState(() {
                if (_selectedBlockIds.contains(block.id)) {
                  _selectedBlockIds.remove(block.id);
                } else {
                  _selectedBlockIds.add(block.id);
                }
              });
              widget.onBlockSelected(block);
            },
            onDoubleTap: () {
              // Show a context menu for the block
              _showBlockContextMenu(context, block, position);
            },
            child: ConnectedBlock(
              block: block,
              onDelete: widget.onDelete != null
                  ? () => widget.onDelete!(block.id)
                  : null,
              onValueChanged: (value) => widget.onValueChanged != null
                  ? widget.onValueChanged!(block.id, value)
                  : {},
              onConnectionDragStart: _startConnectionDrag,
              onConnectionDragUpdate: _handleConnectionDragUpdate,
              onConnectionDragEnd: _handleConnectionDragEnd,
              onConnectionDragCancel: _cancelConnectionDrag,
              difficulty: widget.difficulty,
              isSelected: isSelected,
            ),
          ),
        ),
      );
    }

    return blocks;
  }

  /// Show context menu for a block
  void _showBlockContextMenu(BuildContext context, Block block, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 100, // x position
        position.dy + 50,  // y position
        position.dx + 100, // x position
        position.dy + 50,  // y position
      ),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              widget.onBlockSelected(block);
            },
          ),
        ),
        if (widget.onDelete != null)
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete!(block.id);
              },
            ),
          ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              _duplicateBlock(block);
            },
          ),
        ),
      ],
    );
  }

  /// Duplicate a block
  void _duplicateBlock(Block block) {
    // Create a new block based on the existing one
    final originalPosition = _blockPositions[block.id] ?? Offset.zero;
    final newPosition = Offset(originalPosition.dx + 50, originalPosition.dy + 50);

    // Create a unique ID for the new block
    final uniqueId = '${block.id}_copy_${DateTime.now().millisecondsSinceEpoch}';

    // Create a new block with the same properties
    final newBlock = block.copyWith(
      id: uniqueId,
      // Reset connections since they shouldn't be copied
      connections: block.connections.map((conn) {
        return BlockConnection(
          id: '${uniqueId}_${conn.id.split('_').last}',
          name: conn.name,
          type: conn.type,
          position: conn.position,
        );
      }).toList(),
    );

    // Add the new block to the collection
    final updatedBlocks = [...widget.blockCollection.blocks, newBlock];
    final newCollection = BlockCollection(blocks: updatedBlocks);

    // Update positions
    setState(() {
      _blockPositions[uniqueId] = newPosition;
    });

    // Update parent
    widget.onWorkspaceChanged();

    // Let the parent know about the new block
    widget.onBlockSelected(newBlock);
  }

  /// Disconnect blocks
  void _disconnectBlocks(String blockId, String connectionId) {
    // Find the block and connection
    final block = widget.blockCollection.getBlockById(blockId);
    if (block == null) return;

    final connection = block.connections.firstWhere(
          (c) => c.id == connectionId,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    if (connection.connectedToId == null) return;

    // Find the connected block and connection
    final connectedParts = connection.connectedToId!.split('_');
    if (connectedParts.isEmpty) return;

    final connectedBlockId = connectedParts.first;
    final connectedBlock = widget.blockCollection.getBlockById(connectedBlockId);
    if (connectedBlock == null) return;

    // Find the connected connection
    final connectedConnection = connectedBlock.connections.firstWhere(
          (c) => c.id == connection.connectedToId,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.none,
        position: Offset.zero,
      ),
    );

    // Disconnect the connections
    setState(() {
      connection.connectedToId = null;
      connectedConnection.connectedToId = null;
    });

    widget.onWorkspaceChanged();
  }
}

/// Painter for the background grid
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}