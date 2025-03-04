import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_builder.dart';
import '../l10n/messages.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  int _currentStep = 0;
  String? _translatedWelcome;
  final List<String> _supportedLanguages = ['en', 'fr', 'tw'];

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
    _translateWelcomeMessage();
  }

  Future<void> _translateWelcomeMessage() async {
    try {
      final model = Provider.of<GenerativeModel>(context, listen: false);
      final prompt = '''
      Translate the following welcome message to French (fr) and Twi (tw):
      
      English: "Welcome to Kente Codeweaver - Where tradition meets technology"
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final translations = response.text?.split('\n') ?? [];

      setState(() {
        _translatedWelcome = translations.join('\n');
      });
    } catch (e) {
      debugPrint('Translation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildHeader(),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _buildContent()),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildHeader(),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildContent()),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/story/background_pattern.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/characters/ananse_teaching.png',
            height: 200,
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeInAnimation,
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).welcomeMessage,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.kenteGold,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_translatedWelcome != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _translatedWelcome!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOnboardingStep(),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildOnboardingStep() {
    final steps = [
      _buildWelcomeStep(),
      _buildTutorialStep(),
      _buildCulturalStep(),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: steps[_currentStep],
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      key: const ValueKey('welcome'),
      children: [
        Image.asset(
          'assets/images/tutorial/basic_pattern_explanation.png',
          height: 200,
        ),
        const SizedBox(height: 24),
        Text(
          'Learn coding through the art of Kente weaving',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Discover the beauty of traditional patterns while mastering programming concepts',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTutorialStep() {
    return Column(
      key: const ValueKey('tutorial'),
      children: [
        Image.asset(
          'assets/images/tutorial/loop_explanation.png',
          height: 200,
        ),
        const SizedBox(height: 24),
        Text(
          'Interactive Learning Experience',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Use visual blocks to create patterns and learn coding concepts',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCulturalStep() {
    return Column(
      key: const ValueKey('cultural'),
      children: [
        Image.asset(
          'assets/images/tutorial/color_meaning_diagram.png',
          height: 200,
        ),
        const SizedBox(height: 24),
        Text(
          'Rich Cultural Heritage',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Learn about the cultural significance of patterns and colors',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep == index
                ? AppTheme.kenteGold
                : AppTheme.kenteGold.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: Text(AppLocalizations.of(context).previous),
            )
          else
            const SizedBox(width: 80),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep++;
                });
              } else {
                Navigator.pushReplacementNamed(context, '/tutorial');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kenteGold,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: Text(
              _currentStep < 2 ? AppLocalizations.of(context).next : AppLocalizations.of(context).start,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
