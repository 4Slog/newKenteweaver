import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/story_engine_service.dart';
import '../services/story_navigation_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/story_content_display.dart';
import '../widgets/story_choice_panel.dart';
import '../widgets/character_avatar.dart';
import '../models/story_model.dart';
import '../models/audio_model.dart' as audio;

class IntroductionStoryScreen extends StatefulWidget {
  const IntroductionStoryScreen({super.key});

  @override
  State<IntroductionStoryScreen> createState() => _IntroductionStoryScreenState();
}

class _IntroductionStoryScreenState extends State<IntroductionStoryScreen> with TickerProviderStateMixin {
  late AnimationController _contentAnimationController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  StoryNode? _currentNode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialNode();
  }

  void _setupAnimations() {
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
  }

  Future<void> _loadInitialNode() async {
    try {
      final navigation = Provider.of<StoryNavigationService>(context, listen: false);
      final storyEngine = Provider.of<StoryEngineService>(context, listen: false);
      
      final nodeId = navigation.currentNodeId ?? 'intro_start';
      final node = await storyEngine.getNode(nodeId);
      
      if (mounted) {
        setState(() {
          _currentNode = node;
          _isLoading = false;
        });
        _contentAnimationController.forward();
      }

      // Play background music if specified
      if (node.backgroundMusic != null) {
        final audioService = Provider.of<AudioService>(context, listen: false);
        final audioType = audio.AudioType.values.firstWhere(
          (type) => type.filename == node.backgroundMusic,
          orElse: () => audio.AudioType.storyTheme,
        );
        await audioService.playMusic(audioType);
      }
    } catch (e) {
      debugPrint('Error loading initial node: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleChoice(StoryChoice choice) async {
    final navigation = Provider.of<StoryNavigationService>(context, listen: false);
    await navigation.handleChoice(choice);
    
    if (!mounted) return;
    
    // If this is the last node of the introduction, navigate to the main story screen
    if (choice.nextNodeId.startsWith('main_story')) {
      Navigator.pushReplacementNamed(context, '/story');
    } else {
      _contentAnimationController.reverse().then((_) {
        _loadInitialNode();
      });
    }
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(
            backgroundId: 'intro_background',
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_currentNode != null)
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_currentNode!.characterId != null)
                            CharacterAvatar(
                              characterId: _currentNode!.characterId!,
                              size: 120,
                            ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _contentOpacity,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: StoryContentDisplay(
                                contentBlocks: [
                                  {
                                    'type': 'dialogue',
                                    'text': _currentNode!.content,
                                    'speaker': _currentNode!.characterId ?? 'narrator',
                                  }
                                ],
                                enableTTS: true,
                                autoAdvance: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_currentNode!.choices.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: StoryChoicePanel(
                        choices: _currentNode!.choices,
                        onChoiceSelected: _handleChoice,
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