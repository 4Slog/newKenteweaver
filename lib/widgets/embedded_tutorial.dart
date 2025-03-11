import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tutorial_service.dart' as tutorial_service;
import '../services/audio_service.dart';
import '../services/adaptive_learning_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_tutorial_step.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../extensions/breadcrumb_extensions.dart';

/// A widget that displays an embedded tutorial
class EmbeddedTutorial extends StatefulWidget {
  /// The ID of the tutorial to display
  final String tutorialId;
  
  /// Optional list of tutorial steps to override the default steps
  final List<String>? tutorialSteps;
  
  /// Callback when the tutorial is completed
  final VoidCallback? onTutorialComplete;
  
  /// Whether to show breadcrumbs
  final bool showBreadcrumbs;
  
  /// Whether to show the AI mentor
  final bool showAIMentor;
  
  /// Whether to enable TTS
  final bool enableTTS;
  
  const EmbeddedTutorial({
    Key? key,
    required this.tutorialId,
    this.tutorialSteps,
    this.onTutorialComplete,
    this.showBreadcrumbs = true,
    this.showAIMentor = true,
    this.enableTTS = true,
  }) : super(key: key);

  @override
  State<EmbeddedTutorial> createState() => _EmbeddedTutorialState();
}

class _EmbeddedTutorialState extends State<EmbeddedTutorial> {
  late tutorial_service.TutorialService _tutorialService;
  late AdaptiveLearningService _adaptiveLearningService;
  late AudioService _audioService;
  
  bool _isLoading = true;
  tutorial_service.TutorialData? _tutorialData;
  List<tutorial_service.TutorialStep>? _steps;
  int _currentStepIndex = 0;
  bool _tutorialCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _loadTutorial();
  }
  
  Future<void> _loadTutorial() async {
    _tutorialService = Provider.of<tutorial_service.TutorialService>(context, listen: false);
    _adaptiveLearningService = Provider.of<AdaptiveLearningService>(context, listen: false);
    _audioService = Provider.of<AudioService>(context, listen: false);
    
    try {
      // Load tutorial data
      final tutorialData = await _tutorialService.loadTutorial(widget.tutorialId);
      
      // Use custom steps if provided
      List<tutorial_service.TutorialStep> steps;
      if (widget.tutorialSteps != null && widget.tutorialSteps!.isNotEmpty) {
        steps = _tutorialService.parseTutorialSteps(widget.tutorialSteps!, widget.tutorialId);
      } else {
        steps = tutorialData.steps;
      }
      
      if (mounted) {
        setState(() {
          _tutorialData = tutorialData;
          _steps = steps;
          _isLoading = false;
        });
        
        // Play tutorial sound
        if (_audioService.soundEnabled) {
          _audioService.playSoundEffect(AudioType.navigationTap);
        }
      }
    } catch (e) {
      debugPrint('Error loading tutorial: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tutorial: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _handleStepComplete() {
    // Play sound effect
    if (_audioService.soundEnabled) {
      _audioService.playSoundEffect(AudioType.success);
    }
    
    if (_currentStepIndex < (_steps?.length ?? 0) - 1) {
      // Move to next step
      setState(() {
        _currentStepIndex++;
      });
    } else {
      // Tutorial completed
      setState(() {
        _tutorialCompleted = true;
      });
      
      // Record tutorial completion in adaptive learning service
      _recordTutorialCompletion();
      
      // Call completion callback
      if (widget.onTutorialComplete != null) {
        widget.onTutorialComplete!();
      }
    }
  }
  
  void _recordTutorialCompletion() {
    try {
      // Record tutorial completion
      _adaptiveLearningService.recordInteraction(
        'tutorial_completed',
        widget.tutorialId,
        data: {
          'steps_completed': _steps?.length ?? 0,
          'duration_seconds': 0, // TODO: Track actual duration
        },
      );
      
      // Update concept mastery based on tutorial type
      if (widget.tutorialId.contains('pattern')) {
        _adaptiveLearningService.updateConceptMastery('pattern_creation', 0.2);
      }
      if (widget.tutorialId.contains('color')) {
        _adaptiveLearningService.updateConceptMastery('color_selection', 0.2);
      }
      if (widget.tutorialId.contains('loop')) {
        _adaptiveLearningService.updateConceptMastery('loop_usage', 0.2);
      }
    } catch (e) {
      debugPrint('Error recording tutorial completion: $e');
    }
  }
  
  void _handleSkip() {
    // Play sound effect
    if (_audioService.soundEnabled) {
      _audioService.playSoundEffect(AudioType.navigationTap);
    }
    
    if (_currentStepIndex < (_steps?.length ?? 0) - 1) {
      // Move to next step
      setState(() {
        _currentStepIndex++;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }
    
    if (_tutorialData == null || _steps == null || _steps!.isEmpty) {
      return _buildErrorView();
    }
    
    return Column(
      children: [
        // Breadcrumb navigation
        if (widget.showBreadcrumbs)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BreadcrumbNavigation(
              items: [
                context.getHomeBreadcrumb(),
                BreadcrumbItem(
                  label: 'Tutorials',
                  fallbackIcon: Icons.school,
                ),
                BreadcrumbItem(
                  label: _tutorialData!.title,
                  fallbackIcon: Icons.book,
                ),
              ],
            ),
          ),
        
        // Tutorial content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/story/background_pattern.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9),
                  BlendMode.lighten,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tutorial header
                  Text(
                    _tutorialData!.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.kenteGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tutorialData!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress indicator
                  LinearProgressIndicator(
                    value: _steps!.isEmpty ? 0 : (_currentStepIndex + 1) / _steps!.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kenteGold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentStepIndex + 1} of ${_steps!.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  
                  // Current tutorial step
                  Expanded(
                    child: _currentStepIndex < _steps!.length
                        ? InteractiveTutorialStep(
                            title: _steps![_currentStepIndex].title,
                            description: _steps![_currentStepIndex].description,
                            type: _mapTutorialStepType(_steps![_currentStepIndex].type),
                            imageAsset: _steps![_currentStepIndex].imageAsset,
                            hint: _steps![_currentStepIndex].hint,
                            isCompleted: _tutorialCompleted,
                            onComplete: _handleStepComplete,
                            onSkip: _handleSkip,
                            nextStepPreview: _currentStepIndex < _steps!.length - 1
                                ? _buildStepPreview(_steps![_currentStepIndex + 1])
                                : null,
                          )
                        : _buildCompletionView(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Map between TutorialStepType in tutorial_service.dart and interactive_tutorial_step.dart
  TutorialStepType _mapTutorialStepType(dynamic serviceType) {
    // Convert from string or enum from tutorial_service.dart
    final typeStr = serviceType.toString().split('.').last.toLowerCase();
    
    switch (typeStr) {
      case 'introduction':
        return TutorialStepType.introduction;
      case 'blockdragging':
        return TutorialStepType.blockDragging;
      case 'patternselection':
        return TutorialStepType.patternSelection;
      case 'colorselection':
        return TutorialStepType.colorSelection;
      case 'loopusage':
        return TutorialStepType.loopUsage;
      case 'rowcolumns':
        return TutorialStepType.rowColumns;
      case 'culturalcontext':
        return TutorialStepType.culturalContext;
      case 'challenge':
        return TutorialStepType.challenge;
      default:
        return TutorialStepType.introduction;
    }
  }
  
  Widget _buildStepPreview(tutorial_service.TutorialStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
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
            'Loading tutorial...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tutorial',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadTutorial,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'Tutorial Completed!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'ve successfully completed the ${_tutorialData?.title} tutorial.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onTutorialComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kenteGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
