import 'package:flutter/material.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../navigation/app_router.dart';

extension BuildContextExtensions on BuildContext {
  BreadcrumbItem getHomeBreadcrumb() {
    return BreadcrumbItem(
      label: 'Home',
      route: AppRouter.home,
      fallbackIcon: Icons.home,
      iconAsset: 'assets/images/navigation/home_breadcrumb.png',
    );
  }

  BreadcrumbItem getTutorialBreadcrumb({Map<String, dynamic>? arguments}) {
    return BreadcrumbItem(
      label: 'Tutorial',
      route: AppRouter.tutorial,
      fallbackIcon: Icons.school,
      iconAsset: 'assets/images/navigation/tutorial_breadcrumb.png',
      arguments: arguments,
    );
  }

  BreadcrumbItem getStoryBreadcrumb({Map<String, dynamic>? arguments}) {
    return BreadcrumbItem(
      label: 'Story',
      route: AppRouter.story,
      fallbackIcon: Icons.auto_stories,
      iconAsset: 'assets/images/navigation/story_breadcrumb.png',
      arguments: arguments,
    );
  }

  BreadcrumbItem getChallengeBreadcrumb({Map<String, dynamic>? arguments}) {
    return BreadcrumbItem(
      label: 'Challenge',
      route: AppRouter.challenge,
      fallbackIcon: Icons.sports_score,
      iconAsset: 'assets/images/navigation/challenge_breadcrumb.png',
      arguments: arguments,
    );
  }

  BreadcrumbItem getAchievementBreadcrumb({Map<String, dynamic>? arguments}) {
    return BreadcrumbItem(
      label: 'Achievements',
      route: AppRouter.achievements,
      fallbackIcon: Icons.emoji_events,
      iconAsset: 'assets/images/navigation/achievement_breadcrumb.png',
      arguments: arguments,
    );
  }
  
  BreadcrumbItem getSettingsBreadcrumb() {
    return BreadcrumbItem(
      label: 'Settings',
      route: AppRouter.settings,
      fallbackIcon: Icons.settings,
    );
  }
  
  BreadcrumbItem getWeavingBreadcrumb({Map<String, dynamic>? arguments}) {
    return BreadcrumbItem(
      label: 'Weaving',
      route: AppRouter.weaving,
      fallbackIcon: Icons.grid_on,
      iconAsset: 'assets/images/navigation/weaving_breadcrumb.png',
      arguments: arguments,
    );
  }
}
