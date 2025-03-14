import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/widgets/blocks_workspace.dart';
import 'package:kente_codeweaver/widgets/blocks_toolbox.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/services/pattern_render_service.dart';

@GenerateMocks([PatternRenderService])
void main() {
  late MockPatternRenderService mockRenderService;

  setUp(() {
    mockRenderService = MockPatternRenderService();
  });

  Future<void> pumpBlockWorkspace(
    WidgetTester tester, {
    List<Block>? initialBlocks,
    bool showAnalysis = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<PatternRenderService>.value(
          value: mockRenderService,
          child: Material(
            child: BlocksWorkspace(
              initialBlocks: initialBlocks ?? [],
              showAnalysis: showAnalysis,
              onBlocksChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('Block Toolbox', () {
    testWidgets('displays available block types', (WidgetTester tester) async {
      await pumpBlockWorkspace(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BlocksToolbox), findsOneWidget);
      expect(find.text('Pattern'), findsOneWidget);
      expect(find.text('Loop'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('allows dragging blocks to workspace', (WidgetTester tester) async {
      await pumpBlockWorkspace(tester);
      await tester.pumpAndSettle();

      // Find and drag a pattern block
      final patternBlock = find.text('Pattern').first;
      final center = tester.getCenter(patternBlock);
      await tester.dragFrom(center, const Offset(100, 100));
      await tester.pumpAndSettle();

      // Verify block was added to workspace
      expect(find.byType(DraggableBlock), findsOneWidget);
    });
  });

  group('Block Connections', () {
    testWidgets('connects compatible blocks', (WidgetTester tester) async {
      final blocks = [
        Block(
          id: 'block1',
          type: BlockType.loop,
          position: const Offset(100, 100),
        ),
        Block(
          id: 'block2',
          type: BlockType.pattern,
          position: const Offset(200, 100),
        ),
      ];

      await pumpBlockWorkspace(tester, initialBlocks: blocks);
      await tester.pumpAndSettle();

      // Find and drag the second block to connect
      final block2 = find.byKey(const ValueKey('block2'));
      final block1Center = tester.getCenter(find.byKey(const ValueKey('block1')));
      await tester.dragFrom(
        tester.getCenter(block2),
        block1Center - tester.getCenter(block2),
      );
      await tester.pumpAndSettle();

      // Verify blocks are connected
      expect(find.byType(ConnectedBlock), findsWidgets);
    });

    testWidgets('prevents incompatible connections', (WidgetTester tester) async {
      final blocks = [
        Block(
          id: 'block1',
          type: BlockType.color,
          position: const Offset(100, 100),
        ),
        Block(
          id: 'block2',
          type: BlockType.color,
          position: const Offset(200, 100),
        ),
      ];

      await pumpBlockWorkspace(tester, initialBlocks: blocks);
      await tester.pumpAndSettle();

      // Try to connect incompatible blocks
      final block2 = find.byKey(const ValueKey('block2'));
      final block1Center = tester.getCenter(find.byKey(const ValueKey('block1')));
      await tester.dragFrom(
        tester.getCenter(block2),
        block1Center - tester.getCenter(block2),
      );
      await tester.pumpAndSettle();

      // Verify blocks remain unconnected
      expect(find.byType(ConnectedBlock), findsNothing);
    });
  });

  group('Block Analysis', () {
    testWidgets('shows analysis when enabled', (WidgetTester tester) async {
      await pumpBlockWorkspace(tester, showAnalysis: true);
      await tester.pumpAndSettle();

      expect(find.byType(BlockAnalysis), findsOneWidget);
    });

    testWidgets('updates analysis on block changes', (WidgetTester tester) async {
      final blocks = [
        Block(
          id: 'block1',
          type: BlockType.loop,
          position: const Offset(100, 100),
          parameters: {'count': 4},
        ),
      ];

      await pumpBlockWorkspace(tester, initialBlocks: blocks, showAnalysis: true);
      await tester.pumpAndSettle();

      // Verify analysis shows loop count
      expect(find.text('Repeats 4 times'), findsOneWidget);
    });
  });

  group('Block Deletion', () {
    testWidgets('allows deleting blocks', (WidgetTester tester) async {
      final blocks = [
        Block(
          id: 'block1',
          type: BlockType.pattern,
          position: const Offset(100, 100),
        ),
      ];

      await pumpBlockWorkspace(tester, initialBlocks: blocks);
      await tester.pumpAndSettle();

      // Long press to trigger delete
      await tester.longPress(find.byKey(const ValueKey('block1')));
      await tester.pumpAndSettle();

      // Tap delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify block was removed
      expect(find.byKey(const ValueKey('block1')), findsNothing);
    });

    testWidgets('deletes connected blocks correctly', (WidgetTester tester) async {
      final blocks = [
        Block(
          id: 'block1',
          type: BlockType.loop,
          position: const Offset(100, 100),
        ),
        Block(
          id: 'block2',
          type: BlockType.pattern,
          position: const Offset(100, 200),
          connections: {'input': 'block1'},
        ),
      ];

      await pumpBlockWorkspace(tester, initialBlocks: blocks);
      await tester.pumpAndSettle();

      // Delete the loop block
      await tester.longPress(find.byKey(const ValueKey('block1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify both blocks are removed
      expect(find.byKey(const ValueKey('block1')), findsNothing);
      expect(find.byKey(const ValueKey('block2')), findsNothing);
    });
  });
} 