import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

enum BlockType {
  pattern,
  color,
  structure,
  loop,
  row,
  column,
}

enum ConnectionType {
  input,
  output,
  both,
  none,
}

class BlockConnection {
  final String id;
  final String name;
  final ConnectionType type;
  final Offset position;
  String? connectedToId;

  BlockConnection({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.connectedToId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'position': {'x': position.dx, 'y': position.dy},
      'connectedToId': connectedToId,
    };
  }

  factory BlockConnection.fromJson(Map<String, dynamic> json) {
    return BlockConnection(
      id: json['id'],
      name: json['name'],
      type: ConnectionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ConnectionType.none,
      ),
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      connectedToId: json['connectedToId'],
    );
  }
}

class Block {
  final String id;
  final String name;
  final String description;
  final BlockType type;
  final String subtype;
  final Map<String, dynamic> properties;
  final List<BlockConnection> connections;
  final String iconPath;
  final Color color;

  Block({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.subtype,
    required this.properties,
    required this.connections,
    required this.iconPath,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'subtype': subtype,
      'properties': properties,
      'connections': connections.map((c) => c.toJson()).toList(),
      'iconPath': iconPath,
      'color': color.value.toString(),
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: BlockType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BlockType.pattern,
      ),
      subtype: json['subtype'],
      properties: json['properties'] ?? {},
      connections: (json['connections'] as List)
          .map((c) => BlockConnection.fromJson(c))
          .toList(),
      iconPath: json['iconPath'],
      color: Color(int.parse(json['color'])),
    );
  }

  factory Block.fromMap(Map<String, dynamic> map) {
    BlockType getTypeFromString(String typeStr) {
      if (typeStr.startsWith('shuttle_')) return BlockType.color;
      if (typeStr.contains('_pattern')) return BlockType.pattern;
      if (typeStr == 'loop_block') return BlockType.loop;
      if (typeStr == 'row_block') return BlockType.row;
      if (typeStr == 'column_block') return BlockType.column;
      return BlockType.structure;
    }

    final type = getTypeFromString(map['type']);

    // Default connections based on block type
    final connections = <BlockConnection>[];

    // Add input connection for most blocks
    if (type != BlockType.pattern && type != BlockType.color) {
      connections.add(BlockConnection(
        id: '${map['id']}_input',
        name: 'Input',
        type: ConnectionType.input,
        position: const Offset(0, 0.5),
      ));
    }

    // Add output connection for most blocks
    if (type != BlockType.structure) {
      connections.add(BlockConnection(
        id: '${map['id']}_output',
        name: 'Output',
        type: ConnectionType.output,
        position: const Offset(1, 0.5),
      ));
    }

    // For more complex blocks like loops, add multiple connections
    if (type == BlockType.loop) {
      connections.add(BlockConnection(
        id: '${map['id']}_body',
        name: 'Body',
        type: ConnectionType.output,
        position: const Offset(0.5, 1),
      ));
    }

    return Block(
      id: map['id'],
      name: map['name'] ?? 'Unnamed Block',
      description: map['description'] ?? '',
      type: type,
      subtype: map['type'],
      properties: map['content'] ?? {},
      connections: connections,
      iconPath: map['icon'] ?? 'assets/images/blocks/default.png',
      color: map['color'] != null
          ? Color(int.parse(map['color'].toString().replaceAll('#', '0xFF')))
          : Colors.grey,
    );
  }

  // Convert back to old map structure for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': subtype,
      'content': properties,
    };
  }

  // Create a copy with some properties changed
  Block copyWith({
    String? id,
    String? name,
    String? description,
    BlockType? type,
    String? subtype,
    Map<String, dynamic>? properties,
    List<BlockConnection>? connections,
    String? iconPath,
    Color? color,
  }) {
    return Block(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      properties: properties ?? Map.of(this.properties),
      connections: connections ?? List.of(this.connections),
      iconPath: iconPath ?? this.iconPath,
      color: color ?? this.color,
    );
  }
}

// BlockCollection holds a set of blocks with their connections
class BlockCollection {
  final List<Block> blocks;

  BlockCollection({required this.blocks});

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory BlockCollection.fromJson(Map<String, dynamic> json) {
    return BlockCollection(
      blocks: (json['blocks'] as List)
          .map((b) => Block.fromJson(b))
          .toList(),
    );
  }

  // Save to string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Load from string
  factory BlockCollection.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return BlockCollection.fromJson(json);
  }

  // Convert legacy block list to BlockCollection
  factory BlockCollection.fromLegacyBlocks(List<Map<String, dynamic>> legacyBlocks) {
    final blocks = legacyBlocks.map((map) => Block.fromMap(map)).toList();
    return BlockCollection(blocks: blocks);
  }

  // Convert back to legacy blocks for backward compatibility
  List<Map<String, dynamic>> toLegacyBlocks() {
    return blocks.map((block) => block.toMap()).toList();
  }

  // Add a block
  void addBlock(Block block) {
    blocks.add(block);
  }

  // Remove a block
  void removeBlock(String blockId) {
    blocks.removeWhere((b) => b.id == blockId);

    // Also remove connections to this block
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId?.startsWith(blockId) ?? false) {
          connection.connectedToId = null;
        }
      }
    }
  }

  // Get a block by ID
  Block? getBlockById(String blockId) {
    try {
      return blocks.firstWhere((b) => b.id == blockId);
    } catch (e) {
      return null;
    }
  }

  // Connect two blocks
  bool connectBlocks(String sourceBlockId, String sourceConnectionId,
      String targetBlockId, String targetConnectionId) {
    final sourceBlock = getBlockById(sourceBlockId);
    final targetBlock = getBlockById(targetBlockId);

    if (sourceBlock == null || targetBlock == null) {
      return false;
    }

    final sourceConnection = sourceBlock.connections
        .firstWhere((c) => c.id == sourceConnectionId);
    final targetConnection = targetBlock.connections
        .firstWhere((c) => c.id == targetConnectionId);

    // Check if connection types are compatible
    if ((sourceConnection.type == ConnectionType.output ||
        sourceConnection.type == ConnectionType.both) &&
        (targetConnection.type == ConnectionType.input ||
            targetConnection.type == ConnectionType.both)) {
      sourceConnection.connectedToId = targetConnectionId;
      targetConnection.connectedToId = sourceConnectionId;
      return true;
    }

    return false;
  }

  // Disconnect a block connection
  void disconnectConnection(String blockId, String connectionId) {
    final block = getBlockById(blockId);
    if (block == null) return;

    final connection = block.connections
        .firstWhere((c) => c.id == connectionId);

    if (connection.connectedToId != null) {
      final connectedParts = connection.connectedToId!.split('_');
      final connectedBlockId = connectedParts.first;
      final connectedConnectionId = connection.connectedToId!;

      final connectedBlock = getBlockById(connectedBlockId);
      if (connectedBlock != null) {
        final connectedConnection = connectedBlock.connections
            .firstWhere((c) => c.id == connectedConnectionId);
        connectedConnection.connectedToId = null;
      }

      connection.connectedToId = null;
    }
  }

  // Load blocks from JSON file
  static Future<BlockCollection> loadFromJsonFile(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = json.decode(jsonString);
      return BlockCollection.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading blocks from JSON file: $e');
      return BlockCollection(blocks: []);
    }
  }
}