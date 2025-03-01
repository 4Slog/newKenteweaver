import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../navigation/app_router.dart';
import '../theme/app_theme.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/audio_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late BlockCollection blockCollection;
  PatternDifficulty _selectedDifficulty = PatternDifficulty.basic;
  bool _showWorkspace = false;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    // Initialize with challenge blocks
    blockCollection = _createChallengeBlocks();
    _audioService = Provider.of<AudioService>(context, listen: false);
    
    // Play the appropriate music when the screen is loaded
    _audioService.playMusic(AudioType.learningTheme);
  }
  
  @override
  void dispose() {
    // Stop the music when the screen is disposed
    _audioService.stopAllMusic();
    super.dispose();
  }

  BlockCollection _createChallengeBlocks() {
    // Create sample blocks for the challenge
    final blocks = <Block>[
      Block(
        id: 'pattern_block',
        name: 'Basic Pattern',
        description: 'Learn basic pattern creation',
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
        iconPath: 'assets/images/blocks/checker_pattern.png',
        color: Colors.blue,
      ),
      Block(
        id: 'color_block',
        name: 'Color Selection',
        description: 'Choose colors for your pattern',
        type: BlockType.color,
        subtype: 'shuttle_gold',
        properties: {'color': Colors.amber.value.toString()},
        connections: [
          BlockConnection(
            id: 'color_output',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(1, 0.5),
          ),
        ],
        iconPath: 'assets/images/blocks/shuttle_gold.png',
        color: Colors.amber,
      ),
    ];
    
    return BlockCollection(blocks: blocks);
  }

  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      blockCollection = updatedBlocks;
    });
  }

  void _startChallenge() {
    setState(() {
      _showWorkspace = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWorkspace) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Challenge: ${_selectedDifficulty.displayName}'),
        ),
        body: PatternCreationWorkspace(
          initialBlocks: blockCollection,
          difficulty: _selectedDifficulty,
          title: 'Challenge Pattern',
          breadcrumbs: [
            context.getHomeBreadcrumb(),
            context.getChallengeBreadcrumb(),
            BreadcrumbItem(
              label: _selectedDifficulty.displayName,
              fallbackIcon: Icons.grid_on,
              iconAsset: 'assets/images/badges/${_selectedDifficulty.toString().split('.').last}_difficulty.png',
            ),
          ],
          onPatternChanged: _handlePatternChanged,
          showAIMentor: true,
          showCulturalContext: true,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/patterns/background_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb navigation
              BreadcrumbNavigation(
                items: [
                  context.getHomeBreadcrumb(),
                  context.getChallengeBreadcrumb(),
                ],
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Kente Pattern Challenges',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your pattern creation skills with these challenges. Select a difficulty level to begin.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              
              // Difficulty selection
              Text(
                'Select Difficulty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Difficulty cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: PatternDifficulty.values.map((difficulty) {
                    return _buildDifficultyCard(difficulty);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    difficulty.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.kenteGold,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                difficulty.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _startChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kenteGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Start Challenge'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
