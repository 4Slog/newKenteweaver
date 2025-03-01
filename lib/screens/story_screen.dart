import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../widgets/story_dialog.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../services/gemini_story_service.dart';
import '../services/audio_service.dart';
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

class _StoryScreenState extends State<StoryScreen> {
  int _currentStoryStep = 0;
  bool _showingDialog = false;
  bool _isLoading = true;
  bool _inChallengeMode = false;
  late GeminiStoryService _storyService;
  List<Map<String, dynamic>> _storySteps = [];
  BlockCollection? _challengeBlocks;
  Map<String, dynamic>? _currentChallenge;
  
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
    
    // Play story music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = Provider.of<AudioService>(context, listen: false);
      if (audioService.musicEnabled) {
        audioService.playMusic(AudioType.learningTheme);
      }
    });
  }
  
  @override
  void dispose() {
    // Stop the music when the screen is disposed
    final audioService = Provider.of<AudioService>(context, listen: false);
    audioService.stopAllMusic();
    
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
      print('Error initializing story: $e');
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
      );
      
      if (!mounted) return;
      
      // Process the story steps to ensure they have valid images
      final processedSteps = storySteps.map((step) {
        // Map suggested image descriptions to actual image assets
        final imagePath = _mapImageDescription(step['image'] as String? ?? '');
        
        return {
          ...step,
          'image': imagePath,
        };
      }).toList();
      
      if (mounted) {
        setState(() {
          _storySteps = processedSteps;
          _isLoading = false;
        });
        
        // Schedule the first dialog
        _scheduleNextDialog();
      }
    } catch (e) {
      print('Error loading story content: $e');
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
        'hasChoice': false,
      },
      {
        'title': 'The Challenge',
        'content': 'Ananse presents you with your first challenge: to create a simple pattern using the basic weaving blocks. "Every great weaver starts with the fundamentals," he explains.',
        'image': _defaultImages['challenge']!,
        'hasChoice': true,
        'choices': [
          {'text': 'Accept the challenge', 'nextStep': 2},
          {'text': 'Ask for more information', 'nextStep': 3},
        ],
      },
      {
        'title': 'Your First Pattern',
        'content': 'You decide to accept Ananse\'s challenge. He shows you how to use the basic blocks to create a simple checker pattern, explaining how each block represents a piece of code.',
        'image': _defaultImages['pattern']!,
        'hasChoice': false,
      },
      {
        'title': 'Learning More',
        'content': 'Ananse explains that Kente patterns are not just beautiful designs but also carry deep cultural meanings. Each color and pattern tells a story about Ghanaian history and values.',
        'image': _defaultImages['cultural']!,
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
          {'text': 'Learn about pattern meanings', 'nextStep': 4},
        ],
      },
      {
        'title': 'The Meaning of Patterns',
        'content': 'Ananse explains that the checker pattern (Dame-Dame) represents strategy and wisdom, while the zigzag pattern (Nkyinkyim) symbolizes life\'s journey and adaptability.',
        'image': _defaultImages['cultural']!,
        'hasChoice': true,
        'choices': [
          {'text': 'Start creating your pattern', 'nextStep': 2},
        ],
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
    final isChallenge = step['title'].toString().toLowerCase().contains('challenge');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StoryDialog(
        title: step['title'] as String,
        content: step['content'] as String,
        imagePath: step['image'] as String,
        hasChoices: step['hasChoice'] as bool,
        choices: isChallenge 
            ? [
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
              ]
            : step['hasChoice'] 
                ? (step['choices'] as List<dynamic>).map((choice) {
                    final choiceMap = choice as Map<String, dynamic>;
                    return {
                      'text': choiceMap['text'] as String,
                      'onTap': () {
                        Navigator.of(context).pop();
                        if (mounted) {
                          setState(() {
                            _currentStoryStep = choiceMap['nextStep'] as int;
                            _showingDialog = false;
                          });
                          _scheduleNextDialog();
                        }
                      },
                    };
                  }).toList()
                : [
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
                  ],
      ),
    );
  }
  
  void _handleChallengeStart(Map<String, dynamic> challengeData) {
    // Hide the dialog and enter challenge mode
    setState(() {
      _showingDialog = false;
      _inChallengeMode = true;
      _currentChallenge = challengeData;
      _challengeBlocks = _createChallengeBlocks();
    });
  }
  
  BlockCollection _createChallengeBlocks() {
    // Create sample blocks for the challenge
    final blocks = <Block>[
      Block(
        id: 'pattern_block',
        name: 'Basic Pattern',
        description: 'Create a pattern',
        type: BlockType.pattern,
        subtype: 'checker_pattern',
        properties: {'value': 'basic'},
        connections: [
          BlockConnection(
            id: 'pattern_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
        ],
        iconPath: 'assets/images/blocks/pattern_icon.png',
        color: Colors.blue,
      ),
      Block(
        id: 'color_block',
        name: 'Color Selection',
        description: 'Choose colors for your pattern',
        type: BlockType.color,
        subtype: 'color_block',
        properties: {'value': '#FFD700'}, // Gold color
        connections: [
          BlockConnection(
            id: 'color_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
        ],
        iconPath: 'assets/images/blocks/color_icon.png',
        color: const Color(0xFFFFD700), // Gold color
      ),
    ];
    
    return BlockCollection(blocks: blocks);
  }
  
  void _exitChallenge({bool completed = false}) {
    setState(() {
      _inChallengeMode = false;
      if (completed) {
        _currentStoryStep++; // Progress to next step
      }
      _showingDialog = false;
    });
    
    _scheduleNextDialog();
  }
  
  void _validateAndCompleteChallenge() {
    // In a real app, you would validate the challenge completion here
    // For now, we'll just consider it completed
    _exitChallenge(completed: true);
    
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: _inChallengeMode ? [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Exit Challenge',
            onPressed: () => _exitChallenge(completed: false),
          ),
        ] : null,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _inChallengeMode
              ? _buildChallengeWorkspace()
              : Column(
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
                                  'assets/images/characters/ananse_teaching.png',
                                  height: 200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      _currentChallenge?['title'] ?? 'Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete the pattern to continue the story',
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
            difficulty: widget.lesson.difficulty,
            title: 'Challenge Workspace',
            breadcrumbs: [
              context.getHomeBreadcrumb(),
              context.getStoryBreadcrumb(arguments: {'lesson': widget.lesson}),
              BreadcrumbItem(
                label: 'Challenge',
                fallbackIcon: Icons.extension,
                iconAsset: 'assets/images/navigation/challenge_breadcrumb.png',
              ),
            ],
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
