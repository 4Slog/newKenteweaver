import 'dart:convert';
import 'package:flutter/material.dart';

/// Widget for displaying a text-based representation of blocks
class BlockRepresentationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> blocks;
  final Function(List<Map<String, dynamic>>)? onBlocksChanged;
  final bool isEditable;
  
  const BlockRepresentationWidget({
    Key? key,
    required this.blocks,
    this.onBlocksChanged,
    this.isEditable = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Block Code',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Block representation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildBlocksText(),
          ),
        ),
        
        // Edit button if editable
        if (isEditable && onBlocksChanged != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showEditDialog(context),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Blocks'),
            ),
          ),
      ],
    );
  }
  
  List<Widget> _buildBlocksText() {
    final List<Widget> blockWidgets = [];
    
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final blockType = block['type'] as String;
      final blockName = block['name'] as String? ?? 'Unnamed Block';
      final indentation = _getBlockIndentation(block, blocks);
      
      // Create a widget for this block
      final blockWidget = Padding(
        padding: EdgeInsets.only(left: indentation * 20.0, bottom: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block icon or indicator
            _getBlockIcon(blockType),
            const SizedBox(width: 8),
            
            // Block text representation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Block name and type
                  Text(
                    '$blockName (${_getReadableBlockType(blockType)})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  // Block properties
                  if (block.containsKey('properties') && block['properties'] is Map)
                    ..._buildPropertyTexts(block['properties'] as Map),
                  
                  // Block connections
                  if (block.containsKey('connections') && block['connections'] is List)
                    ..._buildConnectionTexts(block['connections'] as List, blocks),
                ],
              ),
            ),
          ],
        ),
      );
      
      blockWidgets.add(blockWidget);
    }
    
    return blockWidgets;
  }
  
  List<Widget> _buildPropertyTexts(Map properties) {
    return properties.entries.map((entry) =>
      Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 2.0),
        child: Text(
          '${entry.key}: ${entry.value}',
          style: const TextStyle(fontSize: 12),
        ),
      )
    ).toList();
  }
  
  List<Widget> _buildConnectionTexts(List connections, List<Map<String, dynamic>> allBlocks) {
    return connections.map((connection) {
      final connId = connection['id'] as String? ?? '';
      final connType = connection['type'] as String? ?? '';
      final connectedToId = connection['connectedToId'] as String?;
      
      String connectionText = 'Connection: $connId ($connType)';
      
      if (connectedToId != null) {
        // Find the connected block
        final connectedBlockId = connectedToId.split('_').first;
        final connectedBlock = allBlocks.firstWhere(
          (b) => b['id'] == connectedBlockId,
          orElse: () => {'name': 'Unknown Block'},
        );
        
        connectionText += ' → ${connectedBlock['name'] ?? 'Unknown Block'}';
      }
      
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 2.0),
        child: Text(
          connectionText,
          style: const TextStyle(fontSize: 12, color: Colors.blue),
        ),
      );
    }).toList();
  }
  
  int _getBlockIndentation(Map<String, dynamic> block, List<Map<String, dynamic>> allBlocks) {
    // Check if this block is connected to another block
    for (final otherBlock in allBlocks) {
      if (otherBlock.containsKey('connections') && otherBlock['connections'] is List) {
        for (final connection in otherBlock['connections'] as List) {
          final connectedToId = connection['connectedToId'] as String?;
          if (connectedToId != null && connectedToId.startsWith(block['id'])) {
            // This block is connected to another block, indent it
            return _getBlockIndentation(otherBlock, allBlocks) + 1;
          }
        }
      }
    }
    // No connections found, this is a root block
    return 0;
  }
  
  Widget _getBlockIcon(String blockType) {
    IconData iconData;
    Color iconColor;
    
    if (blockType.contains('pattern')) {
      iconData = Icons.grid_on;
      iconColor = Colors.blue;
    } else if (blockType.contains('color') || blockType.contains('shuttle')) {
      iconData = Icons.color_lens;
      iconColor = Colors.red;
    } else if (blockType.contains('loop')) {
      iconData = Icons.loop;
      iconColor = Colors.green;
    } else if (blockType.contains('row')) {
      iconData = Icons.view_week;
      iconColor = Colors.orange;
    } else if (blockType.contains('column')) {
      iconData = Icons.view_column;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.widgets;
      iconColor = Colors.grey;
    }
    
    return Icon(iconData, size: 16, color: iconColor);
  }
  
  String _getReadableBlockType(String blockType) {
    if (blockType.contains('pattern')) return 'Pattern';
    if (blockType.contains('color') || blockType.contains('shuttle')) return 'Color';
    if (blockType.contains('loop')) return 'Loop';
    if (blockType.contains('row')) return 'Row';
    if (blockType.contains('column')) return 'Column';
    return 'Structure';
  }
  
  void _showEditDialog(BuildContext context) {
    // Convert blocks to JSON string for editing
    final jsonString = const JsonEncoder.withIndent('  ').convert(blocks);
    final textController = TextEditingController(text: jsonString);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Blocks'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: TextField(
            controller: textController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit block JSON...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                // Parse the edited JSON
                final editedBlocks = jsonDecode(textController.text) as List;
                final typedBlocks = editedBlocks
                    .map((b) => Map<String, dynamic>.from(b))
                    .toList();
                
                // Update blocks
                if (onBlocksChanged != null) {
                  onBlocksChanged!(typedBlocks);
                }
                
                Navigator.of(context).pop();
              } catch (e) {
                // Show error for invalid JSON
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid JSON: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
