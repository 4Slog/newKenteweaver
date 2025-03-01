import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../services/gemini_service.dart';

class AIMentorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> blocks;
  final PatternDifficulty difficulty;
  final bool isVisible;
  final VoidCallback? onClose;

  const AIMentorWidget({
    super.key,
    required this.blocks,
    required this.difficulty,
    this.isVisible = true,
    this.onClose,
  });

  @override
  State<AIMentorWidget> createState() => _AIMentorWidgetState();
}

class _AIMentorWidgetState extends State<AIMentorWidget> {
  late GeminiService _geminiService;
  Map<String, dynamic>? _analysis;
  String? _currentHint;
  List<String> _previousHints = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    try {
      _geminiService = await GeminiService.initialize();
      _analyzePattern();
    } catch (e) {
      debugPrint('Error initializing Gemini: $e');
    }
  }

  Future<void> _analyzePattern() async {
    if (!mounted || !widget.isVisible) return;

    setState(() => _isLoading = true);

    try {
      final analysis = await _geminiService.analyzePattern(
        blocks: widget.blocks,
        difficulty: widget.difficulty,
      );

      final hint = await _geminiService.generateMentoringHint(
        blocks: widget.blocks,
        difficulty: widget.difficulty,
        previousHints: _previousHints,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _currentHint = hint;
          if (hint != null) {
            _previousHints = [..._previousHints, hint];
            if (_previousHints.length > 5) {
              _previousHints.removeAt(0);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error analyzing pattern: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didUpdateWidget(AIMentorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blocks != oldWidget.blocks || 
        widget.difficulty != oldWidget.difficulty) {
      _analyzePattern();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isExpanded ? 300 : 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isExpanded) _buildExpandedContent(),
            _buildHintSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.auto_awesome),
          ),
          title: const Text(
            'AI Mentor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analysis == null) {
      return const Center(child: Text('No analysis available'));
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisMetrics(),
            const Divider(),
            _buildSuggestions(),
            const Divider(),
            _buildCulturalSignificance(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisMetrics() {
    final complexity = _analysis?['complexity_score'] ?? 0.0;
    final cultural = _analysis?['cultural_accuracy'] ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric('Complexity', complexity),
        _buildMetric('Cultural Accuracy', cultural),
      ],
    );
  }

  Widget _buildMetric(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        CircularProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            value < 0.3 ? Colors.red :
            value < 0.7 ? Colors.orange :
            Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _analysis?['learning_suggestions'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggestions:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.arrow_right, size: 16),
              Expanded(child: Text(suggestion.toString())),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCulturalSignificance() {
    final significance = _analysis?['cultural_significance'] as String? ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cultural Significance:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(significance),
      ],
    );
  }

  Widget _buildHintSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentHint ?? 'No hint available',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzePattern,
          ),
        ],
      ),
    );
  }
}
