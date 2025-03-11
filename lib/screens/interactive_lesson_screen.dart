import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/lesson_model.dart';
import '../widgets/smart_workspace.dart';
import '../widgets/pattern_preview.dart';

class InteractiveLessonScreen extends StatefulWidget {
  final LessonModel lesson;

  const InteractiveLessonScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<InteractiveLessonScreen> createState() => _InteractiveLessonScreenState();
}

class _InteractiveLessonScreenState extends State<InteractiveLessonScreen> {
  late BlockCollection blockCollection;
  
  Map<String, dynamic> currentPattern = {
    'scale': 1.0,
    'elements': [],
  };

  @override
  void initState() {
    super.initState();
    // Convert lesson blocks to BlockCollection
    final lessonBlocks = (widget.lesson.content['blocks'] as List<dynamic>?)
            ?.map((block) => block as Map<String, dynamic>)
            .toList() ??
        [];
    blockCollection = BlockCollection.fromLegacyBlocks(lessonBlocks);
  }

  void _handlePatternUpdated(Map<String, dynamic> pattern) {
    setState(() {
      currentPattern = pattern;
    });
  }

  void _handleBlockSelected(Block block) {
    setState(() {
      // Handle block selection
    });
  }

  void _handleWorkspaceChanged() {
    setState(() {
      // Update workspace state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SmartWorkspace(
              blockCollection: blockCollection,
              difficulty: widget.lesson.difficulty,
              onBlockSelected: _handleBlockSelected,
              onWorkspaceChanged: _handleWorkspaceChanged,
            ),
          ),
          const VerticalDivider(),
          Expanded(
            flex: 3,
            child: PatternPreview(
              currentPattern: currentPattern,
              onPatternUpdated: _handlePatternUpdated,
            ),
          ),
        ],
      ),
    );
  }
}
