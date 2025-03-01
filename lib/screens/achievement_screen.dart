import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../extensions/breadcrumb_extensions.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Patterns'),
            Tab(text: 'Challenges'),
            Tab(text: 'Milestones'),
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
                context.getAchievementBreadcrumb(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'all';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Unlocked'),
                  selected: _filter == 'unlocked',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'unlocked';
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Locked'),
                  selected: _filter == 'locked',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filter = 'locked';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAchievementGrid(userProvider, 'all'),
                _buildAchievementGrid(userProvider, 'pattern'),
                _buildAchievementGrid(userProvider, 'challenge'),
                _buildAchievementGrid(userProvider, 'milestone'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(UserProvider userProvider, String category) {
    final achievements = _getFilteredAchievements(userProvider, category);

    if (achievements.isEmpty) {
      return const Center(
        child: Text(
          'No achievements found',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(
          achievement,
          userProvider.hasAchievement(achievement.id),
          achievement.progress,
        );
      },
    );
  }

  Widget _buildAchievementCard(
      Achievement achievement,
      bool isUnlocked,
      double? progress,
      ) {
    return GestureDetector(
      onTap: () {
        _showAchievementDetails(achievement, isUnlocked);
      },
      child: Card(
        elevation: isUnlocked ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnlocked
                ? AppTheme.kenteGold
                : Colors.grey.withOpacity(0.3),
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isUnlocked
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.kenteGold.withOpacity(0.2),
              ],
            )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge image with overlay if locked
              Stack(
                alignment: Alignment.center,
                children: [
                  // Badge image
                  _buildBadgeImage(achievement, isUnlocked),

                  // Lock overlay
                  if (!isUnlocked)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Progress indicator if available
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked
                          ? AppTheme.kenteGold
                          : Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeImage(Achievement achievement, bool isUnlocked) {
    Widget imageWidget;

    try {
      imageWidget = Image.asset(
        achievement.imageAsset,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage(achievement);
        },
      );
    } catch (e) {
      imageWidget = _buildFallbackImage(achievement);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isUnlocked ? 1.0 : 0.3,
      child: imageWidget,
    );
  }

  Widget _buildFallbackImage(Achievement achievement) {
    // Default icons based on achievement ID patterns
    IconData icon = Icons.emoji_events;
    Color color = AppTheme.kenteGold;

    if (achievement.id.contains('pattern')) {
      icon = Icons.grid_on;
      color = Colors.blue;
    } else if (achievement.id.contains('challenge')) {
      icon = Icons.sports;
      color = Colors.orange;
    } else if (achievement.id.contains('story')) {
      icon = Icons.book;
      color = Colors.green;
    } else if (achievement.id.contains('master')) {
      icon = Icons.workspace_premium;
      color = Colors.purple;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement, bool isUnlocked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadgeImage(achievement, isUnlocked),
              const SizedBox(height: 16),
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!isUnlocked)
                Text(
                  achievement.hint ?? 'Keep exploring to unlock this achievement!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Achievement> _getFilteredAchievements(UserProvider userProvider, String category) {
    var allAchievements = _getAllAchievements();

    // Filter by category
    if (category != 'all') {
      allAchievements = allAchievements.where(
              (a) => a.id.contains(category)
      ).toList();
    }

    // Filter by unlock status
    if (_filter == 'unlocked') {
      allAchievements = allAchievements.where(
              (a) => userProvider.hasAchievement(a.id)
      ).toList();
    } else if (_filter == 'locked') {
      allAchievements = allAchievements.where(
              (a) => !userProvider.hasAchievement(a.id)
      ).toList();
    }

    return allAchievements;
  }

  List<Achievement> _getAllAchievements() {
    // In a real app, this would come from a database or constants file
    return [
      Achievement(
        id: 'pattern_first',
        title: 'First Pattern',
        description: 'Create your first Kente pattern',
        imageAsset: 'assets/images/achievements/pattern_first.png',
      ),
      Achievement(
        id: 'pattern_10',
        title: 'Pattern Explorer',
        description: 'Create 10 different patterns',
        imageAsset: 'assets/images/achievements/pattern_10.png',
        progress: 0.4,
        hint: 'Try creating more patterns in the Coding Screen',
      ),
      Achievement(
        id: 'pattern_master',
        title: 'Pattern Master',
        description: 'Create all basic pattern types',
        imageAsset: 'assets/images/achievements/pattern_master.png',
      ),
      Achievement(
        id: 'challenge_first',
        title: 'Challenge Accepted',
        description: 'Complete your first challenge',
        imageAsset: 'assets/images/achievements/challenge_first.png',
      ),
      Achievement(
        id: 'challenge_5',
        title: 'Challenge Enthusiast',
        description: 'Complete 5 challenges',
        imageAsset: 'assets/images/achievements/challenge_5.png',
        progress: 0.6,
      ),
      Achievement(
        id: 'challenge_advanced',
        title: 'Advanced Challenger',
        description: 'Complete an advanced difficulty challenge',
        imageAsset: 'assets/images/achievements/challenge_advanced.png',
        hint: 'Try challenges in the Advanced section',
      ),
      Achievement(
        id: 'milestone_level_5',
        title: 'Level 5 Reached',
        description: 'Reach level 5 in your Kente CodeWeaver journey',
        imageAsset: 'assets/images/achievements/milestone_level_5.png',
      ),
      Achievement(
        id: 'milestone_level_10',
        title: 'Level 10 Reached',
        description: 'Reach level 10 in your Kente CodeWeaver journey',
        imageAsset: 'assets/images/achievements/milestone_level_10.png',
      ),
      Achievement(
        id: 'milestone_streak_7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day learning streak',
        imageAsset: 'assets/images/achievements/milestone_streak_7.png',
        hint: 'Log in every day to maintain your streak',
      ),
    ];
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final double? progress;
  final String? hint;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.progress,
    this.hint,
  });
}
