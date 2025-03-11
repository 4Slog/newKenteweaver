import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/widgets/smart_workspace.dart';
import 'package:kente_codeweaver/widgets/connected_block.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/services/story_engine_service.dart';
import 'smart_workspace_test.mocks.dart';

@GenerateMocks([StoryEngineService])
void main() {
  late MockStoryEngineService mockStoryEngine;

  setUp(() {
    mockStoryEngine = MockStoryEngineService();
  });

  Future<void> pumpSmartWorkspace(
    WidgetTester tester, {
    required BlockCollection blockCollection,
    required PatternDifficulty difficulty,
    Function(Block)? onBlockSelected,
    VoidCallback? onWorkspaceChanged,
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
            child: SmartWorkspace(
              blockCollection: blockCollection,
              difficulty: difficulty,
              onBlockSelected: onBlockSelected ?? (_) {},
              onWorkspaceChanged: onWorkspaceChanged ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('SmartWorkspace Widget', () {
    testWidgets('renders correctly with empty block collection',
        (WidgetTester tester) async {
      final blockCollection = BlockCollection(blocks: []);

      await pumpSmartWorkspace(
        tester,
        blockCollection: blockCollection,
        difficulty: PatternDifficulty.basic,
      );

      expect(find.byType(SmartWorkspace), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows pattern preview dialog on FAB press',
        (WidgetTester tester) async {
      final blockCollection = BlockCollection(blocks: []);

      await pumpSmartWorkspace(
        tester,
        blockCollection: blockCollection,
        difficulty: PatternDifficulty.basic,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Pattern Preview'), findsOneWidget);
    });

    testWidgets('handles block selection', (WidgetTester tester) async {
      Block? selectedBlock;
      final block = Block(
        id: 'test_block',
        name: 'Test Block',
        description: 'Test Description',
        type: BlockType.pattern,
        subtype: 'basic',
        properties: {},
        connections: [],
        iconPath: 'assets/images/blocks/pattern.png',
        colorHex: '#000000',
      );

      final blockCollection = BlockCollection(blocks: [block]);

      await pumpSmartWorkspace(
        tester,
        blockCollection: blockCollection,
        difficulty: PatternDifficulty.basic,
        onBlockSelected: (block) => selectedBlock = block,
      );

      await tester.tap(find.byType(ConnectedBlock));
      await tester.pumpAndSettle();

      expect(selectedBlock, equals(block));
    });

    testWidgets('handles workspace changes', (WidgetTester tester) async {
      bool workspaceChanged = false;
      final block = Block(
        id: 'test_block',
        name: 'Test Block',
        description: 'Test Description',
        type: BlockType.pattern,
        subtype: 'basic',
        properties: {},
        connections: [],
        iconPath: 'assets/images/blocks/pattern.png',
        colorHex: '#000000',
      );

      final blockCollection = BlockCollection(blocks: [block]);

      await pumpSmartWorkspace(
        tester,
        blockCollection: blockCollection,
        difficulty: PatternDifficulty.basic,
        onWorkspaceChanged: () => workspaceChanged = true,
      );

      // Simulate block drag
      final blockFinder = find.byType(ConnectedBlock);
      final gesture = await tester.startGesture(tester.getCenter(blockFinder));
      await gesture.moveBy(const Offset(100, 100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(workspaceChanged, isTrue);
    });
  });
} 