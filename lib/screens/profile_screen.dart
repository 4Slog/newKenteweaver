import 'package:flutter/material.dart';
import '../models/pattern_difficulty.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../extensions/breadcrumb_extensions.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (!appState.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Add breadcrumb navigation
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: BreadcrumbNavigation(
                  items: [
                    context.getHomeBreadcrumb(),
                    BreadcrumbItem(
                      label: 'Profile',
                      fallbackIcon: Icons.person,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProfileHeader(context, appState),
                    const SizedBox(height: 24),
                    _buildProgressSection(context, appState),
                    const SizedBox(height: 24),
                    _buildAchievementsSection(context, appState),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppStateProvider appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.kenteGold,
              child: Icon(
                Icons.person,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appState.userName ?? 'Guest User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Level: ${appState.currentDifficulty.toString().split('.').last}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, AppStateProvider appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              context,
              'Patterns',
              0.7,
              PatternDifficulty.basic,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              context,
              'Stories',
              0.5,
              PatternDifficulty.intermediate,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              context,
              'Challenges',
              0.3,
              PatternDifficulty.advanced,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double progress,
    PatternDifficulty difficulty,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.getDifficultyColor(context, difficulty.toString().split('.').last),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, AppStateProvider appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAchievementBadge(
                  context,
                  'Pattern Master',
                  Icons.star,
                  PatternDifficulty.expert,
                ),
                _buildAchievementBadge(
                  context,
                  'Story Explorer',
                  Icons.book,
                  PatternDifficulty.intermediate,
                ),
                _buildAchievementBadge(
                  context,
                  'Challenge Champion',
                  Icons.emoji_events,
                  PatternDifficulty.advanced,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(
    BuildContext context,
    String title,
    IconData icon,
    PatternDifficulty difficulty,
  ) {
    final color = AppTheme.getDifficultyColor(context, difficulty.toString().split('.').last);
    return Tooltip(
      message: title,
      child: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
    );
  }
}
