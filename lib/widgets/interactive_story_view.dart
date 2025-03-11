import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/story_service.dart';
import '../models/pattern_difficulty.dart';
import '../models/story_model.dart';
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
  final StoryService _storyService = StoryService();
  late Future<StoryNode> _storyFuture;
  StoryNode? _currentStory;
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
    _storyFuture = _storyService.getNode(
      widget.patternType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoryNode>(
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
        if (_currentStory == null) {
          return const Center(child: Text('Story not available'));
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildStoryContent(_currentStory!),
                  _buildInteractiveElements(_currentStory!),
                ],
              ),
            ),
            if (_showingChoices && (_currentStory?.choices?.isNotEmpty ?? false))
              _buildChoices(_currentStory!.choices ?? []),
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
                children: (storyNode.contentBlocks ?? []).map((content) {
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

  Widget _buildContentBlock(ContentBlock content) {
    final text = content.text;

    switch (content.type) {
      case ContentType.narration:
        return Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge,
        );
      case ContentType.dialogue:
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
      case ContentType.description:
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

  Widget _buildInteractiveElements(StoryNode storyNode) {
    if (storyNode.challenge == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Challenge preview
        if (storyNode.challenge != null)
          _buildChallengePreview(storyNode.challenge!),
      ],
    );
  }

  Widget _buildChallengePreview(Challenge challenge) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: GestureDetector(
        onTap: () => _showCodingChallenge(challenge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                challenge.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
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
      final challenge = Challenge(
        id: choice.codingChallenge!['id'] as String? ?? 'challenge_${choice.id}',
        type: ChallengeType.values.firstWhere(
          (t) => t.toString() == 'ChallengeType.${choice.codingChallenge!['type'] ?? 'patternCreation'}',
          orElse: () => ChallengeType.patternCreation,
        ),
        title: choice.codingChallenge!['title'] as String? ?? 'Coding Challenge',
        description: choice.codingChallenge!['description'] as String? ?? '',
        hints: List<String>.from(choice.codingChallenge!['hints'] as List? ?? []),
        difficulty: PatternDifficulty.values.firstWhere(
          (d) => d.toString() == 'PatternDifficulty.${choice.codingChallenge!['difficulty'] ?? 'basic'}',
          orElse: () => PatternDifficulty.basic,
        ),
      );
      _showCodingChallenge(challenge);
    } else {
      _loadStory();
    }
  }

  void _showCodingChallenge(Challenge challenge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(challenge.title),
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
              ...challenge.hints.map(
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
