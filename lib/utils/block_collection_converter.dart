import '../models/block_model.dart' as block_model;
import '../models/learning_progress_model.dart' as learning_model;
import 'package:flutter/material.dart';

/// Utility class to convert between different BlockCollection types
class BlockCollectionConverter {
  /// Convert from block_model.BlockCollection to learning_model.BlockCollection
  static learning_model.BlockCollection toLearningModel(block_model.BlockCollection collection) {
    return learning_model.BlockCollection(
      blocks: collection.blocks.map((block) => {
        'id': block.id,
        'name': block.name,
        'type': block.type.toString().split('.').last,
        'subtype': block.subtype,
        'properties': block.properties,
        'connections': block.connections.map((conn) => {
          'id': conn.id,
          'type': conn.type.toString().split('.').last,
          'connectedToId': conn.connectedToId,
        }).toList(),
      }).toList(),
      pattern: collection.metadata['pattern'] ?? '',
    );
  }

  /// Convert from learning_model.BlockCollection to block_model.BlockCollection
  static block_model.BlockCollection toBlockModel(learning_model.BlockCollection collection) {
    return block_model.BlockCollection(
      blocks: collection.blocks.map((blockData) {
        final Map<String, dynamic> data = blockData as Map<String, dynamic>;
        return block_model.Block(
          id: data['id'] as String,
          name: data['name'] as String,
          description: data['description'] as String? ?? 'Block description',
          type: block_model.BlockType.values.firstWhere(
            (t) => t.toString().split('.').last == data['type'],
            orElse: () => block_model.BlockType.pattern,
          ),
          subtype: data['subtype'] as String? ?? '',
          properties: data['properties'] as Map<String, dynamic>? ?? {},
          iconPath: data['iconPath'] as String? ?? 'assets/images/blocks/default_icon.png',
          colorHex: data['colorHex'] as String? ?? '#808080',
          connections: (data['connections'] as List<dynamic>?)?.map((connData) {
            final Map<String, dynamic> conn = connData as Map<String, dynamic>;
            return block_model.BlockConnection(
              id: conn['id'] as String,
              name: conn['name'] as String? ?? 'Connection',
              type: block_model.ConnectionType.values.firstWhere(
                (t) => t.toString().split('.').last == conn['type'],
                orElse: () => block_model.ConnectionType.none,
              ),
              position: const Offset(0.5, 0.5),
              connectedToId: conn['connectedToId'] as String?,
            );
          }).toList() ?? [],
          position: data['position'] != null
            ? Offset(
                (data['position']['x'] as num).toDouble(),
                (data['position']['y'] as num).toDouble(),
              )
            : Offset.zero,
          size: data['size'] != null
            ? Size(
                (data['size']['width'] as num).toDouble(),
                (data['size']['height'] as num).toDouble(),
              )
            : const Size(120, 120),
        );
      }).toList(),
      metadata: {'pattern': collection.pattern},
    );
  }
} 