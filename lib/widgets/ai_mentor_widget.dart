import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

/// An AI-powered mentor widget that provides contextual guidance for pattern creation.
///
/// This widget analyzes the user's pattern and provides real-time feedback,
/// suggestions, and cultural context based on the current difficulty level.
class AIMentorWidget extends StatefulWidget {
  /// The current blocks in the workspace
  final List<Map<String, dynamic>> blocks;

  /// The current difficulty level
  final PatternDifficulty difficulty;

  /// Whether the mentor widget is visible
  final bool isVisible;

  /// Callback when the widget is closed
  final VoidCallback? onClose;

  /// The character to use for the mentor (defaults to "Kwaku Ananse")
  final String mentorCharacter;

  const AIMentorWidget({
    super.key,
    required this.blocks,
    required this.difficulty,
    this.isVisible = true,
    this.onClose,
    this.mentorCharacter = "Kwaku Ananse",
  });

  @override
  State<AIMentorWidget> createState() => _AIMentorWidgetState();
}

class _AIMentorWidgetState extends State<AIMentorWidget> with SingleTickerProviderStateMixin {
  late GeminiService _geminiService;
  Map<String, dynamic>? _analysis;
  String? _currentHint;
  List<String> _previousHints = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _isFirstLoad = true;
  bool _hasError = false;

  // Animation for character
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  // Cooldown for analysis to prevent too frequent updates
  DateTime _lastAnalysisTime = DateTime.now().subtract(const Duration(seconds: 10));

  // Character speaking states
  bool _isSpeaking = false;
  final List<String> _characterExpressions = [
    'neutral',
    'thinking',
    'excited',
    'concerned',
  ];
  String _currentExpression = 'neutral';

  @override
  void initState() {
    super.initState();
    _initializeGemini();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticInOut,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  Future<void> _initializeGemini() async {
    try {
      _geminiService = await GeminiService.initialize();
      _analyzePattern();
    } catch (e) {
      setState(() {
        _hasError = true;
        _currentHint = "I'm having trouble connecting to my knowledge base. Try again later.";
      });
      debugPrint('Error initializing Gemini: $e');
    }
  }

  @override
  void didUpdateWidget(AIMentorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if blocks or difficulty changed and enough time has passed since last analysis
    if ((widget.blocks != oldWidget.blocks ||
        widget.difficulty != oldWidget.difficulty) &&
        DateTime.now().difference(_lastAnalysisTime).inSeconds > 3) {
      _analyzePattern();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _analyzePattern() async {
    if (!mounted || !widget.isVisible) return;

    // Update last analysis time
    _lastAnalysisTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isSpeaking = true;
      _currentExpression = 'thinking';
    });

    // Start animation
    _animationController.reset();
    _animationController.forward();

    try {
      // Delay to prevent too frequent updates and show animation
      if (_isFirstLoad) {
        await Future.delayed(const Duration(milliseconds: 1500));
        _isFirstLoad = false;
      }

      final analysis = await _geminiService.analyzePattern(
        blocks: widget.blocks,
        difficulty: widget.difficulty,
      );

      String hint;
      if (widget.blocks.isEmpty) {
        hint = _getEmptyWorkspaceHint();
      } else {
        hint = await _geminiService.generateMentoringHint(
          blocks: widget.blocks,
          difficulty: widget.difficulty,
          previousHints: _previousHints,
        );
      }

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _currentHint = hint;
          _isLoading = false;
          _isSpeaking = true;
          _currentExpression = _getExpressionForHint(hint);

          if (hint.isNotEmpty) {
            _previousHints.add(hint);
            if (_previousHints.length > 5) {
              _previousHints.removeAt(0);
            }
          }
        });

        // Start animation again for new hint
        _animationController.reset();
        _animationController.forward();

        // Reset speaking state after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _currentExpression = 'neutral';
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error analyzing pattern: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _currentHint = "I'm having trouble analyzing your pattern right now. Try again in a moment.";
          _currentExpression = 'concerned';
        });
      }
    }
  }

  String _getEmptyWorkspaceHint() {
    final emptyWorkspaceHints = [
      "Welcome! Start creating your pattern by adding blocks from the toolbox.",
      "Drag pattern blocks from the toolbox to begin your Kente design.",
      "Traditional Kente patterns start with base colors and patterns.",
      "Try starting with a pattern block and then add some color blocks.",
    ];

    return emptyWorkspaceHints[DateTime.now().second % emptyWorkspaceHints.length];
  }

  String _getExpressionForHint(String hint) {
    if (hint.contains('great') ||
        hint.contains('excellent') ||
        hint.contains('good job')) {
      return 'excited';
    } else if (hint.contains('try') ||
        hint.contains('consider') ||
        hint.contains('improve')) {
      return 'thinking';
    } else if (hint.contains('error') ||
        hint.contains('problem') ||
        hint.contains('careful')) {
      return 'concerned';
    }
    return 'neutral';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isExpanded ? 300 : null, // Remove fixed height for non-expanded state
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
            leading: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _isSpeaking ? _bounceAnimation.value : 0),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.kenteGold.withOpacity(0.2),
                    child: Image.asset(
                      'assets/images/characters/ananse.png',
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.auto_awesome);
                      },
                    ),
                  ),
                );
              },
            ),
            title: Text(
              widget.mentorCharacter,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'AI Mentor - ${widget.difficulty.displayName} Level',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getDifficultyColor(widget.difficulty, context),
              ),
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    tooltip: _isExpanded ? 'Show less' : 'Show more',
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                      tooltip: 'Close mentor',
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your pattern...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text('Unable to analyze pattern'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _analyzePattern,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kenteGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
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
    final complexity = _analysis?['complexity_score'] as double? ?? 0.0;
    final cultural = _analysis?['cultural_accuracy'] as double? ?? 0.0;

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
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  value < 0.3 ? Colors.red :
                  value < 0.7 ? Colors.orange :
                  Colors.green,
                ),
                strokeWidth: 5,
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ],
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_right, size: 16),
              Expanded(child: Text(suggestion.toString(), style: const TextStyle(fontSize: 12))),
            ],
          ),
        )),
        if (suggestions.isEmpty)
          const Text(
            'Add more blocks to get personalized suggestions',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
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
        Text(
          significance.isNotEmpty
              ? significance
              : 'Add traditional patterns to see their cultural significance',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHintSection() {
    if (_isLoading && _currentHint == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: _isExpanded
          ? null
          : BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.kenteGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentHint ?? 'Add blocks to get guidance from your AI mentor.',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _analyzePattern,
            tooltip: 'Get new hint',
          ),
        ],
      ),
    );
  }
}
