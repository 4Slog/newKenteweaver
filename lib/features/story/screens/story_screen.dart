import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../models/story_model.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/story_dialog.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/cultural_context_card.dart';
import '../widgets/embedded_tutorial.dart';
import '../services/story_service.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/adaptive_learning_service.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/story_navigation_service.dart';
import '../widgets/story_content_display.dart';
import '../widgets/story_choice_panel.dart';
import '../widgets/character_avatar.dart';
import '../widgets/animated_background.dart';
import '../utils/screen_transitions.dart';
import '../services/story_engine_service.dart';
import '../models/audio_model.dart' as audio;

class StoryScreen extends StatefulWidget {
  final String nodeId;

  const StoryScreen({
    super.key,
    required this.nodeId,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<double> _textOpacity;
  bool _isChoicePanelVisible = false;
  StoryNode? _currentNode;

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _loadStoryNode();
  }
  
  @override
  void dispose() {
    _textAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryNode() async {
    final storyEngine = Provider.of<StoryEngineService>(context, listen: false);
    final node = await storyEngine.getNode(widget.nodeId);
      
      if (mounted) {
        setState(() {
        _currentNode = node;
        _textAnimationController.forward(from: 0.0);
      });

      final audioService = Provider.of<AudioService>(context, listen: false);
      if (node.backgroundMusic != null) {
        final audioType = audio.AudioType.values.firstWhere(
          (type) => type.filename == node.backgroundMusic,
          orElse: () => audio.AudioType.storyTheme,
        );
        audioService.playMusic(audioType);
      }
    }
  }

  void _showChoices(List<StoryChoice> choices) {
    setState(() => _isChoicePanelVisible = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StoryChoicePanel(
        choices: choices,
        onChoiceSelected: (choice) {
          setState(() => _isChoicePanelVisible = false);
          final navigation = Provider.of<StoryNavigationService>(
            context,
            listen: false,
          );
          navigation.handleChoice(choice);
        },
      ),
    ).then((_) {
        if (mounted) {
        setState(() => _isChoicePanelVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNode == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
      children: [
          AnimatedBackground(
            backgroundId: _currentNode!.backgroundId,
            enableParallax: !_isChoicePanelVisible,
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentNode!.characterId != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: CharacterAvatar(
                              characterId: _currentNode!.characterId!,
                              isAnimating: !_isChoicePanelVisible,
                            ),
                          ),
                        FadeTransition(
                          opacity: _textOpacity,
                          child: Text(
                            _currentNode!.content,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
            ),
          ),
        ],
                    ),
                  ),
                ),
                if (!_isChoicePanelVisible && _currentNode!.choices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () => _showChoices(_currentNode!.choices),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
