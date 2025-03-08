class EnhancedWorkspacePreview extends StatefulWidget {
  final TutorialVisualController controller;
  final bool allowInteraction;
  final List<String>? highlightedBlocks;
  final Function(String)? onBlockInteraction;

  EnhancedWorkspacePreview({
    required this.controller,
    this.allowInteraction = false,
    this.highlightedBlocks,
    this.onBlockInteraction,
  });

  @override
  _EnhancedWorkspacePreviewState createState() => _EnhancedWorkspacePreviewState();
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
                        style: BorderStyle.dashed,
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
      case TutorialState.introduction:
        return 'Getting Started';
      case TutorialState.workspaceReveal:
        return 'Exploring the Workspace';
      case TutorialState.blockIntroduction:
        return 'Meeting the Blocks';
      case TutorialState.firstBlock:
        return 'First Steps';
      case TutorialState.connecting:
        return 'Making Connections';
      case TutorialState.patternPreview:
        return 'Pattern Preview';
      case TutorialState.completion:
        return 'Well Done!';
    }
  }
} 