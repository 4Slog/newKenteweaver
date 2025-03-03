import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/feedback_popup.dart';
import '../navigation/app_router.dart';
import '../theme/app_theme.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/audio_service.dart';
import '../services/block_definition_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  late BlockCollection blockCollection;
  late BlockDefinitionService _blockDefinitionService;
  PatternDifficulty _selectedDifficulty = PatternDifficulty.basic;
  bool _showWorkspace = false;
  bool _challengeCompleted = false;
  late AudioService _audioService;
  late AnimationController _animationController;

  // Challenge metadata
  List<Map<String, dynamic>> _challenges = [];
  int _selectedChallengeIndex = 0;

  // Timer variables
  int _remainingSeconds = 0;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _blockDefinitionService = BlockDefinitionService();
    _audioService = Provider.of<AudioService>(context, listen: false);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize block collection with a default empty collection
    blockCollection = BlockCollection(blocks: []);

    // Load block definitions and challenges
    _initServices();

    // Play the appropriate music when the screen is loaded
    _audioService.playMusic(AudioType.learningTheme);
  }

  Future<void> _initServices() async {
    await _blockDefinitionService.loadDefinitions();
    _loadChallenges();
    // Create initial challenge blocks based on the first challenge
    blockCollection = _createChallengeBlocks();
  }

  void _loadChallenges() {
    // These would typically come from a database or API in a production app
    _challenges = [
      {
        'id': 'basic_checker',
        'title': 'Dame-Dame Basics',
        'description': 'Create a basic checkerboard pattern using Dame-Dame blocks and appropriate colors.',
        'objective': 'Use pattern and color blocks to create a traditional checker pattern',
        'difficulty': PatternDifficulty.basic,
        'timeLimit': 5, // minutes
        'requiredBlocks': ['checker_pattern', 'shuttle_black', 'shuttle_gold'],
        'imageAsset': 'assets/images/blocks/checker_pattern.png',
      },
      {
        'id': 'zigzag_challenge',
        'title': 'Nkyinkyim Journey',
        'description': 'Create a zigzag pattern representing life\'s journey with meaningful color choices.',
        'objective': 'Combine zigzag patterns with meaningful colors',
        'difficulty': PatternDifficulty.basic,
        'timeLimit': 6,
        'requiredBlocks': ['zigzag_pattern', 'shuttle_black', 'shuttle_red', 'shuttle_gold'],
        'imageAsset': 'assets/images/blocks/zigzag_pattern.png',
      },
      {
        'id': 'intermediate_loops',
        'title': 'Pattern Repetition',
        'description': 'Use loop blocks to create repetitive patterns that show rhythm and harmony.',
        'objective': 'Create a pattern with at least one loop block',
        'difficulty': PatternDifficulty.intermediate,
        'timeLimit': 8,
        'requiredBlocks': ['checker_pattern', 'loop_block', 'shuttle_black', 'shuttle_gold'],
        'imageAsset': 'assets/images/blocks/loop_icon.png',
      },
      {
        'id': 'advanced_combination',
        'title': 'Pattern Combination',
        'description': 'Combine multiple patterns into a complex design that tells a cultural story.',
        'objective': 'Use at least two different pattern types and structure blocks',
        'difficulty': PatternDifficulty.advanced,
        'timeLimit': 10,
        'requiredBlocks': ['checker_pattern', 'zigzag_pattern', 'row_block', 'column_block'],
        'imageAsset': 'assets/images/blocks/row_icon.png',
      },
      {
        'id': 'master_creation',
        'title': 'Cultural Masterpiece',
        'description': 'Create a pattern with deep cultural significance that combines all your skills.',
        'objective': 'Demonstrate mastery of patterns, colors, and their cultural meanings',
        'difficulty': PatternDifficulty.master,
        'timeLimit': 12,
        'requiredBlocks': ['checker_pattern', 'zigzag_pattern', 'loop_block', 'row_block'],
        'imageAsset': 'assets/images/blocks/square_pattern.png',
      },
    ];
  }

  BlockCollection _createChallengeBlocks() {
    // If challenges haven't loaded yet, return an empty collection
    if (_challenges.isEmpty) {
      return BlockCollection(blocks: []);
    }

    final selectedChallenge = _challenges[_selectedChallengeIndex];
    final requiredBlockIds = selectedChallenge['requiredBlocks'] as List<dynamic>? ?? [];

    // Create blocks from block definitions
    final blocks = <Block>[];

    for (final blockId in requiredBlockIds) {
      final block = _blockDefinitionService.getBlockById(blockId.toString());
      if (block != null) {
        // Create a copy with a unique ID to prevent conflicts
        final uniqueId = '${block.id}_${DateTime.now().millisecondsSinceEpoch}';
        blocks.add(block.copyWith(id: uniqueId));
      }
    }

    return BlockCollection(blocks: blocks);
  }

  @override
  void dispose() {
    // Stop the music when the screen is disposed
    _audioService.stopAllMusic();
    _animationController.dispose();
    // Cancel any active timers
    _stopChallengeTimer();
    super.dispose();
  }

  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      blockCollection = updatedBlocks;
    });

    // Check if challenge is completed
    _checkChallengeCompletion();
  }

  void _startChallenge() {
    setState(() {
      _showWorkspace = true;
      _challengeCompleted = false;
    });

    // Refresh blocks for the selected challenge
    blockCollection = _createChallengeBlocks();

    // Start the challenge timer
    _startChallengeTimer();

    // Play challenge start sound
    _audioService.playSoundEffect(AudioType.buttonTap);
  }

  void _startChallengeTimer() {
    final selectedChallenge = _challenges[_selectedChallengeIndex];
    final timeLimit = selectedChallenge['timeLimit'] as int? ?? 5;

    setState(() {
      _remainingSeconds = timeLimit * 60; // Convert minutes to seconds
      _timerActive = true;
    });

    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (!_timerActive) return;

    setState(() {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        Future.delayed(const Duration(seconds: 1), _updateTimer);
      } else {
        // Time's up
        _showTimeUpDialog();
      }
    });
  }

  void _stopChallengeTimer() {
    setState(() {
      _timerActive = false;
    });
  }

  void _showTimeUpDialog() {
    _stopChallengeTimer();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: const Text('You ran out of time for this challenge. Would you like to try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showWorkspace = false;
              });
            },
            child: const Text('Exit Challenge'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kenteGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // Restart the challenge
              blockCollection = _createChallengeBlocks();
              _startChallengeTimer();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _checkChallengeCompletion() {
    // This would normally have more sophisticated logic to check if the challenge requirements are met
    // For this demo, we'll simply check if there are connections between blocks

    int connections = 0;
    for (final block in blockCollection.blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          connections++;
        }
      }
    }

    // If there are at least 2 connections, consider the challenge potentially complete
    if (connections >= 2 && !_challengeCompleted) {
      // Show completion button or automatically complete after validation
      // For now, we'll just mark it as ready for completion
      setState(() {
        _challengeCompleted = true;
      });
    }
  }

  void _completeChallenge() {
    _stopChallengeTimer();

    // Play success sound
    _audioService.playSoundEffect(AudioType.success);

    // Show completion dialog
    _showChallengeCompletionDialog();
  }

  void _showChallengeCompletionDialog() {
    final selectedChallenge = _challenges[_selectedChallengeIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.kenteGold, size: 30),
            const SizedBox(width: 10),
            Text(
              'Challenge Completed!',
              style: TextStyle(
                color: AppTheme.kenteGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You have completed the "${selectedChallenge['title']}" challenge.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'You have earned:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildRewardItem(Icons.star, '50 points'),
            _buildRewardItem(Icons.extension, 'New pattern unlocked'),
            _buildRewardItem(Icons.palette, 'Cultural badge'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showWorkspace = false;
              });
            },
            child: const Text('Back to Challenges'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kenteGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // Go to the next challenge if available
              if (_selectedChallengeIndex < _challenges.length - 1) {
                setState(() {
                  _selectedChallengeIndex++;
                  _showWorkspace = false;
                });
              } else {
                setState(() {
                  _showWorkspace = false;
                });
              }
            },
            child: const Text('Next Challenge'),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.kenteGold, size: 20),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWorkspace) {
      return _buildChallengeWorkspace();
    }

    return _buildChallengeSelectionScreen();
  }

  Widget _buildChallengeWorkspace() {
    final selectedChallenge = _challenges[_selectedChallengeIndex];
    final minutesRemaining = _remainingSeconds ~/ 60;
    final secondsRemaining = _remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge: ${selectedChallenge['title']}'),
        actions: [
          // Timer display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${minutesRemaining.toString().padLeft(2, '0')}:${secondsRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Challenge objective banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppTheme.kenteGold.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Objective: ${selectedChallenge['objective']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_challengeCompleted)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete'),
                    onPressed: _completeChallenge,
                  ),
              ],
            ),
          ),

          // Main pattern creation workspace
          Expanded(
            child: PatternCreationWorkspace(
              initialBlocks: blockCollection,
              difficulty: selectedChallenge['difficulty'] as PatternDifficulty,
              title: selectedChallenge['title'] as String,
              breadcrumbs: [
                context.getHomeBreadcrumb(),
                context.getChallengeBreadcrumb(),
                BreadcrumbItem(
                  label: selectedChallenge['title'] as String,
                  fallbackIcon: Icons.extension,
                ),
              ],
              onPatternChanged: _handlePatternChanged,
              showAIMentor: true,
              showCulturalContext: true,
            ),
          ),
        ],
      ),
      floatingActionButton: _challengeCompleted ? FloatingActionButton(
        onPressed: _completeChallenge,
        backgroundColor: AppTheme.kenteGold,
        child: const Icon(Icons.check, color: Colors.black),
      ) : null,
    );
  }

  Widget _buildChallengeSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/patterns/background_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb navigation
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BreadcrumbNavigation(
                items: [
                  context.getHomeBreadcrumb(),
                  context.getChallengeBreadcrumb(),
                ],
              ),
            ),

            // Title and description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kente Pattern Challenges',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test your pattern creation skills with these challenges. Complete them to earn badges and unlock new patterns.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildDifficultySelector(),
            ),

            // Challenge cards
            Expanded(
              child: _buildChallengeList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PatternDifficulty.values.map((difficulty) {
          return _buildDifficultyCard(difficulty);
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultyCard(PatternDifficulty difficulty) {
    final isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.kenteGold : Colors.transparent,
            width: 2,
          ),
        ),
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                difficulty.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.kenteGold : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                difficulty.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeList() {
    // Filter challenges by selected difficulty
    final filteredChallenges = _challenges.where(
            (c) => c['difficulty'] == _selectedDifficulty
    ).toList();

    if (filteredChallenges.isEmpty) {
      return const Center(
        child: Text(
          'No challenges available for this difficulty level yet',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredChallenges.length,
      itemBuilder: (context, index) {
        final challenge = filteredChallenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final difficulty = challenge['difficulty'] as PatternDifficulty;
    final difficultyColor = AppTheme.getDifficultyColor(difficulty, context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedChallengeIndex = _challenges.indexOf(challenge);
          });
          _startChallenge();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Challenge header with difficulty indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Challenge image
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: difficultyColor),
                    ),
                    child: Image.asset(
                      challenge['imageAsset'] as String? ?? 'assets/images/blocks/checker_pattern.png',
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.grid_on, color: difficultyColor);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Challenge title and difficulty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: difficultyColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Challenge description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge['description'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Time estimate
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge['timeLimit']} min',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Required blocks count
                      Row(
                        children: [
                          const Icon(Icons.widgets, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            '${(challenge['requiredBlocks'] as List?)?.length ?? 0} blocks',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Start button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedChallengeIndex = _challenges.indexOf(challenge);
                          });
                          _startChallenge();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kenteGold,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}