import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/story_engine_service.dart';
import '../services/story_navigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_builder.dart';
import '../widgets/story_card.dart';
import '../widgets/animated_background.dart';
import '../models/story_model.dart';
import '../models/pattern_difficulty.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  bool _isLoading = true;
  StoryModel? _introStory;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    _loadIntroductoryStory();
  }

  Future<void> _loadIntroductoryStory() async {
    try {
      final storyEngine = Provider.of<StoryEngineService>(context, listen: false);
      final story = await storyEngine.generateStory(
        storyId: 'intro_tutorial',
        difficulty: PatternDifficulty.basic,
        targetConcepts: ['app_introduction', 'basic_blocks'],
        language: 'en',
      );

      if (mounted) {
        setState(() {
          _introStory = story;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading intro story: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startIntroductoryStory() async {
    if (_introStory == null) return;
    
    final navigation = Provider.of<StoryNavigationService>(context, listen: false);
    await navigation.startStory(_introStory!.startNode.id);
    
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/story');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(
            backgroundId: 'welcome_background',
          ),
          ResponsiveBuilder(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildMainStoryCard(),
            const SizedBox(height: 24),
            _buildFeatureCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMainStoryCard(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: _buildFeatureCards(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 64),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildMainStoryCard(),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildFeatureCards(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/characters/kweku_welcome.png',
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 200,
              color: AppTheme.kenteGold,
            );
          },
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            children: [
              Text(
                'Welcome to Kente Codeweaver',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.kenteGold,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join Kweku on a journey through code and culture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStoryCard() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StoryCard(
      title: 'Begin Your Journey',
      description: 'Start with an introduction to the world of Kente patterns and coding blocks',
      image: 'assets/images/story/intro_preview.png',
      isLocked: false,
      onTap: _startIntroductoryStory,
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFeatureCard(
          icon: Icons.code,
          title: 'Visual Block Programming',
          description: 'Create patterns using simple, visual blocks',
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.palette,
          title: 'Cultural Learning',
          description: 'Discover the art of Kente weaving',
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.school,
          title: 'Interactive Stories',
          description: 'Learn through modern Ananse tales',
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.kenteGold, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
