import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../models/block_model.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/interactive_tutorial_step.dart';
import '../navigation/app_router.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../extensions/breadcrumb_extensions.dart';
import 'package:provider/provider.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late BlockCollection tutorialBlocks;
  int _currentStep = 0;
  bool _tutorialCompleted = false;
  
  @override
  void initState() {
    super.initState();
    tutorialBlocks = _createTutorialBlocks();
    
    // Play tutorial music
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
    super.dispose();
  }
  
  BlockCollection _createTutorialBlocks() {
    // Create sample blocks for the tutorial
    final blocks = <Block>[
      Block(
        id: 'pattern_block',
        name: 'Basic Pattern',
        description: 'Learn basic pattern creation',
        type: BlockType.pattern,
        subtype: 'checker_pattern',
        properties: {
          'pattern': 'checker_pattern',
          'colors': ['#000000', '#FF0000', '#FFD700'],
        },
        connections: [
          BlockConnection(
            id: 'pattern_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
        ],
        iconPath: 'assets/images/blocks/checker_pattern.png',
        colorHex: '#3498db',
      ),
      Block(
        id: 'color_block',
        name: 'Gold Thread',
        description: 'Represents wealth and royalty',
        type: BlockType.color,
        subtype: 'shuttle_gold',
        properties: {'color': AppTheme.kenteGold.value.toString()},
        connections: [
          BlockConnection(
            id: 'color_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
        ],
        iconPath: 'assets/images/blocks/shuttle_gold.png',
        colorHex: '#${AppTheme.kenteGold.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      ),
      Block(
        id: 'loop_block',
        name: 'Pattern Repetition',
        description: 'Repeat patterns multiple times',
        type: BlockType.structure,
        subtype: 'loop_block',
        properties: {'value': '3'},
        connections: [
          BlockConnection(
            id: 'loop_block_input',
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 0.5),
          ),
          BlockConnection(
            id: 'loop_block_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
          BlockConnection(
            id: 'loop_block_body',
            name: 'Body',
            type: ConnectionType.output,
            position: const Offset(0.5, 1),
          ),
        ],
        iconPath: 'assets/images/blocks/loop_icon.png',
        colorHex: '#2ecc71',
      ),
    ];
    
    return BlockCollection(blocks: blocks);
  }
  
  void _handleNextStep() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.soundEnabled) {
      audioService.playSoundEffect(AudioType.navigationTap);
    }
    
    setState(() {
      if (_currentStep < 4) {
        _currentStep++;
      } else {
        _tutorialCompleted = true;
      }
    });
  }
  
  void _handlePreviousStep() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.soundEnabled) {
      audioService.playSoundEffect(AudioType.buttonTap);
    }
    
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }
  
  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      tutorialBlocks = updatedBlocks;
    });
  }
  
  void _finishTutorial() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.soundEnabled) {
      audioService.playSoundEffect(AudioType.confirmationTap);
    }
    
    // Navigate to the learning hub
    Navigator.pushReplacementNamed(context, AppRouter.learningHub);
  }

  @override
  Widget build(BuildContext context) {
    if (_tutorialCompleted) {
      return _buildCompletionScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tutorial Help'),
                  content: const Text(
                    'This tutorial will guide you through creating your first Kente pattern. '
                    'Follow the instructions and use the Continue button to move to the next step. '
                    'You can also skip steps if you\'re already familiar with the concepts.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tutorial step
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InteractiveTutorialStep(
              title: _getTutorialStepTitle(),
              description: _getTutorialStepDescription(),
              type: _getTutorialStepType(),
              isCompleted: false,
              onComplete: _handleNextStep,
              onSkip: _currentStep < 4 ? _handleNextStep : null,
              hint: _getTutorialHint(),
            ),
          ),
          
          // Pattern creation workspace
          Expanded(
            child: PatternCreationWorkspace(
              initialBlocks: tutorialBlocks,
              difficulty: PatternDifficulty.basic,
              readOnly: false,
              showAnalysis: false,
              title: 'Tutorial Workspace',
              breadcrumbs: [
                context.getHomeBreadcrumb(),
                context.getTutorialBreadcrumb(),
                BreadcrumbItem(
                  label: 'Step ${_currentStep + 1}',
                  fallbackIcon: Icons.school,
                ),
              ],
              showAIMentor: true,
              showCulturalContext: true,
              onPatternChanged: _handlePatternChanged,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Completed'),
      ),
      // Add breadcrumb navigation to completion screen
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BreadcrumbNavigation(
          items: [
            context.getHomeBreadcrumb(),
            context.getTutorialBreadcrumb(),
            BreadcrumbItem(
              label: 'Completed',
              fallbackIcon: Icons.check_circle,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/navigation/background_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration,
                  size: 80,
                  color: AppTheme.kenteGold,
                ),
                const SizedBox(height: 24),
                Text(
                  'Congratulations!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You\'ve completed the Kente Code Weaver tutorial. You now know the basics of creating patterns using code blocks.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'What you\'ve learned:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLearningPoint(
                  context,
                  'Creating basic patterns using pattern blocks',
                  Icons.grid_on,
                ),
                _buildLearningPoint(
                  context,
                  'Adding colors with cultural significance',
                  Icons.palette,
                ),
                _buildLearningPoint(
                  context,
                  'Using loops to repeat patterns',
                  Icons.repeat,
                ),
                _buildLearningPoint(
                  context,
                  'Connecting blocks to create complex designs',
                  Icons.link,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _finishTutorial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kenteGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Continue to Learning Hub',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLearningPoint(BuildContext context, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.kenteGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.kenteGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTutorialStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Welcome to Kente Code Weaver!';
      case 1:
        return 'Creating Your First Pattern';
      case 2:
        return 'Adding Colors';
      case 3:
        return 'Using Loops for Repetition';
      case 4:
        return 'Connecting Blocks';
      default:
        return 'Advanced Patterns';
    }
  }
  
  String _getTutorialStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'In this tutorial, you\'ll learn how to create beautiful Kente patterns using code blocks. Start by exploring the available blocks in the toolbox.';
      case 1:
        return 'Drag a pattern block from the toolbox to the workspace. This will be the foundation of your design. Click the "Generate Pattern" button to see your pattern.';
      case 2:
        return 'Now add a color block and connect it to your pattern. Colors have cultural significance in Kente cloth. Gold represents wealth and royalty.';
      case 3:
        return 'Use loop blocks to repeat patterns. This is similar to using loops in programming to repeat actions. Try setting the loop value to 3.';
      case 4:
        return 'Connect blocks by dragging from one connection point to another. Try connecting the pattern block to the loop block.';
      default:
        return 'Experiment with different combinations to create complex patterns.';
    }
  }
  
  String _getTutorialHint() {
    switch (_currentStep) {
      case 0:
        return 'Click on the toolbox tabs to see different types of blocks.';
      case 1:
        return 'Click the "Generate Pattern" button in the bottom right to see your pattern.';
      case 2:
        return 'Try connecting the color block to the pattern block by dragging from the output of one to the input of another.';
      case 3:
        return 'You can change the loop value by clicking on the loop block and entering a new number.';
      case 4:
        return 'To connect blocks, click and drag from a connection point (the small circles) on one block to a connection point on another block.';
      default:
        return 'Try different combinations of blocks to create unique patterns.';
    }
  }
  
  TutorialStepType _getTutorialStepType() {
    switch (_currentStep) {
      case 0:
        return TutorialStepType.introduction;
      case 1:
        return TutorialStepType.blockDragging;
      case 2:
        return TutorialStepType.colorSelection;
      case 3:
        return TutorialStepType.loopUsage;
      case 4:
        return TutorialStepType.patternSelection;
      default:
        return TutorialStepType.patternSelection;
    }
  }
}
