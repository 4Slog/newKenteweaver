import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/pattern_creation_workspace.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/cultural_context_card.dart';
import '../services/pattern_render_service.dart';
import '../services/device_profile_service.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../extensions/breadcrumb_extensions.dart';

class SandboxScreen extends StatefulWidget {
  final PatternDifficulty difficulty;
  final String? initialPatternId;
  final bool showTutorial;

  const SandboxScreen({
    super.key,
    this.difficulty = PatternDifficulty.basic,
    this.initialPatternId,
    this.showTutorial = false,
  });

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  late BlockCollection _blockCollection;
  late List<BreadcrumbItem> _breadcrumbs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _breadcrumbs = [
      context.getHomeBreadcrumb(),
      BreadcrumbItem(
        label: 'Sandbox',
        fallbackIcon: Icons.science,
      ),
    ];
    _loadInitialPattern();
  }

  Future<void> _loadInitialPattern() async {
    setState(() => _isLoading = true);

    try {
      if (widget.initialPatternId != null) {
        final renderService = Provider.of<PatternRenderService>(context, listen: false);
        final pattern = await renderService.getPattern(widget.initialPatternId!);
        if (pattern != null) {
          _blockCollection = BlockCollection.fromJson(pattern);
        } else {
          _blockCollection = BlockCollection(blocks: []);
        }
      } else {
        _blockCollection = BlockCollection(blocks: []);
      }
    } catch (e) {
      debugPrint('Error loading initial pattern: $e');
      _blockCollection = BlockCollection(blocks: []);
    }

    setState(() => _isLoading = false);
  }

  void _handlePatternChanged(BlockCollection blocks) async {
    final renderService = Provider.of<PatternRenderService>(context, listen: false);
    final deviceProfile = Provider.of<DeviceProfileService>(context, listen: false);
    
    try {
      // Generate a unique ID if none exists
      final patternId = widget.initialPatternId ?? 
        'sandbox_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save the pattern
      await renderService.savePattern(
        patternId,
        blocks.toJson(),
      );

      // Update device profile if needed
      if (widget.initialPatternId == null) {
        final profile = deviceProfile.currentProfile;
        if (profile != null) {
          final progress = profile.progress;
          if (!progress.unlockedPatterns.contains(patternId)) {
            final updatedProgress = progress.copyWith(
              unlockedPatterns: [...progress.unlockedPatterns, patternId],
            );
            await deviceProfile.updateProgress(updatedProgress);
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving pattern: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving pattern'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Sandbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Show Tutorial',
            onPressed: () {
              // TODO: Implement tutorial
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Pattern',
            onPressed: () {
              _handlePatternChanged(_blockCollection);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BreadcrumbNavigation(
              items: _breadcrumbs,
            ),
          ),
          Expanded(
            child: PatternCreationWorkspace(
              initialBlocks: _blockCollection,
              difficulty: widget.difficulty,
              showAnalysis: true,
              showAIMentor: true,
              showCulturalContext: true,
              title: 'Pattern Sandbox',
              onPatternChanged: _handlePatternChanged,
            ),
          ),
        ],
      ),
    );
  }
} 