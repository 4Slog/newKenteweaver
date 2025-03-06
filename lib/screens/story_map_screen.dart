import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pattern_difficulty.dart';
import '../models/story_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_type.dart';
import '../providers/user_provider.dart';
import '../services/story_progression_service.dart';
import '../theme/app_theme.dart';
import '../navigation/app_router.dart';

class StoryMapScreen extends StatefulWidget {
  const StoryMapScreen({Key? key}) : super(key: key);
  
  @override
  _StoryMapScreenState createState() => _StoryMapScreenState();
}

class _StoryMapScreenState extends State<StoryMapScreen> {
  late StoryProgressionService _progressionService;
  List<StoryOverview>? _availableStories;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _progressionService = Provider.of<StoryProgressionService>(context, listen: false);
      
      // Get mock available story IDs for the user
      final storyIds = await _getMockAvailableStoryIds(userProvider.user!.id);
      
      // Load story overview data
      final List<StoryOverview> stories = [];
      for (final id in storyIds) {
        // Get story from progression service
        final story = await _getStoryOverview(id);
        if (story != null) {
          stories.add(story);
        }
      }
      
      // Sort stories by difficulty
      stories.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
      
      if (mounted) {
        setState(() {
          _availableStories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _availableStories = [];
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Journey'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStoryMap(),
    );
  }
  
  Widget _buildStoryMap() {
    if (_availableStories == null || _availableStories!.isEmpty) {
      return const Center(
        child: Text('No stories available yet. Complete the tutorial to unlock stories!'),
      );
    }
    
    // Group stories by difficulty
    final Map<PatternDifficulty, List<StoryOverview>> storiesByDifficulty = {};
    for (final story in _availableStories!) {
      if (!storiesByDifficulty.containsKey(story.difficulty)) {
        storiesByDifficulty[story.difficulty] = [];
      }
      storiesByDifficulty[story.difficulty]!.add(story);
    }
    
    // Get user provider for completion data
    final userProvider = Provider.of<UserProvider>(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journey map header
            const Text(
              'Your Kente Weaving Journey',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the path to become a master Kente weaver!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Journey map visualization
            ...PatternDifficulty.values.map((difficulty) {
              final stories = storiesByDifficulty[difficulty] ?? [];
              return _buildDifficultySection(difficulty, stories, userProvider);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDifficultySection(
    PatternDifficulty difficulty,
    List<StoryOverview> stories,
    UserProvider userProvider,
  ) {
    // Skip empty difficulty levels
    if (stories.isEmpty) return const SizedBox.shrink();
    
    // Get difficulty color and name
    final Color difficultyColor = _getDifficultyColor(difficulty);
    final String difficultyName = _getDifficultyName(difficulty);
    final String ageRange = _getAgeRangeForDifficulty(difficulty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Difficulty header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: difficultyColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                difficultyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Ages $ageRange',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Story nodes for this difficulty
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              final isCompleted = _getStoryCompletionPercentage(userProvider.user!.id, story.id) >= 0.9;
              final isInProgress = _getStoryCompletionPercentage(userProvider.user!.id, story.id) > 0 &&
                  _getStoryCompletionPercentage(userProvider.user!.id, story.id) < 0.9;
              final isAvailable = index == 0 || 
                  _getStoryCompletionPercentage(userProvider.user!.id, stories[index - 1].id) > 0;
              
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: StoryNodeWidget(
                  story: story,
                  isCompleted: isCompleted,
                  isInProgress: isInProgress,
                  isAvailable: isAvailable,
                  difficultyColor: difficultyColor,
                  completionPercentage: _getStoryCompletionPercentage(userProvider.user!.id, story.id),
                  onSelect: isAvailable
                      ? () => _navigateToStory(story)
                      : null,
                ),
              );
            },
          ),
        ),
        
        // Path to next difficulty
        if (difficulty != PatternDifficulty.master)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: _PathPainter(
                    color: difficultyColor,
                  ),
                  child: const SizedBox(width: 100),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Helper method to get mock available story IDs
  Future<List<String>> _getMockAvailableStoryIds(String userId) async {
    // In a real implementation, this would fetch from the progression service
    // For now, we'll return mock story IDs
    return [
      'intro_first_pattern',
      'basic_dame_dame',
      'basic_colors',
      'intermediate_patterns',
      'advanced_patterns',
    ];
  }

  // Helper method to get story overview
  Future<StoryOverview?> _getStoryOverview(String storyId) async {
    try {
      // In a real implementation, this would fetch from the progression service
      // For now, we'll create a mock story overview
      return StoryOverview(
        id: storyId,
        title: 'Story $storyId',
        description: 'A story about Kente weaving and coding',
        difficulty: _getDifficultyFromId(storyId),
        concepts: ['pattern', 'sequence', 'loop'],
      );
    } catch (e) {
      debugPrint('Error getting story overview: $e');
      return null;
    }
  }
  
  // Helper method to get story completion percentage
  double _getStoryCompletionPercentage(String userId, String storyId) {
    // In a real implementation, this would fetch from the progression service
    // For now, we'll return a mock value based on the story ID
    if (storyId.contains('intro')) {
      return 1.0; // Completed
    } else if (storyId.contains('basic')) {
      return 0.5; // In progress
    } else {
      return 0.0; // Not started
    }
  }
  
  // Helper method to get difficulty from story ID
  PatternDifficulty _getDifficultyFromId(String storyId) {
    if (storyId.contains('master')) {
      return PatternDifficulty.master;
    } else if (storyId.contains('advanced')) {
      return PatternDifficulty.advanced;
    } else if (storyId.contains('intermediate')) {
      return PatternDifficulty.intermediate;
    } else {
      return PatternDifficulty.basic;
    }
  }
  
  void _navigateToStory(StoryOverview story) {
    // Create lesson model from story overview
    final lesson = LessonModel(
      id: story.id,
      title: story.title,
      description: story.description,
      type: LessonType.story,
      difficulty: story.difficulty,
      content: {'storyId': story.id},
      skills: story.concepts,
    );
    
    // Navigate to story screen
    Navigator.pushNamed(
      context,
      AppRouter.story,
      arguments: lesson,
    );
  }
  
  Color _getDifficultyColor(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return Colors.green;
      case PatternDifficulty.intermediate:
        return Colors.orange;
      case PatternDifficulty.advanced:
        return Colors.red;
      case PatternDifficulty.master:
        return Colors.purple;
    }
  }
  
  String _getDifficultyName(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 'Basic';
      case PatternDifficulty.intermediate:
        return 'Intermediate';
      case PatternDifficulty.advanced:
        return 'Advanced';
      case PatternDifficulty.master:
        return 'Master';
    }
  }
  
  String _getAgeRangeForDifficulty(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return '7-8';
      case PatternDifficulty.intermediate:
        return '8-10';
      case PatternDifficulty.advanced:
        return '10-11';
      case PatternDifficulty.master:
        return '11-12';
    }
  }
}

// Custom painter for the path between difficulty levels
class _PathPainter extends CustomPainter {
  final Color color;
  
