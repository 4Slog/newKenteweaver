import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../services/unified/pattern_engine.dart';
import '../services/pattern_analyzer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cultural_context_card.dart';

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

class _PatternPopupPreviewState extends State<PatternPopupPreview> {
  late PatternEngine _patternEngine;
  late PatternAnalyzerService _patternAnalyzer;

  List<List<Color>> _generatedPattern = [];
  Map<String, dynamic> _analysisResults = {};

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // View controls
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  final TransformationController _transformationController = TransformationController();

  // Export options
  String _selectedExportFormat = 'PNG';
  final List<String> _exportFormats = ['PNG', 'SVG', 'JSON'];

  @override
  void initState() {
    super.initState();
    _patternEngine = PatternEngine();
    _patternAnalyzer = PatternAnalyzerService();

    _initializeAndGeneratePattern();
  }

  @override
  void dispose() {
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

      // Analyze the pattern
      final analysis = await _patternAnalyzer.analyzePattern(
        blocks: widget.blockCollection.toLegacyBlocks(),
        difficulty: widget.difficulty,
      );

      setState(() {
        _generatedPattern = pattern;
        _analysisResults = analysis;
        _isLoading = false;
      });
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const Divider(),

            // Main content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : _buildPatternPreview(),
            ),

            // Action buttons
            _buildActionButtons(context),
          ],
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
          const CircularProgressIndicator(color: AppTheme.kenteGold),
          const SizedBox(height: 24),
          Text(
            'Generating your Kente pattern...',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Text(
            'Applying traditional weaving techniques',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 24),
          Text(
            'Unable to generate pattern',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeAndGeneratePattern,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kenteGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build the main pattern preview area
  Widget _buildPatternPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pattern visualization
        Expanded(
          flex: 3,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                child: Center(
                  child: CustomPaint(
                    painter: _PatternPreviewPainter(
                      pattern: _generatedPattern,
                      cellSize: 20.0,
                      showGrid: widget.showGrid,
                    ),
                    size: Size(
                      _generatedPattern[0].length * 20.0,
                      _generatedPattern.length * 20.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bottom section: Cultural context and analysis
        if (widget.showCulturalContext || widget.showAnalysis)
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cultural context panel
                if (widget.showCulturalContext)
                  Expanded(
                    child: _buildCulturalContext(),
                  ),

                // Analysis panel
                if (widget.showAnalysis) ...[
                  if (widget.showCulturalContext)
                    const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnalysisPanel(),
                  ),
                ],
              ],
            ),
          ),
      ],
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

  /// Build the action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Export options
          if (!_isLoading && !_hasError)
            _buildExportOptions(context),

          // Main action buttons
          Row(
            children: [
              TextButton(
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              if (!_isLoading && !_hasError && widget.onSave != null)
                ElevatedButton(
                  onPressed: widget.onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kenteGold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save Pattern'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build export options dropdown
  Widget _buildExportOptions(BuildContext context) {
    return Row(
      children: [
        const Text('Export as:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedExportFormat,
          items: _exportFormats.map((format) => DropdownMenuItem<String>(
            value: format,
            child: Text(format),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedExportFormat = value;
              });
            }
          },
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: widget.onExport != null
              ? () => widget.onExport!(_selectedExportFormat)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
          ),
          child: const Text('Export'),
        ),
      ],
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
    final updatedMatrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
    _transformationController.value = updatedMatrix;
  }

  /// Reset the transformation to default
  void _resetTransformation() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _transformationController.value = Matrix4.identity();
    });
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