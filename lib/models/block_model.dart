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
}

class BlockCollection {
  final List<Block> blocks;

  const BlockCollection({
    required this.blocks,
  });

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

  Block? getBlockById(String id) {
    try {
      return blocks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
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