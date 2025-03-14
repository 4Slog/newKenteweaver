import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/unified/pattern_engine.dart';
import '../services/pattern_analyzer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cultural_context_card.dart';
import '../widgets/weaving_pattern_renderer.dart';

/// A popup dialog for previewing generated Kente patterns.
///
/// This component provides an interactive preview of the generated pattern
/// with cultural context information, analysis, and export options.
class PatternPopupPreview extends StatefulWidget {
  /// The block collection used to generate the pattern
  final BlockCollection blockCollection;

  /// Whether to show grid lines on the pattern
  final bool showGrid;

  /// Whether to show cultural context information
  final bool showCulturalContext;

  /// Whether to show pattern analysis information
  final bool showAnalysis;

  /// Callback when the dialog is closed
  final VoidCallback? onClose;

  /// Callback when the pattern is saved
  final VoidCallback? onSave;

  /// Callback when the pattern is exported
  final Function(String)? onExport;

  /// The difficulty level of the pattern
  final PatternDifficulty difficulty;

  const PatternPopupPreview({
    Key? key,
    required this.blockCollection,
    this.showGrid = true,
    this.showCulturalContext = true,
    this.showAnalysis = true,
    this.onClose,
    this.onSave,
    this.onExport,
    this.difficulty = PatternDifficulty.basic,
  }) : super(key: key);

  @override
  State<PatternPopupPreview> createState() => _PatternPopupPreviewState();
}

class _PatternPopupPreviewState extends State<PatternPopupPreview> with SingleTickerProviderStateMixin {
  late PatternEngine _patternEngine;
  late PatternAnalyzerService _patternAnalyzer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<List<Color>> _generatedPattern = [];
  Map<String, dynamic> _analysisResults = {};
  String _selectedExportFormat = 'PNG';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _showColorPalette = false;
  bool _showSymbolism = false;

  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _patternEngine = PatternEngine();
    _patternAnalyzer = PatternAnalyzerService();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _initializeAndGeneratePattern();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Initialize the engines and generate the pattern
  Future<void> _initializeAndGeneratePattern() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Initialize the pattern engine if needed
      await _patternEngine.initialize();

      // Generate the pattern
      final pattern = _patternEngine.generatePatternFromBlocks(widget.blockCollection);
      final analysis = await _patternAnalyzer.analyzePattern(
        blocks: widget.blockCollection.blocks.map((block) => block.toJson()).toList(),
        difficulty: widget.difficulty,
      );

