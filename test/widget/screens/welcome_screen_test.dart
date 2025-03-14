import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/screens/welcome_screen.dart';
import 'package:kente_codeweaver/services/story_engine_service.dart';
import 'package:kente_codeweaver/services/story_navigation_service.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';

@GenerateMocks([StoryEngineService, StoryNavigationService])
void main() {
  late MockStoryEngineService mockStoryEngine;
  late MockStoryNavigationService mockNavigation;

  setUp(() {
    mockStoryEngine = MockStoryEngineService();
    mockNavigation = MockStoryNavigationService();
  });

  Future<void> pumpWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StoryEngineService>.value(value: mockStoryEngine),
          Provider<StoryNavigationService>.value(value: mockNavigation),
        ],
        child: MaterialApp(
          home: const WelcomeScreen(),
        ),
      ),
    );
  }

  testWidgets('displays welcome message and Kweku image', (WidgetTester tester) async {
    await pumpWelcomeScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Kente Codeweaver'), findsOneWidget);
    expect(find.text('Join Kweku on a journey through code and culture'), findsOneWidget);
    
    // Verify Kweku image or fallback icon is displayed
    expect(
      find.byWidgetPredicate((widget) => 
        widget is Image && widget.image.toString().contains('kweku_welcome.png') ||
        widget is Icon && widget.icon == Icons.person
      ),
      findsOneWidget,
    );
  });

  testWidgets('displays feature cards', (WidgetTester tester) async {
    await pumpWelcomeScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Visual Block Programming'), findsOneWidget);
    expect(find.text('Cultural Learning'), findsOneWidget);
    expect(find.text('Interactive Stories'), findsOneWidget);
  });

  testWidgets('loads and displays story card', (WidgetTester tester) async {
    final introStory = StoryModel(
      id: 'intro_tutorial',
      title: 'A Journey Through Kente Patterns',
      description: 'Learn coding concepts through traditional Kente weaving',
      difficulty: PatternDifficulty.basic,
      learningConcepts: ['app_introduction', 'basic_blocks'],
      startNode: StoryNode(
        id: 'intro_start',
        content: 'Welcome message',
        backgroundId: 'intro_background',
        characterId: 'kweku',
        backgroundMusic: 'story_theme.mp3',
        choices: [],
      ),
      nodes: {},
    );

    when(mockStoryEngine.generateStory(
      storyId: 'intro_tutorial',
      difficulty: PatternDifficulty.basic,
      targetConcepts: ['app_introduction', 'basic_blocks'],
      language: 'en',
    )).thenAnswer((_) async => introStory);

    await pumpWelcomeScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Begin Your Journey'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('starts story on card tap', (WidgetTester tester) async {
    final introStory = StoryModel(
      id: 'intro_tutorial',
      title: 'Test Story',
      description: 'Test Description',
      difficulty: PatternDifficulty.basic,
      learningConcepts: ['test'],
      startNode: StoryNode(
        id: 'start',
        content: 'Test content',
        backgroundId: 'test_bg',
        characterId: 'kweku',
        backgroundMusic: 'test.mp3',
        choices: [],
      ),
      nodes: {},
    );

    when(mockStoryEngine.generateStory(
      storyId: 'intro_tutorial',
      difficulty: PatternDifficulty.basic,
      targetConcepts: ['app_introduction', 'basic_blocks'],
      language: 'en',
    )).thenAnswer((_) async => introStory);

    await pumpWelcomeScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin Your Journey'));
    await tester.pumpAndSettle();

    verify(mockNavigation.startStory('start')).called(1);
  });

  testWidgets('handles story loading error gracefully', (WidgetTester tester) async {
    when(mockStoryEngine.generateStory(
      storyId: 'intro_tutorial',
      difficulty: PatternDifficulty.basic,
      targetConcepts: ['app_introduction', 'basic_blocks'],
      language: 'en',
    )).thenThrow(Exception('Test error'));

    await pumpWelcomeScreen(tester);
    await tester.pumpAndSettle();

    // Should still show the main UI elements
    expect(find.text('Welcome to Kente Codeweaver'), findsOneWidget);
    expect(find.text('Join Kweku on a journey through code and culture'), findsOneWidget);
  });
} 