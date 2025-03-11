import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kente_codeweaver/main.dart' as app;
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/models/story_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tutorial Flow Integration Tests', () {
    testWidgets('Complete tutorial journey', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify welcome screen
      expect(find.text('Welcome to Kente Codeweaver'), findsOneWidget);
      expect(find.text('Begin Your Journey'), findsOneWidget);

      // Start tutorial
      await tester.tap(find.text('Begin Your Journey'));
      await tester.pumpAndSettle();

      // Verify introduction story screen
      expect(find.text('Welcome to Kente Codeweaver!'), findsOneWidget);
      expect(find.byType(CharacterAvatar), findsOneWidget);

      // Progress through introduction
      await _progressThroughStory(tester);

      // Verify first challenge screen
      expect(find.text('Your First Pattern'), findsOneWidget);
      expect(find.byType(BlocksWorkspace), findsOneWidget);

      // Complete first pattern challenge
      await _completeFirstChallenge(tester);

      // Verify completion and rewards
      expect(find.text('Congratulations!'), findsOneWidget);
      expect(find.text('Pattern Unlocked'), findsOneWidget);

      // Continue to next story section
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify cultural context
      expect(find.text('The Art of Kente'), findsOneWidget);
      await _progressThroughStory(tester);

      // Complete tutorial
      expect(find.text('Tutorial Complete'), findsOneWidget);
      await tester.tap(find.text('Start Your Journey'));
      await tester.pumpAndSettle();

      // Verify navigation to main story
      expect(find.text('Chapter 1: First Threads'), findsOneWidget);
    });
  });
}

Future<void> _progressThroughStory(WidgetTester tester) async {
  while (find.byType(StoryChoicePanel).evaluate().isNotEmpty) {
    final choices = find.byType(StoryChoice);
    if (choices.evaluate().isEmpty) break;

    // Always choose the first option for testing
    await tester.tap(choices.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Wait for animations and content to load
    await tester.pumpAndSettle();
  }
}

Future<void> _completeFirstChallenge(WidgetTester tester) async {
  // Find the pattern block in toolbox
  final patternBlock = find.text('Pattern').first;
  final workspace = find.byType(BlocksWorkspace);
  
  // Drag pattern block to workspace
  final patternCenter = tester.getCenter(patternBlock);
  final workspaceCenter = tester.getCenter(workspace);
  await tester.dragFrom(patternCenter, workspaceCenter - patternCenter);
  await tester.pumpAndSettle();

  // Find the loop block
  final loopBlock = find.text('Loop').first;
  
  // Drag loop block to connect with pattern
  final loopCenter = tester.getCenter(loopBlock);
  final targetCenter = workspaceCenter + const Offset(0, -50);
  await tester.dragFrom(loopCenter, targetCenter - loopCenter);
  await tester.pumpAndSettle();

  // Set loop count to 4
  await tester.tap(find.byIcon(Icons.edit));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '4');
  await tester.tap(find.text('Apply'));
  await tester.pumpAndSettle();

  // Run pattern
  await tester.tap(find.text('Run'));
  await tester.pumpAndSettle();

  // Wait for pattern generation and validation
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
} 