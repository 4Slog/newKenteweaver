import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/widgets/draggable_block.dart';

void main() {
  final testBlock = Block(
    id: 'test_block',
    name: 'Test Block',
    description: 'A test block',
    type: BlockType.pattern,
    subtype: 'test_pattern',
    properties: {'value': 'test'},
    connections: [],
    iconPath: 'assets/images/blocks/test.png',
    colorHex: '#2196F3',
  );

  testWidgets('DraggableBlock renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          block: testBlock,
          onDragStarted: () {},
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(DraggableBlock), findsOneWidget);
  });

  testWidgets('DraggableBlock handles drag start', (WidgetTester tester) async {
    bool dragStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          block: testBlock,
          onDragStarted: () => dragStarted = true,
          onTap: () {},
        ),
      ),
    );

    await tester.drag(find.byType(DraggableBlock), const Offset(100, 100));
    expect(dragStarted, isTrue);
  });

  testWidgets('DraggableBlock handles drag end', (WidgetTester tester) async {
    bool dragEnded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          block: testBlock,
          onDragStarted: () {},
          onDragEndSimple: () => dragEnded = true,
          onTap: () {},
        ),
      ),
    );

    await tester.drag(find.byType(DraggableBlock), const Offset(100, 100));
    expect(dragEnded, isTrue);
  });

  testWidgets('DraggableBlock handles tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          block: testBlock,
          onDragStarted: () {},
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(DraggableBlock));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('DraggableBlock respects scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          block: testBlock,
          onDragStarted: () {},
          onTap: () {},
          scale: 2.0,
        ),
      ),
    );

    expect(find.byType(DraggableBlock), findsOneWidget);
  });
}
