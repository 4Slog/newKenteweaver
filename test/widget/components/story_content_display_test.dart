import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/widgets/story_content_display.dart';
import 'package:kente_codeweaver/services/tts_service.dart';
import 'story_content_display_test.mocks.dart';

@GenerateMocks([TTSService])
void main() {
  late MockTTSService mockTTS;

  setUp(() {
    mockTTS = MockTTSService();
  });

  Future<void> pumpStoryContent(
    WidgetTester tester, {
    required List<Map<String, dynamic>> contentBlocks,
    bool enableTTS = true,
    bool autoAdvance = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<TTSService>.value(
          value: mockTTS,
          child: Material(
            child: StoryContentDisplay(
              contentBlocks: contentBlocks,
              enableTTS: enableTTS,
              autoAdvance: autoAdvance,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('displays narration content correctly', (WidgetTester tester) async {
    final contentBlocks = [
      {
        'type': 'narration',
        'text': 'This is a test narration.',
      },
    ];

    await pumpStoryContent(
      tester,
      contentBlocks: contentBlocks,
    );

    expect(find.text('This is a test narration.'), findsOneWidget);
  });

  testWidgets('displays dialogue with speaker correctly', (WidgetTester tester) async {
    final contentBlocks = [
      {
        'type': 'dialogue',
        'text': 'Hello, I am Kweku!',
        'speaker': 'Kweku',
      },
    ];

    await pumpStoryContent(
      tester,
      contentBlocks: contentBlocks,
    );

    expect(find.text('Kweku'), findsOneWidget);
    expect(find.text('Hello, I am Kweku!'), findsOneWidget);
  });

  testWidgets('displays cultural context with styling', (WidgetTester tester) async {
    final contentBlocks = [
      {
        'type': 'cultural_context',
        'text': 'This pattern represents wisdom.',
      },
    ];

    await pumpStoryContent(
      tester,
      contentBlocks: contentBlocks,
    );

    expect(find.text('This pattern represents wisdom.'), findsOneWidget);
    // Verify styling
    final textWidget = tester.widget<Text>(
      find.text('This pattern represents wisdom.'),
    );
    expect(textWidget.style?.fontStyle, equals(FontStyle.italic));
  });

  group('Text-to-Speech', () {
    testWidgets('speaks content when TTS is enabled', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'Test speech.',
          'speaker': 'Kweku',
        },
      ];

      when(mockTTS.speak('Test speech.')).thenAnswer((_) async {});

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
        enableTTS: true,
      );

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      verify(mockTTS.speak('Test speech.')).called(1);
    });

    testWidgets('does not speak when TTS is disabled', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'Test speech.',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
        enableTTS: false,
      );

      verifyNever(mockTTS.speak('Test speech.'));
    });
  });

  group('Auto-advance', () {
    testWidgets('advances to next block automatically when enabled', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'First block',
          'speaker': 'Kweku',
        },
        {
          'type': 'dialogue',
          'text': 'Second block',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
        autoAdvance: true,
      );

      expect(find.text('First block'), findsOneWidget);
      expect(find.text('Second block'), findsNothing);

      // Wait for auto-advance
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('First block'), findsNothing);
      expect(find.text('Second block'), findsOneWidget);
    });

    testWidgets('does not auto-advance when disabled', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'First block',
          'speaker': 'Kweku',
        },
        {
          'type': 'dialogue',
          'text': 'Second block',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
        autoAdvance: false,
      );

      expect(find.text('First block'), findsOneWidget);
      expect(find.text('Second block'), findsNothing);

      // Wait longer than auto-advance time
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Should still show first block
      expect(find.text('First block'), findsOneWidget);
      expect(find.text('Second block'), findsNothing);
    });
  });

  group('Navigation Controls', () {
    testWidgets('shows navigation controls for multiple blocks', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'First block',
          'speaker': 'Kweku',
        },
        {
          'type': 'dialogue',
          'text': 'Second block',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('disables back button on first block', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'First block',
          'speaker': 'Kweku',
        },
        {
          'type': 'dialogue',
          'text': 'Second block',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
      );

      final backButton = tester.widget<IconButton>(
        find.byIcon(Icons.arrow_back),
      );
      expect(backButton.onPressed, isNull);
    });

    testWidgets('disables forward button on last block', (WidgetTester tester) async {
      final contentBlocks = [
        {
          'type': 'dialogue',
          'text': 'Only block',
          'speaker': 'Kweku',
        },
      ];

      await pumpStoryContent(
        tester,
        contentBlocks: contentBlocks,
      );

      final forwardButton = tester.widget<IconButton>(
        find.byIcon(Icons.arrow_forward),
      );
      expect(forwardButton.onPressed, isNull);
    });
  });
} 