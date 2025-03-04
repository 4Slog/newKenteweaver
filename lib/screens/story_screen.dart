import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/story_dialog.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/cultural_context_card.dart';
import '../widgets/embedded_tutorial.dart';
import '../services/gemini_story_service.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/adaptive_learning_service.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';

class StoryScreen extends StatefulWidget {
  final LessonModel lesson;

  const StoryScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin {
  int _currentStoryStep = 0;
  bool _showingDialog = false;
  bool _isLoading = true;
  bool _inChallengeMode = false;
  bool _inTutorialMode = false;
  bool _showCulturalContext = false;
  bool _ttsEnabled = true;
  late GeminiStoryService _storyService;
  late TTSService _ttsService;
  List<Map<String, dynamic>> _storySteps = [];
  List<Map<String, dynamic>> _userChoices = [];
  BlockCollection? _challengeBlocks;
  Map<String, dynamic>? _currentChallenge;
  Map<String, dynamic>? _culturalContext;
  String? _currentTutorialId;
  List<String>? _tutorialSteps;
  late AnimationController _animationController;
  
  // Default image mappings for story steps
  final Map<String, String> _defaultImages = {
    'introduction': 'assets/images/characters/ananse_teaching.png',
    'challenge': 'assets/images/tutorial/basic_pattern_explanation.png',
    'pattern': 'assets/images/tutorial/loop_explanation.png',
    'cultural': 'assets/images/tutorial/color_meaning_diagram.png',
    'completion': 'assets/images/achievements/pattern_creator.png',
  };

  @override
  void initState() {
    super.initState();
    _initializeStory();
    _initializeAnimation();
    
    // Initialize TTS service
    _ttsService = TTSService();
    
    // Play story music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = Provider.of<AudioService>(context, listen: false);
      if (audioService.musicEnabled) {
        audioService.playMusic(AudioType.learningTheme);
      }
    });
  }
  
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    // Stop the music when the screen is disposed
    final audioService = Provider.of<AudioService>(context, listen: false);
    audioService.stopAllMusic();
    
    // Stop any ongoing TTS
    _ttsService.stop();
    
    // Dispose animation controller
    _animationController.dispose();
    
    // Cancel any pending operations
    super.dispose();
  }

  Future<void> _initializeStory() async {
    try {
      _storyService = await GeminiStoryService.getInstance();
      if (mounted) {
        await _loadStoryContent();
      }
    } catch (e) {
      debugPrint('Error initializing story: $e');
      // Use fallback story content
      _storySteps = _generateFallbackStory();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadStoryContent() async {
    if (!mounted) return;
    
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final language = languageProvider.currentLocale.languageCode;
    
    try {
      final storySteps = await _storyService.generateStorySteps(
        lesson: widget.lesson,
        language: language,
        stepsCount: 5,
        previousChoices: _userChoices.isNotEmpty ? _userChoices : null,
      );
      
      if (!mounted) return;
      
      // Process the story steps to ensure they have valid images
      final processedSteps = storySteps.map((step) {
        // Map suggested image descriptions to actual image assets
        final imagePath = _mapImageDescription(step['image'] as String? ?? '');
        
        // Extract any cultural context if present
        Map<String, dynamic>? culturalContext;
        if (step.containsKey('culturalContext') && step['culturalContext'] != null) {
          culturalContext = step['culturalContext'] as Map<String, dynamic>;
        }
        
        return {
          ...step,
          'image': imagePath,
          'culturalContext': culturalContext,
        };
      }).toList();
      
      if (mounted) {
        setState(() {
          _storySteps = processedSteps;
          _isLoading = false;
          
          // Set cultural context if available
          if (_storySteps.isNotEmpty && 
              _storySteps[_currentStoryStep].containsKey('culturalContext') &&
              _storySteps[_currentStoryStep]['culturalContext'] != null) {
            _culturalContext = _storySteps[_currentStoryStep]['culturalContext'];
          }
        });
        
        // Schedule the first dialog
        _scheduleNextDialog();
      }
    } catch (e) {
      debugPrint('Error loading story content: $e');
      // Use fallback story content
      _storySteps = _generateFallbackStory();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scheduleNextDialog();
      }
    }
  }
  
  String _mapImageDescription(String description) {
    // Map the image description to an actual image asset
    final lowerDesc = description.toLowerCase();
    
    if (lowerDesc.contains('ananse') || lowerDesc.contains('spider') || 
        lowerDesc.contains('introduction') || lowerDesc.contains('beginning')) {
      return _defaultImages['introduction']!;
    } else if (lowerDesc.contains('challenge') || lowerDesc.contains('task')) {
      return _defaultImages['challenge']!;
    } else if (lowerDesc.contains('pattern') || lowerDesc.contains('weaving')) {
      return _defaultImages['pattern']!;
    } else if (lowerDesc.contains('cultural') || lowerDesc.contains('meaning')) {
      return _defaultImages['cultural']!;
    } else if (lowerDesc.contains('complete') || lowerDesc.contains('finish')) {
      return _defaultImages['completion']!;
    }
    
    // Default image if no match
    return _defaultImages['introduction']!;
  }
  
  List<Map<String, dynamic>> _generateFallbackStory() {
    return [
      {
        'title': 'The Beginning',
        'content': 'Kwaku Ananse, the clever spider of Ghanaian folklore, has taken on a new role in the digital age. As a master weaver and coding expert, he has decided to teach the art of Kente weaving through code.',
        'image': _defaultImages['introduction']!,
        'contentBlocks': [
          {
            'type': 'narration',
            'text': 'Kwaku Ananse, the clever spider of Ghanaian folklore, has taken on a new role in the digital age. As a master weaver and coding expert, he has decided to teach the art of Kente weaving through code.',
          }
        ],
        'hasChoice': false,
        'speaker': 'narrator',
      },
      {
        'title': 'The Challenge',
        'content': 'Ananse presents you with your first challenge: to create a simple pattern using the basic weaving blocks. "Every great weaver starts with the fundamentals," he explains.',
        'image': _defaultImages['challenge']!,
        'contentBlocks': [
          {
            'type': 'narration',
            'text': 'Ananse presents you with your first challenge: to create a simple pattern using the basic weaving blocks.',
          },
          {
            'type': 'dialogue',
            'text': 'Every great weaver starts with the fundamentals.',
            'speaker': 'Kwaku',
          }
        ],
        'hasChoice': true,
        'choices': [
          {'text': 'Accept the challenge', 'nextStep': 2},
          {'text': 'Ask for more information', 'nextStep': 3},
        ],
        'speaker': 'Kwaku',
      },
      {
        'title': 'Your First Pattern',
        'content': 'You decide to accept Ananse\'s challenge. He shows you how to use the basic blocks to create a simple checker pattern, explaining how each block represents a piece of code.',
        'image': _defaultImages['pattern']!,
        'contentBlocks': [
          {
            'type': 'narration',
            'text': 'You decide to accept Ananse\'s challenge. He shows you how to use the basic blocks to create a simple checker pattern, explaining how each block represents a piece of code.',
          }
        ],
        'hasChoice': false,
        'challenge': {
          'title': 'Create a Checker Pattern',
          'description': 'Use the pattern blocks to create a simple Dame-Dame (checker) pattern.',
          'type': 'pattern_creation',
          'difficulty': 'basic',
        },
        'speaker': 'narrator',
      },
      {
        'title': 'Learning More',
        'content': 'Ananse explains that Kente patterns are not just beautiful designs but also carry deep cultural meanings. Each color and pattern tells a story about Ghanaian history and values.',
        'image': _defaultImages['cultural']!,
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'Kente patterns are not just beautiful designs but also carry deep cultural meanings. Each color and pattern tells a story about our history and values.',
            'speaker': 'Kwaku',
          }
        ],
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
          {'text': 'Learn about pattern meanings', 'nextStep': 4},
        ],
        'culturalContext': {
          'title': 'Dame-Dame Pattern',
          'description': 'The Dame-Dame (checker) pattern represents duality in Akan philosophy. It symbolizes the balance between opposites - like light and dark, joy and sorrow, the seen and unseen.',
          'imageAsset': 'assets/images/tutorial/color_meaning_diagram.png',
        },
        'speaker': 'Kwaku',
      },
      {
        'title': 'The Meaning of Patterns',
        'content': 'Ananse explains that the checker pattern (Dame-Dame) represents strategy and wisdom, while the zigzag pattern (Nkyinkyim) symbolizes life\'s journey and adaptability.',
        'image': _defaultImages['cultural']!,
        'contentBlocks': [
          {
            'type': 'dialogue',
            'text': 'The checker pattern we call Dame-Dame represents strategy and wisdom, while the zigzag pattern called Nkyinkyim symbolizes life\'s journey and adaptability.',
            'speaker': 'Kwaku',
          }
        ],
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
        ],
        'culturalContext': {
          'title': 'Pattern Meanings',
          'description': 'Kente patterns each convey specific meanings. Dame-Dame (checker) represents wisdom and strategy. Nkyinkyim (zigzag) symbolizes life\'s non-linear journey. Babadua (horizontal stripes) represents cooperation and unity.',
          'imageAsset': 'assets/images/tutorial/color_meaning_diagram.png',
        },
        'speaker': 'Kwaku',
      },
    ];
  }

  void _scheduleNextDialog() {
    if (_currentStoryStep < _storySteps.length && !_showingDialog && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showStoryDialog();
        }
      });
    }
  }

  void _showStoryDialog() {
    if (!mounted) return;
    
    setState(() {
      _showingDialog = true;
    });

    final step = _storySteps[_currentStoryStep];
    final isChallenge = step.containsKey('challenge') || 
                        (step['title'].toString().toLowerCase().contains('challenge'));
    
    // Update the cultural context if it exists for this step
    if (step.containsKey('culturalContext') && step['culturalContext'] != null) {
      setState(() {
        _culturalContext = step['culturalContext'];
      });
    } else {
      setState(() {
        _culturalContext = null;
      });
    }
    
    // Check if this step has a tutorial
    final hasTutorial = step.containsKey('hasTutorial') && step['hasTutorial'] == true;
    
    // Extract content blocks if they exist, otherwise create a default block
    List<Map<String, dynamic>> contentBlocks = [];
    if (step.containsKey('contentBlocks') && step['contentBlocks'] is List) {
      contentBlocks = List<Map<String, dynamic>>.from(step['contentBlocks'] as List);
    } else {
      // Create a default content block from the content field
      contentBlocks = [
        {
          'type': step.containsKey('speaker') ? 'dialogue' : 'narration',
          'text': step['content'],
          'speaker': step.containsKey('speaker') ? step['speaker'] : null,
        }
      ];
    }

    // Prepare choices based on step type
    List<Map<String, dynamic>> dialogChoices;
    
    if (hasTutorial) {
      // If this step has a tutorial, add a choice to start it
      dialogChoices = [
        {
          'text': 'Start Tutorial',
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              _handleTutorialStart(step);
            }
          },
        },
        {
          'text': 'Skip Tutorial',
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {
                _currentStoryStep++;
                _showingDialog = false;
              });
              _scheduleNextDialog();
            }
          },
        },
      ];
    } else if (isChallenge) {
      // Challenge choices
      dialogChoices = [
        {
          'text': 'Start Challenge',
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              _handleChallengeStart(step);
            }
          },
        },
        {
          'text': 'Skip for Now',
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {
                _currentStoryStep++;
                _showingDialog = false;
              });
              _scheduleNextDialog();
            }
          },
        },
      ];
    } else if (step['hasChoice'] as bool) {
      // Story choices
      dialogChoices = (step['choices'] as List<dynamic>).map((choice) {
        final choiceMap = choice as Map<String, dynamic>;
        return {
          'text': choiceMap['text'] as String,
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              // Record choice for adaptive story generation
              _userChoices.add({
                'stepId': step['title'],
                'choice': choiceMap['text'],
                'timestamp': DateTime.now().toIso8601String(),
              });
              
              setState(() {
                _currentStoryStep = choiceMap['nextStep'] as int;
                _showingDialog = false;
              });
              _scheduleNextDialog();
            }
          },
        };
      }).toList();
    } else {
      // Continue choice
      dialogChoices = [
        {
          'text': 'Continue',
          'onTap': () {
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {
                _currentStoryStep++;
                _showingDialog = false;
              });
              _scheduleNextDialog();
            }
          },
        },
      ];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StoryDialog(
        title: step['title'] as String,
        content: step['content'] as String,
        imagePath: step['image'] as String,
        contentBlocks: contentBlocks,
        hasChoices: true,
        ttsEnabled: _ttsEnabled,
        choices: dialogChoices,
      ),
    );
  }
  
  void _handleTutorialStart(Map<String, dynamic> storyStep) {
    // Get tutorial data from story step
    String tutorialId = storyStep['tutorialId'] as String? ?? 'basic_pattern_tutorial';
    List<String>? tutorialSteps;
    
    if (storyStep.containsKey('tutorialSteps') && storyStep['tutorialSteps'] is List) {
      tutorialSteps = List<String>.from(storyStep['tutorialSteps'] as List);
    }
    
    // Hide the dialog and enter tutorial mode
    setState(() {
      _showingDialog = false;
      _inTutorialMode = true;
      _currentTutorialId = tutorialId;
      _tutorialSteps = tutorialSteps;
    });
    
    // Play tutorial music if available
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.musicEnabled) {
      audioService.playMusic(AudioType.learningTheme);
    }
  }
  
  void _handleTutorialComplete() {
    // Record tutorial completion in adaptive learning service
    try {
      final adaptiveService = Provider.of<AdaptiveLearningService>(context, listen: false);
      
      // Record tutorial completion
      adaptiveService.recordInteraction(
        'tutorial_completed_in_story',
        _currentTutorialId ?? 'unknown_tutorial',
        data: {
          'story_id': widget.lesson.id,
          'story_step': _currentStoryStep,
        },
      );
      
      // Update concept mastery for basic concepts
      adaptiveService.updateConceptMastery('block_connection', 0.3);
      adaptiveService.updateConceptMastery('pattern_creation', 0.3);
      adaptiveService.updateConceptMastery('color_selection', 0.3);
    } catch (e) {
      debugPrint('Error recording tutorial completion: $e');
    }
    
    // Return to story mode
    setState(() {
      _inTutorialMode = false;
      _currentTutorialId = null;
      _tutorialSteps = null;
      
      // Check if the current step requires tutorial completion to proceed
      final step = _storySteps[_currentStoryStep];
      final requireTutorialCompletion = step.containsKey('requireTutorialCompletion') 
          ? step['requireTutorialCompletion'] as bool 
          : true;
      
      if (requireTutorialCompletion) {
        _currentStoryStep++;
      }
      
      _showingDialog = false;
    });
    
    // Play success sound
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.soundEnabled) {
      audioService.playSoundEffect(AudioType.success);
    }
    
    // Schedule next dialog
    _scheduleNextDialog();
  }
  
  void _handleChallengeStart(Map<String, dynamic> storyStep) {
    // Get challenge data from story step
    Map<String, dynamic> challengeData;
    if (storyStep.containsKey('challenge')) {
      challengeData = storyStep['challenge'] as Map<String, dynamic>;
    } else {
      // Create a default challenge if not explicitly defined
      challengeData = {
        'title': 'Pattern Challenge',
        'description': 'Create a pattern based on the story.',
        'type': 'pattern_creation',
        'difficulty': widget.lesson.difficulty.toString().split('.').last,
      };
    }
    
    // Hide the dialog and enter challenge mode
    setState(() {
      _showingDialog = false;
      _inChallengeMode = true;
      _currentChallenge = challengeData;
      _challengeBlocks = _createChallengeBlocks(challengeData);
    });
    
    // Play challenge music if available
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.musicEnabled) {
      audioService.playMusic(AudioType.challengeTheme);
    }
  }
  
  BlockCollection _createChallengeBlocks(Map<String, dynamic> challengeData) {
    // Create appropriate blocks based on the challenge type and difficulty
    final type = challengeData['type'] as String? ?? 'pattern_creation';
    final difficulty = _parseDifficulty(challengeData['difficulty'] as String? ?? 'basic');
    
    // Create blocks appropriate to the challenge
    List<Block> blocks = [];
    
    // Add pattern blocks based on difficulty
    if (difficulty == PatternDifficulty.basic) {
      // Basic patterns for beginners
      blocks.add(_createPatternBlock('checker_pattern', 'Dame-Dame Pattern'));
      blocks.add(_createPatternBlock('stripes_horizontal_pattern', 'Babadua Pattern'));
    } else if (difficulty == PatternDifficulty.intermediate) {
      // Add more complex patterns for intermediate
      blocks.add(_createPatternBlock('checker_pattern', 'Dame-Dame Pattern'));
      blocks.add(_createPatternBlock('zigzag_pattern', 'Nkyinkyim Pattern'));
      blocks.add(_createPatternBlock('stripes_vertical_pattern', 'Kubi Pattern'));
    } else {
      // Add advanced patterns
      blocks.add(_createPatternBlock('square_pattern', 'Eban Pattern'));
      blocks.add(_createPatternBlock('diamonds_pattern', 'Obaakofo Pattern'));
    }
    
    // Add color blocks
    blocks.add(_createColorBlock('shuttle_black', 'Black Thread', Colors.black));
    blocks.add(_createColorBlock('shuttle_gold', 'Gold Thread', const Color(0xFFFFD700)));
    blocks.add(_createColorBlock('shuttle_red', 'Red Thread', Colors.red));
    
    if (difficulty != PatternDifficulty.basic) {
      blocks.add(_createColorBlock('shuttle_blue', 'Blue Thread', Colors.blue));
      blocks.add(_createColorBlock('shuttle_green', 'Green Thread', Colors.green));
    }
    
    // Add structure blocks for intermediate and above
    if (difficulty != PatternDifficulty.basic) {
      blocks.add(_createStructureBlock('loop_block', 'Loop Block', 'Repeats the pattern'));
    }
    
    if (difficulty == PatternDifficulty.advanced || difficulty == PatternDifficulty.master) {
      blocks.add(_createStructureBlock('row_block', 'Row Block', 'Creates a row of patterns'));
      blocks.add(_createStructureBlock('column_block', 'Column Block', 'Creates a column of patterns'));
    }
    
    return BlockCollection(blocks: blocks);
  }
  
  Block _createPatternBlock(String id, String name) {
    return Block(
      id: id,
      name: name,
      description: 'A traditional Kente pattern',
      type: BlockType.pattern,
      subtype: id,
      properties: {'value': id.split('_')[0]},
      connections: [
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
      ],
      iconPath: 'assets/images/blocks/${id}.png',
      color: Colors.blue,
    );
  }
  
  Block _createColorBlock(String id, String name, Color color) {
    return Block(
      id: id,
      name: name,
      description: 'A traditional Kente color',
      type: BlockType.color,
      subtype: id,
      properties: {'color': color.value.toString()},
      connections: [
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
      ],
      iconPath: 'assets/images/blocks/${id}.png',
      color: color,
    );
  }
  
  Block _createStructureBlock(String id, String name, String description) {
    List<BlockConnection> connections = [];
    
    if (id == 'loop_block') {
      connections = [
        BlockConnection(
          id: '${id}_input',
          name: 'Input',
          type: ConnectionType.input,
          position: const Offset(0, 0.5),
        ),
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
        BlockConnection(
          id: '${id}_body',
          name: 'Body',
          type: ConnectionType.output,
          position: const Offset(0.5, 1),
        ),
      ];
    } else {
      connections = [
        BlockConnection(
          id: '${id}_input',
          name: 'Input',
          type: ConnectionType.input,
          position: const Offset(0, 0.5),
        ),
        BlockConnection(
          id: '${id}_output',
          name: 'Output',
          type: ConnectionType.output,
          position: const Offset(1, 0.5),
        ),
      ];
    }
    
    return Block(
      id: id,
      name: name,
      description: description,
      type: BlockType.structure,
      subtype: id,
      properties: {'value': '3'},
      connections: connections,
      iconPath: 'assets/images/blocks/${id.replaceAll('_block', '_icon')}.png',
      color: Colors.green,
    );
  }
  
  PatternDifficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        return PatternDifficulty.intermediate;
      case 'advanced':
        return PatternDifficulty.advanced;
      case 'master':
        return PatternDifficulty.master;
      case 'basic':
      default:
        return PatternDifficulty.basic;
    }
  }
  
  void _exitChallenge({bool completed = false, Map<String, dynamic>? results}) {
    // Return to story mode
    setState(() {
      _inChallengeMode = false;
    });
    
    // Record progress if challenge was completed
    if (completed && results != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Record any mastered concepts from this challenge
      if (results.containsKey('concepts_mastered') && results['concepts_mastered'] is List) {
        final conceptsMastered = List<String>.from(results['concepts_mastered'] as List);
        // Add any code to record mastered concepts here
      }
      
      // Progress to next step
      setState(() {
        _currentStoryStep++;
        _showingDialog = false;
      });
    }
    
    // Play success sound if completed
    if (completed) {
      final audioService = Provider.of<AudioService>(context, listen: false);
      if (audioService.soundEnabled) {
        audioService.playSoundEffect(AudioType.success);
      }
      
      // Switch back to story music
      if (audioService.musicEnabled) {
        audioService.playMusic(AudioType.learningTheme);
      }
    }
    
    // Schedule next dialog
    _scheduleNextDialog();
  }
  
  void _validateAndCompleteChallenge() {
    // In a real app, you would validate the challenge completion here
    // For now, we'll just consider it completed with dummy results
    _exitChallenge(
      completed: true, 
      results: {
        'score': 100,
        'time_taken': 120,
        'concepts_mastered': ['sequences', 'patterns', 'cultural_understanding'],
      }
    );
    
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _toggleCulturalContext() {
    setState(() {
      _showCulturalContext = !_showCulturalContext;
    });
  }
  
  void _toggleTTS() {
    setState(() {
      _ttsEnabled = !_ttsEnabled;
    });
    
    // Stop current narration if turning off
    if (!_ttsEnabled) {
      _ttsService.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          // TTS toggle
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: _ttsEnabled ? 'Disable narration' : 'Enable narration',
            onPressed: _toggleTTS,
          ),
          // Cultural context button, only show if available
          if (_culturalContext != null)
            IconButton(
              icon: Icon(_showCulturalContext ? Icons.info : Icons.info_outline),
              tooltip: _showCulturalContext ? 'Hide cultural context' : 'Show cultural context',
              onPressed: _toggleCulturalContext,
            ),
          // Exit challenge button when in challenge mode
          if (_inChallengeMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Challenge',
              onPressed: () => _exitChallenge(completed: false),
            ),
          // Exit tutorial button when in tutorial mode
          if (_inTutorialMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Tutorial',
              onPressed: _handleTutorialComplete,
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _inTutorialMode
              ? _buildTutorialView()
              : _inChallengeMode
                  ? _buildChallengeWorkspace()
                  : _buildStoryView(),
    );
  }
  
  Widget _buildStoryView() {
    return Column(
      children: [
        // Add breadcrumb navigation
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: BreadcrumbNavigation(
            items: [
              context.getHomeBreadcrumb(),
              context.getStoryBreadcrumb(arguments: {'lesson': widget.lesson}),
            ],
          ),
        ),
        
        // Cultural context card if enabled
        if (_showCulturalContext && _culturalContext != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CulturalContextCard(
              title: _culturalContext!['title'] as String,
              description: _culturalContext!['description'] as String,
              imageAsset: _culturalContext!.containsKey('imageAsset') ? _culturalContext!['imageAsset'] as String : null,
              expandable: true,
              initiallyExpanded: true,
            ),
          ),
        
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/story/background_pattern.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.8),
                  BlendMode.lighten,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Story Mode',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.kenteGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.lesson.description),
                  const SizedBox(height: 24),
                  
                  if (_storySteps.isNotEmpty) ...[
                    // Story progress
                    LinearProgressIndicator(
                      value: _storySteps.isEmpty ? 0 : _currentStoryStep / _storySteps.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kenteGold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Progress: ${_storySteps.isEmpty ? 0 : (_currentStoryStep * 100 ~/ _storySteps.length)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    
                    // Current story content preview
                    if (_currentStoryStep < _storySteps.length) ...[
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _storySteps[_currentStoryStep]['title'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _storySteps[_currentStoryStep]['content'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  _showingDialog = false;
                                  _scheduleNextDialog();
                                },
                                child: const Text('Continue Story'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Story controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentStoryStep > 0
                              ? () {
                                  setState(() {
                                    _currentStoryStep--;
                                    _showingDialog = false;
                                  });
                                  _scheduleNextDialog();
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _currentStoryStep < _storySteps.length - 1
                              ? () {
                                  setState(() {
                                    _currentStoryStep++;
                                    _showingDialog = false;
                                  });
                                  _scheduleNextDialog();
                                }
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Character image
                  Center(
                    child: Image.asset(
                      _currentStoryStep < _storySteps.length 
                          ? _storySteps[_currentStoryStep]['image'] as String
                          : 'assets/images/characters/ananse_teaching.png',
                      height: 200,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTutorialView() {
    return EmbeddedTutorial(
      tutorialId: _currentTutorialId ?? 'basic_pattern_tutorial',
      tutorialSteps: _tutorialSteps,
      onTutorialComplete: _handleTutorialComplete,
      showBreadcrumbs: true,
    );
  }
  
  Widget _buildChallengeWorkspace() {
    return Column(
      children: [
        // Challenge header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.kenteGold.withOpacity(0.2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentChallenge?['title'] ?? 'Pattern Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentChallenge?['description'] ?? 'Complete the pattern to continue the story',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _validateAndCompleteChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kenteGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
        
        // Challenge workspace
        Expanded(
          child: PatternCreationWorkspace(
            initialBlocks: _challengeBlocks ?? BlockCollection(blocks: []),
            difficulty: _currentChallenge != null 
                ? _parseDifficulty(_currentChallenge!['difficulty'].toString()) 
                : widget.lesson.difficulty,
            title: _currentChallenge?['title'] ?? 'Challenge Workspace',
            breadcrumbs: [
              context.getHomeBreadcrumb(),
              context.getStoryBreadcrumb(arguments: {'lesson': widget.lesson}),
              BreadcrumbItem(
                label: 'Challenge',
                fallbackIcon: Icons.extension,
                iconAsset: 'assets/images/navigation/challenge_breadcrumb.png',
              ),
            ],
            showAIMentor: true,
            showCulturalContext: true,
            onPatternChanged: (blocks) {
              setState(() {
                _challengeBlocks = blocks;
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kenteGold),
          ),
          const SizedBox(height: 24),
          Text(
            'Kwaku Ananse is weaving your story...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/characters/ananse_teaching.png',
            height: 150,
          ),
        ],
      ),
    );
  }
}
