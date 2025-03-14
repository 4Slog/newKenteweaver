import 'package:flutter/material.dart';

class AppRouter {
  static const String home = '/';
  static const String story = '/story';
  static const String pattern = '/pattern';
  static const String tutorial = '/tutorial';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    
    if (name == home) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Home Screen'))),
      );
    } else if (name == story) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Story Screen'))),
      );
    } else if (name == pattern) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Pattern Screen'))),
      );
    } else if (name == tutorial) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Tutorial Screen'))),
      );
    } else if (name == settings) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Settings Screen'))),
      );
    } else if (name == profile) {
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Profile Screen'))),
      );
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for $name'),
          ),
        ),
      );
    }
  }
} 