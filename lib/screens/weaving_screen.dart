import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/audio_service.dart';

class WeavingScreen extends StatefulWidget {
  final PatternDifficulty difficulty;
  final BlockCollection? initialBlocks;
  final String title;

  const WeavingScreen({
    super.key,
    this.difficulty = PatternDifficulty.basic,
    this.initialBlocks,
    this.title = 'Pattern Creation',
  });

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  late BlockCollection blockCollection;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    blockCollection = widget.initialBlocks ?? BlockCollection(blocks: []);
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

  void _handlePatternChanged(BlockCollection updatedBlocks) {
    setState(() {
      blockCollection = updatedBlocks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PatternCreationWorkspace(
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
    );
  }
}
