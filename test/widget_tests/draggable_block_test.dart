import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/widgets/draggable_block.dart';

void main() {
  testWidgets('DraggableBlock renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () {},
          onDragEndSimple: () {},
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
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () => dragStarted = true,
          onDragEndSimple: () {},
        ),
      ),
    );

    await tester.drag(find.byType(DraggableBlock), const Offset(100, 100));
    expect(dragStarted, isTrue);
  });

  testWidgets('DraggableBlock handles drag end with details', (WidgetTester tester) async {
    DraggableDetails? dragDetails;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () {},
          onDragEndWithDetails: (details) => dragDetails = details,
          onDragEndSimple: () {},
        ),
      ),
    );

    await tester.drag(find.byType(DraggableBlock), const Offset(100, 100));
    expect(dragDetails, isNotNull);
  });

  testWidgets('DraggableBlock handles accept', (WidgetTester tester) async {
    String? acceptedData;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () {},
          onDragEndSimple: () {},
          onAccept: (details) => acceptedData = details.data,
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.byType(DraggableBlock)));
    await gesture.moveBy(const Offset(100, 100));
    await gesture.up();
    await tester.pump();

    expect(acceptedData, isNull); // No data accepted yet
  });

  testWidgets('DraggableBlock handles double tap', (WidgetTester tester) async {
    bool doubleTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () {},
          onDragEndSimple: () {},
          onDoubleTap: () => doubleTapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(DraggableBlock));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(DraggableBlock));
    await tester.pump();

    expect(doubleTapped, isTrue);
  });

  testWidgets('DraggableBlock respects locked state', (WidgetTester tester) async {
    bool dragStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DraggableBlock(
          child: Container(width: 100, height: 100),
          blockId: 'test_block',
          onDragStarted: () => dragStarted = true,
          onDragEndSimple: () {},
          isLocked: true,
        ),
      ),
    );

    await tester.drag(find.byType(Container), const Offset(100, 100));
    expect(dragStarted, isFalse);
  });
}
