import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/interactive_story_service.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';

class InteractiveStoryView extends StatefulWidget {
  final String patternType;
  final List<String> colors;
  final PatternDifficulty difficulty;
  final String preferredLanguage;
  final Map<String, dynamic>? userProgress;
  final Function(StoryChoice) onChoiceSelected;
  final Function(Map<String, dynamic>) onChallengeCompleted;

  const InteractiveStoryView({
    super.key,
    required this.patternType,
    required this.colors,
    required this.difficulty,
    required this.preferredLanguage,
    this.userProgress,
    required this.onChoiceSelected,
    required this.onChallengeCompleted,
  });

  @override
  State<InteractiveStoryView> createState() => _InteractiveStoryViewState();
}

class _InteractiveStoryViewState extends State<InteractiveStoryView> with SingleTickerProviderStateMixin {
  final InteractiveStoryService _storyService = InteractiveStoryService();
  late Future<Map<String, dynamic>> _storyFuture;
  Map<String, dynamic>? _currentStory;
  Map<String, dynamic>? _previousChoices;
  late AnimationController _animationController;
  bool _showingChoices = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadStory();
  }

  void _loadStory() {
    _storyFuture = _storyService.generateInteractiveStory(
      patternType: widget.patternType,
      colors: widget.colors,
      difficulty: widget.difficulty,
      preferredLanguage: widget.preferredLanguage,
      userProgress: widget.userProgress,
      previousChoices: _previousChoices,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _storyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading story: ${snapshot.error}'),
          );
        }

        _currentStory = snapshot.data;
        final storyNode = _currentStory?['story_node'] as StoryNode?;
        if (storyNode == null) {
          return const Center(child: Text('Story not available'));
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildStoryContent(storyNode),
                  _buildInteractiveElements(_currentStory!),
                ],
              ),
            ),
            if (_showingChoices)
              _buildChoices(storyNode.choices),
          ],
        );
      },
    );
  }

  Widget _buildStoryContent(StoryNode storyNode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storyNode.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.kenteGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: storyNode.content.map((content) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildContentBlock(content),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock(Map<String, String> content) {
    final type = content['type'];
    final text = content['text'] ?? '';

    switch (type) {
      case 'scene':
        return Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        );
      case 'dialogue':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      case 'action':
        return Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[700],
          ),
        );
      default:
        return Text(text);
    }
  }

  Widget _buildInteractiveElements(Map<String, dynamic> story) {
    final elements = story['interactive_elements'] as Map<String, dynamic>?;
    if (elements == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Animations
        if (elements['animations'] != null)
          ..._buildAnimations(elements['animations'] as Map<String, String>),

        // Clickable elements
        if (elements['clickable_elements'] != null)
          ..._buildClickableElements(
            elements['clickable_elements'] as List<Map<String, dynamic>>,
          ),
      ],
    );
  }

  List<Widget> _buildAnimations(Map<String, String> animations) {
    return animations.entries.map((entry) {
      return Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Lottie.asset(
          entry.value,
          controller: _animationController,
          onLoaded: (composition) {
            _animationController
              ..duration = composition.duration
              ..forward();
          },
        ),
      );
    }).toList();
  }

  List<Widget> _buildClickableElements(List<Map<String, dynamic>> elements) {
    return elements.map((element) {
      final position = element['position'] as Map<String, dynamic>;
      return Positioned(
        left: MediaQuery.of(context).size.width * (position['x'] as double),
        top: MediaQuery.of(context).size.height * (position['y'] as double),
        child: GestureDetector(
          onTap: () => _handleElementClick(element),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getElementIcon(element['type'] as String),
                size: 32,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _getElementIcon(String type) {
    switch (type) {
      case 'code_preview':
        return Icons.code;
      case 'pattern_preview':
        return Icons.palette;
      default:
        return Icons.touch_app;
    }
  }

  void _handleElementClick(Map<String, dynamic> element) {
    // Handle interactive element clicks
    switch (element['type']) {
      case 'code_preview':
        _showCodePreview();
        break;
      case 'pattern_preview':
        _showPatternPreview();
        break;
    }
  }

  void _showCodePreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Preview'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '// Code preview will be shown here\n'
            'function generatePattern() {\n'
            '  // Pattern generation code\n'
            '}',
            style: TextStyle(
              color: Colors.green,
              fontFamily: 'monospace',
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

  void _showPatternPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pattern Preview'),
        content: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Pattern preview will be shown here'),
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

  Widget _buildChoices(List<StoryChoice> choices) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: choices.map((choice) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => _handleChoice(choice),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(choice.text),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleChoice(StoryChoice choice) {
    setState(() {
      _previousChoices = {
        ...?_previousChoices,
        'last_choice': choice.id,
        ...choice.consequences,
      };
      _showingChoices = false;
    });

    widget.onChoiceSelected(choice);

    if (choice.codingChallenge != null) {
      _showCodingChallenge(choice.codingChallenge!);
    } else {
      _loadStory();
    }
  }

  void _showCodingChallenge(Map<String, dynamic> challenge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(challenge['description'] as String),
        content: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hints:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...(challenge['hints'] as List<String>).map(
                (hint) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(hint)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Challenge interface will be implemented here',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onChallengeCompleted({
                'success': true,
                'score': 100,
                'time_taken': 300,
              });
              _loadStory();
            },
            child: const Text('Complete Challenge'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
