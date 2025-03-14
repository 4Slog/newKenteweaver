// lib/models/block_model.dart
import 'package:flutter/material.dart';
import 'dart:convert';

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
        (t) => t.toString().split('.').last == json['type'],
      ),
      position: Offset(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
      ),
      connectedToId: json['connectedToId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'connectedToId': connectedToId,
      'position': {'dx': position.dx, 'dy': position.dy},
    };
  }

  factory BlockConnection.fromMap(Map<String, dynamic> map) {
    final posMap = map['position'] as Map<String, dynamic>;
    return BlockConnection(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ConnectionType.values.firstWhere(
        (t) => t.toString().split('.').last == map['type'],
      ),
      position: Offset(
        posMap['dx'] as double,
        posMap['dy'] as double,
      ),
      connectedToId: map['connectedToId'] as String?,
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
  final String iconPath;
  final String colorHex;
  final List<BlockConnection> connections;
  Offset position;
  Size size;

  Block({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.subtype,
    required this.properties,
    required this.iconPath,
    required this.colorHex,
    required this.connections,
    this.position = Offset.zero,
    this.size = const Size(120, 120),
  });

  Color get color => HexColor.fromHex(colorHex);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'subtype': subtype,
      'properties': properties,
      'iconPath': iconPath,
      'colorHex': colorHex,
      'connections': connections.map((c) => c.toJson()).toList(),
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: BlockType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
      ),
      subtype: json['subtype'],
      properties: json['properties'],
      iconPath: json['iconPath'],
      colorHex: json['colorHex'],
      connections: (json['connections'] as List)
          .map((c) => BlockConnection.fromJson(c))
          .toList(),
      position: json['position'] != null
          ? Offset(
              json['position']['x'].toDouble(),
              json['position']['y'].toDouble(),
            )
          : Offset.zero,
      size: json['size'] != null
          ? Size(
              json['size']['width'].toDouble(),
              json['size']['height'].toDouble(),
            )
          : const Size(120, 120),
    );
  }

  Block copyWith({
    String? id,
    String? name,
    String? description,
    BlockType? type,
    String? subtype,
    Map<String, dynamic>? properties,
    String? iconPath,
    String? colorHex,
    List<BlockConnection>? connections,
    Offset? position,
    Size? size,
  }) {
    return Block(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      properties: properties ?? this.properties,
      iconPath: iconPath ?? this.iconPath,
      colorHex: colorHex ?? this.colorHex,
      connections: connections ?? this.connections,
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'subtype': subtype,
      'connections': connections.map((c) => c.toMap()).toList(),
      'properties': properties,
    };
  }

  factory Block.fromMap(Map<String, dynamic> map) {
    return Block(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      type: BlockType.values.firstWhere(
        (t) => t.toString() == map['type'],
        orElse: () => BlockType.pattern,
      ),
      subtype: map['subtype'] as String,
      properties: Map<String, dynamic>.from(map['properties'] as Map),
      iconPath: map['iconPath'] as String,
      colorHex: map['colorHex'] as String,
      connections: (map['connections'] as List<dynamic>)
          .map((c) => BlockConnection.fromMap(c as Map<String, dynamic>))
          .toList(),
      position: Offset(
        map['position']['x'] as double,
        map['position']['y'] as double,
      ),
      size: Size(
        map['size']['width'] as double,
        map['size']['height'] as double,
      ),
    );
  }
}

/// Represents a collection of blocks that can be used to build a solution
class BlockCollection {
  final List<Block> blocks;
  final Map<String, dynamic> metadata;

  const BlockCollection({
    required this.blocks,
    this.metadata = const {},
  });

  /// Creates a BlockCollection from JSON data
  factory BlockCollection.fromJson(Map<String, dynamic> json) {
    return BlockCollection(
      blocks: (json['blocks'] as List)
          .map((block) => Block.fromJson(block))
          .toList(),
      metadata: json['metadata'] ?? {},
    );
  }

  /// Converts the BlockCollection to JSON
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'metadata': metadata,
    };
  }

  Block? getBlockById(String id) {
    try {
      return blocks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void removeBlock(String blockId) {
    blocks.removeWhere((b) => b.id == blockId);
    // Also remove any connections to this block
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId == blockId) {
          connection.connectedToId = null;
        }
      }
    }
  }

  void addBlock(Block block) {
    blocks.add(block);
  }

  bool connectBlocks(
    String sourceBlockId,
    String sourceConnectionId,
    String targetBlockId,
    String targetConnectionId,
  ) {
    final sourceBlock = getBlockById(sourceBlockId);
    final targetBlock = getBlockById(targetBlockId);

    if (sourceBlock == null || targetBlock == null) return false;

    final sourceConnection = sourceBlock.connections
        .firstWhere((c) => c.id == sourceConnectionId);
    final targetConnection = targetBlock.connections
        .firstWhere((c) => c.id == targetConnectionId);

    // Check if connection types are compatible
    if (!_areConnectionsCompatible(sourceConnection, targetConnection)) {
      return false;
    }

    // Remove any existing connections
    if (sourceConnection.connectedToId != null) {
      final oldConnection = _findConnection(sourceConnection.connectedToId!);
      if (oldConnection != null) {
        oldConnection.connectedToId = null;
      }
    }
    if (targetConnection.connectedToId != null) {
      final oldConnection = _findConnection(targetConnection.connectedToId!);
      if (oldConnection != null) {
        oldConnection.connectedToId = null;
      }
    }

    // Make the new connection
    sourceConnection.connectedToId = targetConnectionId;
    targetConnection.connectedToId = sourceConnectionId;

    return true;
  }

  BlockConnection? _findConnection(String connectionId) {
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.id == connectionId) {
          return connection;
        }
      }
    }
    return null;
  }

  bool _areConnectionsCompatible(BlockConnection source, BlockConnection target) {
    // Input can connect to output and vice versa
    if (source.type == ConnectionType.input && target.type == ConnectionType.output) {
      return true;
    }
    if (source.type == ConnectionType.output && target.type == ConnectionType.input) {
      return true;
    }
    // Both can connect to both
    if (source.type == ConnectionType.both && target.type == ConnectionType.both) {
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> toLegacyBlocks() {
    return blocks.map((block) => {
      'id': block.id,
      'type': block.type.toString().split('.').last,
      'subtype': block.subtype,
      'properties': block.properties,
      'connections': block.connections.map((c) => {
        'id': c.id,
        'connectedToId': c.connectedToId,
      }).toList(),
    }).toList();
  }

  factory BlockCollection.fromLegacyBlocks(List<Map<String, dynamic>> legacyBlocks) {
    return BlockCollection(
      blocks: legacyBlocks.map((map) {
        return Block(
          id: map['id'] as String? ?? '',
          name: map['name'] as String? ?? '',
          description: map['description'] as String? ?? '',
          type: BlockType.values.firstWhere(
            (t) => t.toString() == map['type'],
            orElse: () => BlockType.pattern,
          ),
          subtype: map['subtype'] as String? ?? '',
          properties: Map<String, dynamic>.from(map['properties'] as Map? ?? {}),
          iconPath: '',
          colorHex: '',
          connections: (map['connections'] as List<dynamic>?)
              ?.map((c) => BlockConnection.fromMap(c as Map<String, dynamic>))
              .toList() ?? [],
          position: Offset.zero,
          size: const Size(120, 120),
        );
      }).toList(),
    );
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
