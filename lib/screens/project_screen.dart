// project_screen.dart

import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../models/pattern_difficulty.dart';
import '../widgets/smart_workspace.dart';
import '../widgets/pattern_preview.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late BlockCollection blockCollection;

  Map<String, dynamic> currentPattern = {
    'scale': 1.0,
    'elements': [],
  };

  @override
  void initState() {
    super.initState();
    // Initialize with project blocks converted to BlockCollection
    blockCollection = BlockCollection.fromLegacyBlocks([
      {
        'id': 'project1',
        'name': 'Project Pattern',
        'type': 'Pattern',
        'content': {'shape': 'square', 'color': 'red'},
      },
    ]);
  }

  void _handleBlockSelected(Block block) {
    setState(() {
      // Handle block selection (now takes Block instead of String)
    });
  }

  void _handleWorkspaceChanged() {
    setState(() {
      // Update workspace state
    });
  }

  void _handlePatternUpdated(Map<String, dynamic> pattern) {
    setState(() {
      currentPattern = pattern;
    });
  }

  void _handleDelete(String blockId) {
    setState(() {
      blockCollection.removeBlock(blockId);
    });
  }

  void _handleValueChanged(String blockId, String value) {
    setState(() {
      final block = blockCollection.getBlockById(blockId);
      if (block != null) {
        final updatedBlock = block.copyWith(
          properties: {...block.properties, 'value': value},
        );
        // Instead of using updateBlock, directly update the block in the collection
        final index = blockCollection.blocks.indexWhere((b) => b.id == blockId);
        if (index != -1) {
          blockCollection.blocks[index] = updatedBlock;
        }
      }
    });
  }

  void _handleBlocksConnected(
      String sourceBlockId,
      String sourceConnectionId,
      String targetBlockId,
      String targetConnectionId,
      ) {
    final result = blockCollection.connectBlocks(
      sourceBlockId,
      sourceConnectionId,
      targetBlockId,
      targetConnectionId,
    );

    if (result) {
      _handleWorkspaceChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SmartWorkspace(
              blockCollection: blockCollection,
              difficulty: PatternDifficulty.basic,
              onBlockSelected: _handleBlockSelected,
              onWorkspaceChanged: _handleWorkspaceChanged,
              onDelete: _handleDelete,
              onValueChanged: _handleValueChanged,
              onBlocksConnected: _handleBlocksConnected,
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