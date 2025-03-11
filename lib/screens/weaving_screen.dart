import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/cultural_context_card.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class WeavingScreen extends StatefulWidget {
  final PatternDifficulty difficulty;
  final BlockCollection? initialBlocks;
  final String title;
  final bool showTutorial;

  const WeavingScreen({
    super.key,
    this.difficulty = PatternDifficulty.basic,
    this.initialBlocks,
    this.title = 'Pattern Creation',
    this.showTutorial = false,
  });

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> with SingleTickerProviderStateMixin {
  late BlockCollection blockCollection;
  late AudioService _audioService;
  late AnimationController _controller;
  bool _showTutorialOverlay = false;
  bool _hasShownTutorial = false;
  int _tutorialStep = 0;
  final List<Map<String, String>> _tutorialSteps = [
    {
      'title': 'Welcome to Pattern Weaving',
      'content': 'Drag blocks from the left panel to create your pattern. Connect blocks to build more complex designs.',
    },
    {
      'title': 'Pattern Blocks',
      'content': 'These define the visual appearance of your pattern. Traditional Kente patterns include checker (Dame-Dame), zigzag (Nkyinkyim), and more.',
    },
    {
      'title': 'Color Blocks',
      'content': 'Add colors to your pattern. In Kente weaving, colors have cultural significance - black for maturity, gold for royalty, and red for sacrifice.',
    },
    {
      'title': 'Structure Blocks',
      'content': 'Use loops, rows, and columns to arrange your patterns. These are like the loom structure in traditional weaving.',
    },
    {
      'title': 'AI Mentor',
      'content': 'The AI mentor in the top right provides cultural context and pattern suggestions. Use it to learn more about Kente traditions.',
    },
  ];

  @override
  void initState() {
    super.initState();
    blockCollection = widget.initialBlocks ?? BlockCollection(blocks: []);
    _audioService = Provider.of<AudioService>(context, listen: false);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Play the appropriate music when the screen is loaded
    _audioService.playMusic(AudioType.learningTheme);

    // Show tutorial if needed
    _showTutorialOverlay = widget.showTutorial && !_hasShownTutorial;

    // Delay tutorial display to allow screen to build
    if (_showTutorialOverlay) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showTutorialOverlay = true;
        });
      });
    }
  }

  @override
  void dispose() {
    // Stop the music when the screen is disposed
    _audioService.stopAllMusic();
    _controller.dispose();
    super.dispose();
  }

  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      blockCollection = updatedBlocks;
    });
  }

  void _closeTutorial() {
    setState(() {
      _showTutorialOverlay = false;
      _hasShownTutorial = true;
      _tutorialStep = 0;
    });
  }

  void _nextTutorialStep() {
    if (_tutorialStep < _tutorialSteps.length - 1) {
      setState(() {
        _tutorialStep++;
      });
    } else {
      _closeTutorial();
    }
  }

  void _previousTutorialStep() {
    if (_tutorialStep > 0) {
      setState(() {
        _tutorialStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Help Button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Show tutorial',
            onPressed: () {
              setState(() {
                _showTutorialOverlay = true;
                _tutorialStep = 0;
              });
            },
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.settings);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          PatternCreationWorkspace(
            initialBlocks: blockCollection,
            difficulty: widget.difficulty,
            title: widget.title,
            breadcrumbs: [
              context.getHomeBreadcrumb(),
              BreadcrumbItem(
                label: 'Weaving',
                route: AppRouter.weaving,
                fallbackIcon: Icons.grid_on,
                iconAsset: 'assets/images/navigation/weaving_breadcrumb.png',
              ),
              BreadcrumbItem(
                label: widget.title,
                fallbackIcon: Icons.create,
              ),
            ],
            onPatternChanged: _handlePatternChanged,
            showAIMentor: true,
            showCulturalContext: true,
          ),

          // Tutorial overlay
          if (_showTutorialOverlay)
            _buildTutorialOverlay(),
        ],
      ),
      // Optional: Add a drawer for more navigation options
      drawer: _buildNavigationDrawer(),
    );
  }

  Widget _buildTutorialOverlay() {
    final currentStep = _tutorialSteps[_tutorialStep];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentStep['title']!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.kenteGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _closeTutorial,
                        ),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        currentStep['content']!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_tutorialStep > 0)
                          TextButton(
                            onPressed: _previousTutorialStep,
                            child: const Text('Previous'),
                          )
                        else
                          const SizedBox(width: 80),
                        Text('${_tutorialStep + 1}/${_tutorialSteps.length}'),
                        ElevatedButton(
                          onPressed: _nextTutorialStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kenteGold,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(_tutorialStep < _tutorialSteps.length - 1 ? 'Next' : 'Finish'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.kenteGold,
              image: DecorationImage(
                image: const AssetImage('assets/images/navigation/background_pattern.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppTheme.kenteGold.withOpacity(0.8),
                  BlendMode.dstATop,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Kente Code Weaver',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create beautiful patterns',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRouter.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('Patterns Gallery'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to patterns gallery when implemented
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Challenges'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.challenge);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Cultural Context'),
            onTap: () {
              Navigator.pop(context);
              _showCulturalContextDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Tutorial'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _showTutorialOverlay = true;
                _tutorialStep = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showCulturalContextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kente Cultural Significance',
          style: TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KenteCulturalCards.colorMeanings(),
              const SizedBox(height: 16),
              KenteCulturalCards.patternMeanings(
                onLearnMore: () {
                  Navigator.pop(context);
                  _showDetailedCulturalInfo(context);
                },
              ),
            ],
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

  void _showDetailedCulturalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kente Cultural Significance',
          style: TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
