import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../models/tutorial_state.dart';

class GridPainter extends CustomPainter {
  final double opacity;
  final double gridSize;
  final Color lineColor;

  GridPainter({
    required this.opacity,
    required this.gridSize,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

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
  bool shouldRepaint(GridPainter oldDelegate) {
    return opacity != oldDelegate.opacity ||
           gridSize != oldDelegate.gridSize ||
           lineColor != oldDelegate.lineColor;
  }
}

class HighlightPainter extends CustomPainter {
  final List<String> highlights;
  final double intensity;
  final Color color;

  HighlightPainter({
    required this.highlights,
    required this.intensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2 * intensity)
      ..style = PaintingStyle.fill;

    // Draw highlight rectangles for each highlighted element
    for (final highlight in highlights) {
      // Get the bounds for the highlighted element
      final bounds = _getHighlightBounds(highlight, size);
      canvas.drawRect(bounds, paint);
    }
  }

  Rect _getHighlightBounds(String highlight, Size size) {
    // This is a simplified version - in a real app, you would calculate
    // the actual bounds based on the element's position and size
    switch (highlight) {
      case 'workspace':
        return Rect.fromLTWH(0, 0, size.width, size.height);
      case 'toolbox':
        return Rect.fromLTWH(0, 0, size.width, 80);
      default:
        return Rect.fromLTWH(0, 0, 80, 80);
    }
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return highlights != oldDelegate.highlights ||
           intensity != oldDelegate.intensity ||
           color != oldDelegate.color;
  }
}

class TutorialVisualController extends ChangeNotifier {
  final ValueNotifier<double> workspaceOpacity = ValueNotifier(0.0);
  final ValueNotifier<double> blockScale = ValueNotifier(1.0);
  final ValueNotifier<double> highlightIntensity = ValueNotifier(0.0);
  TutorialState currentState = TutorialState.initial;
  double progress = 0.0;

  void updateState(TutorialState newState) {
    currentState = newState;
    notifyListeners();
  }

  void updateProgress(double value) {
    progress = value;
    notifyListeners();
  }
}

class EnhancedWorkspacePreview extends StatefulWidget {
  final TutorialVisualController controller;
  final bool allowInteraction;
  final List<String>? highlightedBlocks;
  final Function(String)? onBlockInteraction;

  const EnhancedWorkspacePreview({
    super.key,
    required this.controller,
    this.allowInteraction = false,
    this.highlightedBlocks,
    this.onBlockInteraction,
  });

  @override
  State<EnhancedWorkspacePreview> createState() => _EnhancedWorkspacePreviewState();
}

class _EnhancedWorkspacePreviewState extends State<EnhancedWorkspacePreview> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Grid background
            _buildGrid(),
            
            // Workspace content
            _buildWorkspaceContent(),
            
            // Highlight overlay
            if (widget.highlightedBlocks != null)
              _buildHighlightOverlay(),
            
            // Interaction overlay
            if (!widget.allowInteraction)
              _buildInteractionOverlay(),
            
            // Tutorial indicators
            _buildTutorialIndicators(),
          ],
        );
      },
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      painter: GridPainter(
        opacity: widget.controller.workspaceOpacity.value,
        gridSize: 20,
        lineColor: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
    );
  }

  Widget _buildWorkspaceContent() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.controller.workspaceOpacity,
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: Duration(milliseconds: 300),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBlocksToolbox(),
                SizedBox(height: 16),
                _buildWorkspaceArea(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlocksToolbox() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(8),
        children: [
          _buildBlock('start', 'Start'),
          _buildBlock('pattern', 'Pattern'),
          _buildBlock('color', 'Color'),
          _buildBlock('repeat', 'Repeat'),
        ],
      ),
    );
  }

  Widget _buildBlock(String type, String label) {
    final isHighlighted = widget.highlightedBlocks?.contains(type) ?? false;
    
    return ValueListenableBuilder<double>(
      valueListenable: widget.controller.blockScale,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: isHighlighted ? scale : 1.0,
          child: DragTarget<String>(
            onAccept: (data) {
              widget.onBlockInteraction?.call(type);
            },
            builder: (context, candidates, rejects) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isHighlighted
                    ? [BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )]
                    : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBlockIcon(type),
                      color: isHighlighted ? Colors.white : Colors.black87,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceArea() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: DragTarget<String>(
          onAccept: (data) {
            widget.onBlockInteraction?.call('workspace_drop');
          },
          builder: (context, candidates, rejects) {
            return Stack(
              children: [
                // Placeholder text
                if (widget.controller.currentState == TutorialState.workspaceReveal)
                  Center(
                    child: Text(
                      'This is your workspace.\nDrag blocks here to build your pattern.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                // Drop indication
                if (candidates.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHighlightOverlay() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.controller.highlightIntensity,
      builder: (context, intensity, child) {
        return CustomPaint(
          painter: HighlightPainter(
            highlights: widget.highlightedBlocks!,
            intensity: intensity,
            color: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildInteractionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Follow the tutorial to interact with the workspace',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialIndicators() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Row(
        children: [
          // Progress indicator
          CircularProgressIndicator(
            value: widget.controller.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 8),
          // State indicator
          Text(
            _getStateDescription(widget.controller.currentState),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  IconData _getBlockIcon(String type) {
    switch (type) {
      case 'start':
        return Icons.play_arrow;
      case 'pattern':
        return Icons.grid_on;
      case 'color':
        return Icons.palette;
      case 'repeat':
        return Icons.repeat;
      default:
        return Icons.widgets;
    }
  }

  String _getStateDescription(TutorialState state) {
    switch (state) {
      case TutorialState.initial:
        return 'Getting Started';
      case TutorialState.introduction:
        return 'Introduction';
      case TutorialState.workspaceReveal:
        return 'Exploring the Workspace';
      case TutorialState.blockDragging:
        return 'Learning Block Dragging';
      case TutorialState.patternSelection:
        return 'Selecting Patterns';
      case TutorialState.colorSelection:
        return 'Choosing Colors';
      case TutorialState.loopUsage:
        return 'Using Loops';
      case TutorialState.rowColumns:
        return 'Working with Rows and Columns';
      case TutorialState.culturalContext:
        return 'Understanding Cultural Context';
      case TutorialState.challenge:
        return 'Taking the Challenge';
      case TutorialState.next:
        return 'Next Step';
      case TutorialState.complete:
        return 'Tutorial Complete';
    }
  }
} 
