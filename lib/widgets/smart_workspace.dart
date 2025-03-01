import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import 'connected_block.dart';
import 'animated_block_connection.dart';

class SmartWorkspace extends StatefulWidget {
  final BlockCollection blockCollection;
  final PatternDifficulty difficulty;
  final Function(Block) onBlockSelected;
  final VoidCallback onWorkspaceChanged;
  final Function(String)? onDelete;
  final Function(String, String)? onValueChanged;
  final Function(String, String, String, String)? onBlocksConnected;
  final bool showConnections;
  final bool showGrid;
  final bool enableBlockMovement;

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
  });

  @override
  State<SmartWorkspace> createState() => _SmartWorkspaceState();
}

class _SmartWorkspaceState extends State<SmartWorkspace> {
  // Track positions of blocks for connection lines
  final Map<String, Offset> _blockPositions = {};
  String? _draggedBlockId;
  String? _selectedConnection;
  bool _isConnecting = false;
  Offset? _dragEndPosition;
  
  @override
  void initState() {
    super.initState();
    _initializeBlockPositions();
  }
  
  @override
  void didUpdateWidget(SmartWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockCollection != widget.blockCollection) {
      _initializeBlockPositions();
    }
  }
  
  void _initializeBlockPositions() {
    // Initialize block positions in a grid layout if not already set
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
  
  void _updateBlockPosition(String blockId, Offset position) {
    setState(() {
      _blockPositions[blockId] = position;
    });
    widget.onWorkspaceChanged();
  }
  
  void _handleBlockDragEnd(String blockId, Offset position) {
    _updateBlockPosition(blockId, position);
    setState(() {
      _draggedBlockId = null;
      _dragEndPosition = null;
    });
  }
  
  void _startConnectionDrag(String blockId, String connectionId) {
    setState(() {
      _draggedBlockId = blockId;
      _selectedConnection = connectionId;
      _isConnecting = true;
    });
  }
  
  void _handleConnectionDragUpdate(Offset position) {
    setState(() {
      _dragEndPosition = position;
    });
  }
  
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
  
  void _cancelConnectionDrag() {
    setState(() {
      _draggedBlockId = null;
      _selectedConnection = null;
      _isConnecting = false;
      _dragEndPosition = null;
    });
  }

  Color getDifficultyColor(PatternDifficulty difficulty, BuildContext context) {
    final theme = Theme.of(context);
    switch (difficulty) {
      case PatternDifficulty.basic:
        return theme.colorScheme.primary;
      case PatternDifficulty.intermediate:
        return theme.colorScheme.secondary;
      case PatternDifficulty.advanced:
        return theme.colorScheme.tertiary;
      case PatternDifficulty.master:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: getDifficultyColor(widget.difficulty, context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: widget.showGrid
                ? Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  )
                : null,
          ),
          child: Column(
            children: [
              Text(
                'Difficulty: ${widget.difficulty.displayName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: [
                          // Grid background if enabled
                          if (widget.showGrid)
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _GridPainter(),
                            ),
                          
                          // Draw connections between blocks
                          if (widget.showConnections)
                            _buildConnections(),
                          
                          // Draw currently dragging connection
                          if (_isConnecting && _draggedBlockId != null && 
                              _selectedConnection != null && _dragEndPosition != null)
                            _buildDraggingConnection(),
                          
                          // Draw blocks
                          ..._buildBlocks(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildConnections() {
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
              ),
            );
          }
        }
      }
    }
    
    return Stack(children: connections);
  }
  
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
      isValid: false,
      isHighlighted: true,
    );
  }
  
  Offset _getConnectionPoint(Offset blockPosition, Offset relativePosition) {
    // Block dimensions (these should be constants or parameters)
    const blockWidth = 200.0;
    const blockHeight = 100.0;
    
    return Offset(
      blockPosition.dx + relativePosition.dx * blockWidth,
      blockPosition.dy + relativePosition.dy * blockHeight,
    );
  }
  
  List<Widget> _buildBlocks() {
    final blocks = <Widget>[];
    
    for (final block in widget.blockCollection.blocks) {
      final position = _blockPositions[block.id] ?? Offset.zero;
      
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
            onTap: () => widget.onBlockSelected(block),
            onDoubleTap: () {
              // Show a context menu for the block
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
                ],
              );
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
            ),
          ),
        ),
      );
    }
    
    return blocks;
  }
}

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
