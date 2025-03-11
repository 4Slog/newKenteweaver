import 'package:flutter/material.dart';
import 'models/lesson_model.dart';
import 'screens/achievement_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/home_screen.dart';
import 'screens/interactive_lesson_screen.dart';
import 'screens/learning_hub_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/project_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/story_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/weaving_screen.dart';
import 'screens/welcome_screen.dart';

// This file is deprecated. Use AppRouter instead.
@Deprecated('Use AppRouter instead')
class Routes {
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
  static const String project = '/project';

  @Deprecated('Use AppRouter.onGenerateRoute instead')
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
      return MaterialPageRoute(builder: (_) => const WeavingScreen());
    } else if (name == project) {
      return MaterialPageRoute(builder: (_) => const ProjectScreen());
    }

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }
}
