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
import '../services/navigation_service.dart';

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

  static Widget buildRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case home:
        return const HomeScreen();
      case welcome:
        return const WelcomeScreen();
      case tutorial:
        return const TutorialScreen();
      case lesson:
        if (arguments is LessonModel) {
          return InteractiveLessonScreen(lesson: arguments);
        }
        throw ArgumentError('LessonModel required for lesson route');
      case story:
        if (arguments is LessonModel) {
          return StoryScreen(lesson: arguments);
        }
        throw ArgumentError('LessonModel required for story route');
      case challenge:
        return const ChallengeScreen();
      case profile:
        return const ProfileScreen();
      case settings:
        return const SettingsScreen();
      case rewards:
        return const RewardsScreen();
      case achievements:
        return const AchievementScreen();
      case learningHub:
        return const LearningHub();
      case weaving:
        if (arguments is Map<String, dynamic>) {
          return WeavingScreen(
            difficulty: arguments['difficulty'] as PatternDifficulty? ?? PatternDifficulty.basic,
            initialBlocks: arguments['blocks'] != null 
                ? BlockCollection.fromLegacyBlocks(arguments['blocks'] as List<Map<String, dynamic>>)
                : null,
            title: arguments['title'] as String? ?? 'Pattern Creation',
          );
        }
        return const WeavingScreen();
      case aiResponse:
        if (arguments is String) {
          return AIResponseScreen(feedback: arguments);
        }
        throw ArgumentError('String feedback required for AI response route');
      default:
        return ErrorScreen(
          message: 'Route not found',
          details: 'No route defined for $routeName',
          onRetry: () {},
        );
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    try {
      final args = settings.arguments;
      final name = settings.name;

      // Get route widget
      final Widget page = buildRoute(name ?? '/', args);

      // Determine transition animation based on route
      if (name == welcome || name == home) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          settings: settings,
        );
      } else if (name == lesson || name == story || name == challenge) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          settings: settings,
        );
      } else if (name == settings || name == profile || name == achievements) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          settings: settings,
        );
      } else {
        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      }
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
