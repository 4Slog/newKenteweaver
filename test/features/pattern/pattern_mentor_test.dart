import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/widgets/ai_mentor_widget.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/services/story_engine_service.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'ai_mentor_widget_test.mocks.dart';

@GenerateMocks([StoryEngineService])
void main() {
  late MockStoryEngineService mockStoryEngine;

  setUp(() {
    mockStoryEngine = MockStoryEngineService();
  });

  Future<void> pumpAIMentorWidget(
    WidgetTester tester, {
    List<Map<String, dynamic>> blocks = const [],
    PatternDifficulty difficulty = PatternDifficulty.basic,
    bool isVisible = true,
    VoidCallback? onClose,
    String mentorCharacter = "Kwaku Ananse",
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StoryEngineService>.value(
              value: mockStoryEngine,
            ),
          ],
          child: Material(
            child: AIMentorWidget(
              blocks: blocks,
              difficulty: difficulty,
              isVisible: isVisible,
              onClose: onClose,
              mentorCharacter: mentorCharacter,
            ),
          ),
        ),
      ),
    );
  }

  group('AIMentorWidget', () {
    testWidgets('renders correctly when visible', (WidgetTester tester) async {
      await pumpAIMentorWidget(tester);

      expect(find.byType(AIMentorWidget), findsOneWidget);
      expect(find.text('Kwaku Ananse'), findsOneWidget);
      expect(find.text('AI Mentor - Basic Level'), findsOneWidget);
    });

    testWidgets('does not render when not visible', (WidgetTester tester) async {
      await pumpAIMentorWidget(tester, isVisible: false);

      expect(find.byType(AIMentorWidget), findsNothing);
    });

    testWidgets('shows empty workspace hint when no blocks',
        (WidgetTester tester) async {
      await pumpAIMentorWidget(tester);

      expect(
        find.text('Welcome! Start creating your pattern by adding blocks from the toolbox.'),
        findsOneWidget,
      );
    });

    testWidgets('shows story context when available', (WidgetTester tester) async {
      when(mockStoryEngine.currentStory).thenReturn(
        StoryModel(
          id: 'test_story',
          title: 'Test Story',
          description: 'Test Description',
          difficulty: PatternDifficulty.basic,
          learningConcepts: ['test_concept'],
          startNode: StoryNode(
            id: 'test_node',
            content: 'Try creating a basic pattern',
            backgroundId: 'test_bg',
            characterId: 'test_char',
            backgroundMusic: 'test_music.mp3',
            choices: [],
          ),
          nodes: {},
        ),
      );

      when(mockStoryEngine.currentNode).thenReturn(
        StoryNode(
          id: 'test_node',
          content: 'Try creating a basic pattern',
          backgroundId: 'test_bg',
          characterId: 'test_char',
          backgroundMusic: 'test_music.mp3',
          choices: [],
        ),
      );

      await pumpAIMentorWidget(
        tester,
        blocks: [
          {'type': 'pattern', 'id': 'test_block'},
        ],
      );

      expect(
        find.text('Based on the current story context, try Try creating a basic pattern'),
        findsOneWidget,
      );
    });

    testWidgets('handles close button tap', (WidgetTester tester) async {
      bool closeCalled = false;
      await pumpAIMentorWidget(
        tester,
        onClose: () => closeCalled = true,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closeCalled, isTrue);
    });

    testWidgets('expands and collapses on tap', (WidgetTester tester) async {
      await pumpAIMentorWidget(tester);

      // Initially collapsed
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);

      // Tap to expand
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });
  });
} 