import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class PatternVisualizer extends StatefulWidget {
  final List<List<String>> pattern;
  final double cellSize;
  final bool showGrid;
  final bool isInteractive;
  final bool showKenteInfo;
  final Function(int, int)? onCellTap;
  final String? patternTitle;
  final String? patternDescription;

  const PatternVisualizer({
    Key? key,
    required this.pattern,
    this.cellSize = 30.0,
    this.showGrid = true,
    this.isInteractive = false,
    this.showKenteInfo = true,
    this.onCellTap,
    this.patternTitle,
    this.patternDescription,
  }) : super(key: key);

  @override
  State<PatternVisualizer> createState() => _PatternVisualizerState();
}

class _PatternVisualizerState extends State<PatternVisualizer> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  double _currentScale = 1.0;
  int? _hoveredRow;
  int? _hoveredCol;
  bool _showInfoPanel = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });

    // Initialize with a slight zoom if the pattern is very small
    if (widget.pattern.length < 6 || widget.pattern[0].length < 6) {
      _currentScale = 1.5;
      _updateTransformationController();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateTransformationController() {
    final matrix = Matrix4.identity()
      ..scale(_currentScale, _currentScale);
    _transformationController.value = matrix;
  }

  void _handleZoomIn() {
    setState(() {
      _currentScale = math.min(4.0, _currentScale * 1.2);
      _animateScale();
    });
  }

  void _handleZoomOut() {
    setState(() {
      _currentScale = math.max(0.5, _currentScale / 1.2);
      _animateScale();
    });
  }

  void _handleResetZoom() {
    setState(() {
      _currentScale = 1.0;
      _animateScale();
    });
  }

  void _animateScale() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()..scale(_currentScale, _currentScale),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = widget.pattern.length;
        final cols = widget.pattern.isEmpty ? 0 : widget.pattern[0].length;

        // Calculate dynamic cell size based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight - (widget.showKenteInfo && _showInfoPanel ? 120 : 0);

        final dynamicCellSize = math.min(
          availableWidth / cols,
          availableHeight / rows,
        ).clamp(10.0, widget.cellSize);

        return Column(
          children: [
            // Pattern Title (if provided)
            if (widget.patternTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.patternTitle!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kenteGold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Pattern Description (if provided)
            if (widget.patternDescription != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  widget.patternDescription!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),

            // Pattern Display
            Expanded(
              child: Stack(
                children: [
                  // Pattern Grid with InteractiveViewer
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        boundaryMargin: const EdgeInsets.all(20.0),
                        minScale: 0.5,
                        maxScale: 4.0,
                        onInteractionEnd: (details) {
                          // Update scale value after pinch-zoom
                          _currentScale = _transformationController.value.getMaxScaleOnAxis();
                        },
                        child: Center(
                          child: MouseRegion(
                            onHover: widget.isInteractive ? (event) {
                              // Calculate cell position from hover coordinates
                              final patternWidth = cols * dynamicCellSize;
                              final patternHeight = rows * dynamicCellSize;

                              final centerX = (constraints.maxWidth - patternWidth) / 2;
                              final centerY = (availableHeight - patternHeight) / 2;

                              final gridX = (event.localPosition.dx - centerX) / dynamicCellSize;
                              final gridY = (event.localPosition.dy - centerY) / dynamicCellSize;

                              final hoveredCol = gridX.clamp(0, cols - 1).floor();
                              final hoveredRow = gridY.clamp(0, rows - 1).floor();

                              if (_hoveredRow != hoveredRow || _hoveredCol != hoveredCol) {
                                setState(() {
                                  _hoveredRow = hoveredRow;
                                  _hoveredCol = hoveredCol;
                                });
                              }
                            } : null,
                            onExit: widget.isInteractive ? (_) {
                              setState(() {
                                _hoveredRow = null;
                                _hoveredCol = null;
                              });
                            } : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                rows,
                                    (row) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    cols,
                                        (col) => GestureDetector(
                                      onTap: widget.onCellTap != null
                                          ? () => widget.onCellTap!(row, col)
                                          : null,
                                      child: _buildCell(
                                        widget.pattern[row][col],
                                        dynamicCellSize,
                                        row,
                                        col,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Zoom controls
                  if (widget.isInteractive)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildZoomButton(Icons.add, _handleZoomIn, 'Zoom in'),
                          const SizedBox(height: 8),
                          _buildZoomButton(Icons.refresh, _handleResetZoom, 'Reset zoom'),
                          const SizedBox(height: 8),
                          _buildZoomButton(Icons.remove, _handleZoomOut, 'Zoom out'),
                        ],
                      ),
                    ),

                  // Cell info tooltip when hovering
                  if (widget.isInteractive && _hoveredRow != null && _hoveredCol != null)
                    Positioned(
                      left: 16,
                      top: 16,
                      child: _buildCellInfoTooltip(_hoveredRow!, _hoveredCol!),
                    ),
                ],
              ),
            ),

            // Optional Pattern Information
            if (widget.showKenteInfo && _showInfoPanel) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pattern Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel),
                    tooltip: 'Toggle pattern information',
                  ),
                ],
              ),
              _buildPatternInfo(),
            ] else if (widget.showKenteInfo) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel),
                    tooltip: 'Show pattern information',
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCell(String color, double size, int row, int col) {
    final isHovered = widget.isInteractive && _hoveredRow == row && _hoveredCol == col;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _parseColor(color),
        border: widget.showGrid
            ? Border.all(
          color: isHovered ? Colors.white : Colors.grey[300]!,
          width: isHovered ? 2.0 : 0.5,
        )
            : null,
        boxShadow: isHovered
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ]
            : null,
      ),
      child: isHovered && widget.isInteractive
          ? Center(
        child: Icon(
          Icons.touch_app,
          size: size * 0.5,
          color: _isColorDark(_parseColor(color)) ? Colors.white70 : Colors.black54,
        ),
      )
          : null,
    );
  }

  bool _isColorDark(Color color) {
    // Calculate relative luminance
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance < 0.5;
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1, 7), radix: 16) + 0xFF000000);
      }

      // Handle color names
      switch (colorStr.toLowerCase()) {
        case 'gold':
          return AppTheme.kenteGold;
        case 'blue':
          return AppTheme.kenteBlue;
        case 'green':
          return AppTheme.kenteGreen;
        case 'red':
          return AppTheme.kenteRed;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'maroon':
          return const Color(0xFF800000);
        default:
          return Colors.grey;
      }
    } catch (e) {
      debugPrint('Error parsing color: $colorStr');
      return Colors.grey;
    }
  }

  Widget _buildPatternInfo() {
    // Calculate pattern properties
    final rows = widget.pattern.length;
    final cols = widget.pattern.isEmpty ? 0 : widget.pattern[0].length;

    // Count unique colors
    final uniqueColors = <String>{};
    for (final row in widget.pattern) {
      for (final colorStr in row) {
        uniqueColors.add(colorStr);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Size', '$rows × $cols', Icons.grid_on),
          _buildInfoItem('Colors', '${uniqueColors.length}', Icons.palette),
          if (uniqueColors.length < 2)
            _buildInfoItem(
              'Tip',
              'Add more colors',
              Icons.lightbulb_outline,
              tip: true,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {bool tip = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: tip ? Colors.amber : AppTheme.kenteGold,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: tip ? Colors.blue[700] : Colors.black87,
            fontStyle: tip ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: AppTheme.kenteGold,
      ),
    );
  }

  Widget _buildCellInfoTooltip(int row, int col) {
    if (_hoveredRow == null || _hoveredCol == null) return const SizedBox.shrink();

    final colorStr = widget.pattern[row][col];
    final color = _parseColor(colorStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Row: $row, Col: $col',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            colorStr,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}