  _PathPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(
      size.width * 0.3, 0,
      size.width * 0.7, size.height,
      size.width, size.height,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw arrow at the end
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final arrowPath = Path();
    arrowPath.moveTo(size.width, size.height);
    arrowPath.lineTo(size.width - 10, size.height - 5);
    arrowPath.lineTo(size.width - 10, size.height + 5);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Story node widget for the map
class StoryNodeWidget extends StatelessWidget {
  final StoryOverview story;
  final bool isCompleted;
  final bool isInProgress;
  final bool isAvailable;
  final Color difficultyColor;
  final double completionPercentage;
  final VoidCallback? onSelect;
  
  const StoryNodeWidget({
    Key? key,
    required this.story,
    required this.isCompleted,
    required this.isInProgress,
    required this.isAvailable,
    required this.difficultyColor,
    required this.completionPercentage,
    this.onSelect,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determine node appearance based on status
    final Color nodeColor = isCompleted
        ? difficultyColor
        : isInProgress
            ? difficultyColor.withOpacity(0.7)
            : isAvailable
                ? Colors.grey[300]!
                : Colors.grey[200]!;
    
    final Color textColor = isCompleted || isInProgress
        ? Colors.white
        : Colors.black87;
    
    final IconData iconData = isCompleted
        ? Icons.check_circle
        : isInProgress
            ? Icons.play_circle_filled
            : isAvailable
                ? Icons.lock_open
                : Icons.lock;
    
    return InkWell(
      onTap: isAvailable ? onSelect : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story icon
            Icon(
              iconData,
              color: textColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            
            // Story title
            Text(
              story.title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Story description
            Text(
              story.description,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Progress indicator
            if (isInProgress || isCompleted)
              LinearProgressIndicator(
                value: completionPercentage,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.white : Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
