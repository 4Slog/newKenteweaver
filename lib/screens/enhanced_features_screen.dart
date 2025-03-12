import 'package:flutter/material.dart';
import '../widgets/pattern_visualization_widget.dart';
import '../widgets/enhanced_ui_showcase.dart';
import '../widgets/pattern_sharing_widget.dart';
import '../models/block_model.dart';
import '../services/pattern_visualization_service.dart';

/// A screen that showcases the enhanced features of the app
class EnhancedFeaturesScreen extends StatefulWidget {
  /// Creates a new enhanced features screen
  const EnhancedFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedFeaturesScreen> createState() => _EnhancedFeaturesScreenState();
}

class _EnhancedFeaturesScreenState extends State<EnhancedFeaturesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample pattern data for demonstration
  final String _samplePatternId = 'sample_pattern_001';
  final List<Block> _sampleBlocks = [
    Block(
      id: 'block1',
      name: 'Loop Block',
      description: 'A block that represents a loop',
      type: BlockType.loop,
      subtype: 'for_loop',
      properties: {'iterations': 5},
      iconPath: 'assets/icons/loop.png',
      colorHex: '#4CAF50',
      connections: [],
      position: const Offset(0, 0),
      size: const Size(120, 120),
    ),
    Block(
      id: 'block2',
      name: 'Condition Block',
      description: 'A block that represents a condition',
      type: BlockType.pattern,
      subtype: 'if_condition',
      properties: {'condition': 'x > 5'},
      iconPath: 'assets/icons/condition.png',
      colorHex: '#2196F3',
      connections: [],
      position: const Offset(150, 0),
      size: const Size(120, 60),
    ),
    Block(
      id: 'block3',
      name: 'Sequence Block',
      description: 'A block that represents a sequence',
      type: BlockType.pattern,
      subtype: 'sequence',
      properties: {'steps': 3},
      iconPath: 'assets/icons/sequence.png',
      colorHex: '#FFC107',
      connections: [],
      position: const Offset(0, 150),
      size: const Size(240, 60),
    ),
    Block(
      id: 'block4',
      name: 'Function Block',
      description: 'A block that represents a function',
      type: BlockType.pattern,
      subtype: 'function',
      properties: {'name': 'calculateSum'},
      iconPath: 'assets/icons/function.png',
      colorHex: '#9C27B0',
      connections: [],
      position: const Offset(150, 80),
      size: const Size(120, 60),
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pattern Visualization', icon: Icon(Icons.view_module)),
            Tab(text: 'UI Enhancements', icon: Icon(Icons.palette)),
            Tab(text: 'Pattern Sharing', icon: Icon(Icons.share)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pattern Visualization Tab
          PatternVisualizationWidget(
            patternId: _samplePatternId,
            blocks: _sampleBlocks,
            initialMode: VisualizationMode.standard,
          ),
          
          // UI Enhancements Tab
          const EnhancedUIShowcase(),
          
          // Pattern Sharing Tab
          SingleChildScrollView(
            child: Column(
              children: [
                PatternSharingWidget(
                  patternId: _samplePatternId,
                  blocks: _sampleBlocks,
                  onShareComplete: (shareUrl) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pattern shared: $shareUrl'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                
                // Sharing history section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sharing History',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
                          // This would be populated with actual sharing history
                          // For now, we'll just show a placeholder
                          const ListTile(
                            leading: Icon(Icons.link),
                            title: Text('Shared via Link'),
                            subtitle: Text('2 hours ago'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          const Divider(),
                          const ListTile(
                            leading: Icon(Icons.email),
                            title: Text('Shared via Email'),
                            subtitle: Text('Yesterday'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          const Divider(),
                          const ListTile(
                            leading: Icon(Icons.qr_code),
                            title: Text('Shared via QR Code'),
                            subtitle: Text('Last week'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear History'),
                              onPressed: () {
                                // This would clear the actual sharing history
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sharing history cleared'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInfoDialog,
        child: const Icon(Icons.info_outline),
        tooltip: 'About Enhanced Features',
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Enhanced Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Pattern Visualization',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'The Pattern Visualization feature provides multiple ways to view and understand Kente patterns, including:'
                '\n• Standard view'
                '\n• Color-coded view'
                '\n• Block highlight view'
                '\n• Concept highlight view'
                '\n• Cultural context view'
                '\n• 3D visualization'
              ),
              SizedBox(height: 16),
              Text(
                'UI Enhancements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'The UI Enhancement features provide a more engaging and accessible experience:'
                '\n• Customizable themes'
                '\n• Accessibility options'
                '\n• Enhanced UI components'
                '\n• Animations and transitions'
                '\n• Contextual help'
              ),
              SizedBox(height: 16),
              Text(
                'Pattern Sharing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'The Pattern Sharing feature allows you to share your patterns with others:'
                '\n• Share via link'
                '\n• Share via email'
                '\n• Share via QR code'
                '\n• Share via social media'
                '\n• Export as file'
                '\n• Collaboration options'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 