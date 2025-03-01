import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../models/lesson_type.dart';
import '../models/pattern_difficulty.dart';
import '../navigation/app_router.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../extensions/breadcrumb_extensions.dart';
import '../services/audio_service.dart';

class LearningHub extends StatefulWidget {
  const LearningHub({super.key});

  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = Provider.of<AudioService>(context, listen: false);
    
    // Play the appropriate music when the screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_audioService.musicEnabled) {
        _audioService.playMusic(AudioType.menuTheme);
      }
    });
  }
  
  @override
  void dispose() {
    // Stop the music when the screen is disposed
    _audioService.stopAllMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Hub'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tutorials'),
              Tab(text: 'Stories'),
              Tab(text: 'Patterns'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Add breadcrumb navigation
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BreadcrumbNavigation(
                items: [
                  context.getHomeBreadcrumb(),
                  BreadcrumbItem(
                    label: 'Learning Hub',
                    fallbackIcon: Icons.school,
                    iconAsset: 'assets/images/navigation/learning_hub_breadcrumb.png',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTutorialsTab(context),
                  _buildStoriesTab(context),
                  _buildPatternsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialsTab(BuildContext context) {
    return _buildSection(
      context,
      'Getting Started',
      [
        LessonModel(
          id: 'tut1',
          title: 'Introduction to Kente Patterns',
          description: 'Learn the basics of pattern creation',
          type: LessonType.tutorial,
          difficulty: PatternDifficulty.basic,
          content: {'steps': []},
        ),
      ],
    );
  }

  Widget _buildStoriesTab(BuildContext context) {
    return _buildSection(
      context,
      'Ananse\'s Code Chronicles',
      [
        LessonModel(
          id: 'story1',
          title: 'The Spider\'s First Pattern',
          description: 'Join Ananse in creating his first digital Kente pattern',
          type: LessonType.story,
          difficulty: PatternDifficulty.basic,
          content: {'steps': []},
        ),
      ],
    );
  }

  Widget _buildPatternsTab(BuildContext context) {
    return _buildSection(
      context,
      'Pattern Challenges',
      [
        LessonModel(
          id: 'pat1',
          title: 'Basic Patterns',
          description: 'Create your first pattern',
          type: LessonType.pattern,
          difficulty: PatternDifficulty.basic,
          content: {'steps': []},
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<LessonModel> lessons,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...lessons.map((lesson) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(lesson.title),
                subtitle: Text(lesson.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDifficultyIcon(lesson.difficulty),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    lesson.type == LessonType.story
                        ? AppRouter.story
                        : lesson.type == LessonType.tutorial
                            ? AppRouter.tutorial
                            : AppRouter.challenge,
                    arguments: lesson,
                  );
                },
              ),
            )),
      ],
    );
  }

  Widget _buildDifficultyIcon(PatternDifficulty difficulty) {
    IconData iconData;
    Color color;

    switch (difficulty) {
      case PatternDifficulty.basic:
        iconData = Icons.star_border;
        color = Colors.green;
        break;
      case PatternDifficulty.intermediate:
        iconData = Icons.star_half;
        color = Colors.orange;
        break;
      case PatternDifficulty.advanced:
        iconData = Icons.star;
        color = Colors.red;
        break;
      case PatternDifficulty.master:
        iconData = Icons.auto_awesome;
        color = Colors.purple;
        break;
    }

    return Icon(iconData, color: color);
  }
}
