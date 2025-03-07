import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/lesson_model.dart';
import '../models/pattern_difficulty.dart';
import '../screens/achievement_screen.dart';
import '../screens/ai_response_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/error_screen.dart';
import '../screens/home_screen.dart';
import '../screens/interactive_lesson_screen.dart';
import '../screens/learning_hub_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/story_screen.dart';
import '../screens/tutorial_screen.dart';
import '../screens/weaving_screen.dart';
import '../screens/welcome_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String welcome = '/welcome';
  static const String tutorial = '/tutorial';
  static const String lesson = '/lesson';
  static const String story = '/story';
  static const String challenge = '/challenge';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String rewards = '/rewards';
  static const String achievements = '/achievements';
  static const String learningHub = '/learning-hub';
  static const String weaving = '/weaving';
  static const String aiResponse = '/ai-response';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    try {
      final args = settings.arguments;
      final name = settings.name;

      if (name == home) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    } else if (name == welcome) {
      return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    } else if (name == tutorial) {
      return MaterialPageRoute(builder: (_) => const TutorialScreen());
    } else if (name == lesson && args is LessonModel) {
      return MaterialPageRoute(
        builder: (_) => InteractiveLessonScreen(lesson: args),
      );
    } else if (name == story && args is LessonModel) {
      return MaterialPageRoute(
        builder: (_) => StoryScreen(lesson: args),
      );
    } else if (name == challenge) {
      return MaterialPageRoute(builder: (_) => const ChallengeScreen());
    } else if (name == profile) {
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    } else if (name == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else if (name == rewards) {
      return MaterialPageRoute(builder: (_) => const RewardsScreen());
    } else if (name == achievements) {
      return MaterialPageRoute(builder: (_) => const AchievementScreen());
    } else if (name == learningHub) {
      return MaterialPageRoute(builder: (_) => const LearningHub());
    } else if (name == weaving) {
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => WeavingScreen(
            difficulty: args['difficulty'] as PatternDifficulty? ?? PatternDifficulty.basic,
            initialBlocks: args['blocks'] != null 
                ? BlockCollection.fromLegacyBlocks(args['blocks'] as List<Map<String, dynamic>>)
                : null,
            title: args['title'] as String? ?? 'Pattern Creation',
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => const WeavingScreen());
    } else if (name == aiResponse && args is String) {
      return MaterialPageRoute(
        builder: (_) => AIResponseScreen(feedback: args),
      );
      }

      // Default route if no match is found
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Not Found'),
            backgroundColor: Colors.orange,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'No route defined for ${settings.name}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, home),
                  child: const Text('Go to Home Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Return a fallback route to prevent crashes
      return MaterialPageRoute(
        builder: (context) => ErrorScreen(
          message: 'Navigation error occurred',
          details: e.toString(),
          onRetry: () => Navigator.pushReplacementNamed(context, home),
        ),
      );
    }
  }
}
