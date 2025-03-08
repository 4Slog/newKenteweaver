import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';
import 'connected_block.dart';
import 'animated_block_connection.dart';
import 'pattern_popup_preview.dart';
import '../services/gemini_service.dart';

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

class _SmartWorkspaceState extends State<SmartWorkspace> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late GeminiService _geminiService;
  
  // Track drag positions for snapping
  Offset? _dragStartPosition;
  Block? _draggedBlock;
  double _currentScale = 1.0;
  bool _isSnapping = false;
  final double _snapThreshold = 20.0;
  final double _gridSize = 40.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _geminiService = GeminiService();
    _currentScale = widget.initialScale;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleBlockDragStart(Block block, Offset position) {
    setState(() {
      _draggedBlock = block;
      _dragStartPosition = position;
    });
  }

  void _handleBlockDragUpdate(Offset position) {
    if (_draggedBlock == null) return;

    final delta = position - _dragStartPosition!;
    setState(() {
      _draggedBlock!.position += delta / _currentScale;
      _dragStartPosition = position;
      _checkForSnapping();
    });
  }

  void _checkForSnapping() {
    if (_draggedBlock == null) return;

    for (final block in widget.blockCollection.blocks) {
      if (block == _draggedBlock) continue;

      // Check for horizontal and vertical snapping
      final horizontalSnap = _checkHorizontalSnap(block);
      final verticalSnap = _checkVerticalSnap(block);

      if (horizontalSnap || verticalSnap) {
        setState(() => _isSnapping = true);
        widget.onBlocksConnected?.call(
          _draggedBlock!.id,
          block.id,
          horizontalSnap ? 'horizontal' : 'vertical',
          DateTime.now().toString(),
        );
        break;
      }
    }
  }

  bool _checkHorizontalSnap(Block target) {
    final draggedRight = _draggedBlock!.position.dx + _draggedBlock!.size.width;
    final targetLeft = target.position.dx;
    
    if ((draggedRight - targetLeft).abs() < _snapThreshold) {
      _snapBlocksHorizontally(target);
      return true;
    }
    return false;
  }

  bool _checkVerticalSnap(Block target) {
    final draggedBottom = _draggedBlock!.position.dy + _draggedBlock!.size.height;
    final targetTop = target.position.dy;
    
    if ((draggedBottom - targetTop).abs() < _snapThreshold) {
      _snapBlocksVertically(target);
      return true;
    }
    return false;
  }

  void _snapBlocksHorizontally(Block target) {
    setState(() {
      final newX = target.position.dx - _draggedBlock!.size.width;
      _draggedBlock!.position = Offset(newX, _draggedBlock!.position.dy);
    });
  }

  void _snapBlocksVertically(Block target) {
    setState(() {
      final newY = target.position.dy - _draggedBlock!.size.height;
      _draggedBlock!.position = Offset(_draggedBlock!.position.dx, newY);
    });
  }

  Future<void> _handlePatternPreview() async {
    final patternJson = widget.blockCollection.toJson();
    final enhancedPattern = await _geminiService.enhancePattern(patternJson);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => PatternPopupPreview(
        pattern: enhancedPattern,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        onInteractionUpdate: (details) {
          setState(() => _currentScale = details.scale);
        },
        child: Stack(
          children: [
            if (widget.showGrid) _buildGrid(),
            ..._buildBlocks(),
            if (widget.showConnections) _buildConnections(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handlePatternPreview,
        child: const Icon(Icons.preview),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      painter: GridPainter(
        gridSize: _gridSize * _currentScale,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  List<Widget> _buildBlocks() {
    return widget.blockCollection.blocks.map((block) {
      return Positioned(
        left: block.position.dx,
        top: block.position.dy,
        child: GestureDetector(
          onPanStart: (details) => _handleBlockDragStart(block, details.globalPosition),
          onPanUpdate: (details) => _handleBlockDragUpdate(details.globalPosition),
          child: ConnectedBlock(
            block: block,
            isSelected: _draggedBlock == block,
            onEdit: widget.onValueChanged != null ? (value) => widget.onValueChanged!(block.id, value) : null,
            onDelete: widget.onDelete != null ? () => widget.onDelete!(block.id) : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildConnections() {
    return CustomPaint(
      painter: ConnectionsPainter(
        blocks: widget.blockCollection.blocks,
        scale: _currentScale,
        isSnapping: _isSnapping,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  GridPainter({required this.gridSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      gridSize != oldDelegate.gridSize || color != oldDelegate.color;
}

class ConnectionsPainter extends CustomPainter {
  final List<Block> blocks;
  final double scale;
  final bool isSnapping;

  ConnectionsPainter({
    required this.blocks,
    required this.scale,
    required this.isSnapping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSnapping ? Colors.green : Colors.blue
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke;

    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          final connectedBlock = blocks.firstWhere(
            (b) => b.id == connection.connectedToId,
          );
          
          final start = block.position + connection.position;
          final end = connectedBlock.position + 
            connectedBlock.connections.firstWhere(
              (c) => c.id == connection.connectedToId
            ).position;

          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ConnectionsPainter oldDelegate) =>
      blocks != oldDelegate.blocks ||
      scale != oldDelegate.scale ||
      isSnapping != oldDelegate.isSnapping;
}