      setState(() {
        _generatedPattern = pattern;
        _analysisResults = analysis;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error generating pattern: $e';
      });
      debugPrint('Error generating pattern: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                        ? _buildErrorState()
                        : _buildPreviewContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header section with title and controls
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.kenteGold),
            const SizedBox(width: 8),
            Text(
              'Pattern Preview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Zoom controls
            if (!_isLoading && !_hasError) ...[
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _scale = (_scale - 0.1).clamp(0.5, 3.0);
                    _updateTransformation();
                  });
                },
                tooltip: 'Zoom out',
              ),
              Text(
                '${(_scale * 100).round()}%',
                style: const TextStyle(fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _scale = (_scale + 0.1).clamp(0.5, 3.0);
                    _updateTransformation();
                  });
                },
                tooltip: 'Zoom in',
              ),
              IconButton(
                icon: const Icon(Icons.fit_screen),
                onPressed: _resetTransformation,
                tooltip: 'Reset view',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.palette,
                  color: _showColorPalette ? AppTheme.kenteGold : Colors.grey,
                ),
                onPressed: () {
                  setState(() => _showColorPalette = !_showColorPalette);
                },
                tooltip: 'Show color palette',
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: _showSymbolism ? AppTheme.kenteGold : Colors.grey,
                ),
                onPressed: () {
                  setState(() => _showSymbolism = !_showSymbolism);
                },
                tooltip: 'Show symbolism',
              ),
            ],

            // Close button
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ],
        ),
      ],
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kenteGold),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating your pattern...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.kenteRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Generating Pattern',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.kenteRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeAndGeneratePattern,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build the main pattern preview area
  Widget _buildPreviewContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.5,
                      maxScale: 3.0,
                      onInteractionEnd: (_) {
                        final matrix = _transformationController.value;
                        setState(() {
                          _scale = matrix.getMaxScaleOnAxis();
                          _offset = Offset(
                            matrix.getTranslation().x,
                            matrix.getTranslation().y,
                          );
                        });
                      },
                      child: WeavingPatternRenderer(
                        patternGrid: _generatedPattern,
                        cellSize: 20.0,
                        showGrid: widget.showGrid,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showAnalysis)
                _buildAnalysisSection(),
            ],
          ),
        ),
        if (_showColorPalette || _showSymbolism)
          SizedBox(
            width: 250,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showColorPalette
                  ? _buildColorPalette()
                  : _buildSymbolismInfo(),
            ),
          ),
      ],
    );
  }

  /// Build the analysis section
  Widget _buildAnalysisSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Analysis',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAnalysisMetric(
                'Complexity',
                _analysisResults['complexity_score']?.toString() ?? 'N/A',
                Icons.analytics,
              ),
              _buildAnalysisMetric(
                'Blocks',
                _analysisResults['block_count']?.toString() ?? 'N/A',
                Icons.widgets,
              ),
              _buildAnalysisMetric(
                'Colors',
                _analysisResults['color_count']?.toString() ?? 'N/A',
                Icons.palette,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a single analysis metric
  Widget _buildAnalysisMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.kenteGold),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the cultural context panel
  Widget _buildCulturalContext() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_edu, size: 20, color: AppTheme.kenteGold),
                const SizedBox(width: 8),
                Text(
                  'Cultural Context',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: KenteCulturalCards.patternMeanings(
                  onLearnMore: () => _showDetailedCulturalInfo(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the analysis panel
  Widget _buildAnalysisPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 20, color: AppTheme.kenteGold),
                const SizedBox(width: 8),
                Text(
                  'Pattern Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _analysisResults.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: _buildAnalysisResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the analysis results display
  Widget _buildAnalysisResults() {
    // Extract metrics from analysis results
    final complexity = _analysisResults['complexity'] ?? 0.0;
    final colorVariety = _analysisResults['color_variety'] ?? 0.0;
    final symmetry = _analysisResults['symmetry'] ?? 0.0;
    final culturalScore = _analysisResults['cultural_score'] ?? 0.0;

    // Get suggestions
    final suggestions = (_analysisResults['suggestions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pattern metrics
        _buildMetricsRow(context, [
          _buildMetric('Complexity', complexity),
          _buildMetric('Color Variety', colorVariety),
        ]),
        const SizedBox(height: 12),
        _buildMetricsRow(context, [
          _buildMetric('Symmetry', symmetry),
          _buildMetric('Cultural Accuracy', culturalScore),
        ]),

        // Overall score
        if (complexity > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Overall Score:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildOverallScore((complexity + colorVariety + symmetry + culturalScore) / 4),
            ],
          ),
        ],

        // Suggestions
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Suggestions:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  /// Build a row of metrics
  Widget _buildMetricsRow(BuildContext context, List<Widget> metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: metrics,
    );
  }

  /// Build a single metric widget
  Widget _buildMetric(String label, double value) {
    final percentage = (value * 100).round();

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  value < 0.3 ? Colors.red :
                  value < 0.6 ? Colors.orange :
                  Colors.green,
                ),
                strokeWidth: 6,
              ),
              Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the overall score widget
  Widget _buildOverallScore(double score) {
    final rating = score < 0.3 ? 'Basic' :
    score < 0.5 ? 'Good' :
    score < 0.7 ? 'Great' :
    score < 0.9 ? 'Excellent' : 'Master';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: score < 0.3 ? Colors.red.shade100 :
        score < 0.5 ? Colors.orange.shade100 :
        score < 0.7 ? Colors.lime.shade100 :
        Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: score < 0.3 ? Colors.red :
          score < 0.5 ? Colors.orange :
          score < 0.7 ? Colors.lime :
          Colors.green,
        ),
      ),
      child: Text(
        rating,
        style: TextStyle(
          color: score < 0.3 ? Colors.red.shade900 :
          score < 0.5 ? Colors.orange.shade900 :
          score < 0.7 ? Colors.lime.shade900 :
          Colors.green.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Build the color palette
  Widget _buildColorPalette() {
    final uniqueColors = <Color>{};
    for (final row in _generatedPattern) {
      uniqueColors.addAll(row);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Palette',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: uniqueColors.map((color) {
                return Tooltip(
                  message: _getColorName(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the symbolism information
  Widget _buildSymbolismInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pattern Symbolism',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _analysisResults['cultural_significance'] ?? 'No symbolism information available.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed cultural information dialog
  void _showDetailedCulturalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kente Cultural Significance',
          style: TextStyle(color: Colors.black),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KenteCulturalCards.colorMeanings(),
                const SizedBox(height: 16),
                KenteCulturalCards.historicalContext(),
                const SizedBox(height: 16),
                KenteCulturalCards.modernSignificance(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Update the transformation controller with the current scale and offset
  void _updateTransformation() {
    final matrix = Matrix4.identity()
      ..scale(_scale)
      ..setTranslation(Vector3(_offset.dx, _offset.dy, 0.0));
    _transformationController.value = matrix;
  }

  /// Reset the transformation to default
  void _resetTransformation() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _transformationController.value = Matrix4.identity();
    });
  }

  String _getColorName(Color color) {
    if (color == AppTheme.kenteGold) return 'Gold';
    if (color == AppTheme.kenteRed) return 'Red';
    if (color == AppTheme.kenteGreen) return 'Green';
    if (color == AppTheme.kenteBlue) return 'Blue';
    return 'Custom Color';
  }
}

/// Painter for rendering the Kente pattern preview
class _PatternPreviewPainter extends CustomPainter {
  final List<List<Color>> pattern;
  final double cellSize;
  final bool showGrid;

  _PatternPreviewPainter({
    required this.pattern,
    required this.cellSize,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.grey.withOpacity(0.3);

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        // Draw cell
        paint.color = pattern[row][col];
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );

        canvas.drawRect(rect, paint);

        // Draw grid if enabled
        if (showGrid) {
          canvas.drawRect(rect, gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPreviewPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.showGrid != showGrid;
  }
}
