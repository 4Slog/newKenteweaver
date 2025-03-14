import 'package:flutter/material.dart';
import '../models/block_model.dart';
import '../services/pattern_sharing_service.dart';

/// Widget for sharing patterns with other users
class PatternSharingWidget extends StatefulWidget {
  /// Pattern ID to share
  final String patternId;
  
  /// Blocks that make up the pattern
  final List<Block> blocks;
  
  /// Callback when sharing is complete
  final Function(String shareUrl)? onShareComplete;
  
  /// Creates a new pattern sharing widget
  const PatternSharingWidget({
    Key? key,
    required this.patternId,
    required this.blocks,
    this.onShareComplete,
  }) : super(key: key);

  @override
  State<PatternSharingWidget> createState() => _PatternSharingWidgetState();
}

class _PatternSharingWidgetState extends State<PatternSharingWidget> {
  final PatternSharingService _sharingService = PatternSharingService();
  
  SharingMethod _selectedMethod = SharingMethod.link;
  String? _recipientEmail;
  String? _message;
  bool _isSharing = false;
  String? _shareUrl;
  String? _errorMessage;
  
  // Sharing settings
  bool _includeMetadata = true;
  bool _includeComments = true;
  bool _includeVersionHistory = false;
  bool _enableCollaboration = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = _sharingService.getSharingSettings();
    setState(() {
      _includeMetadata = settings['includeMetadata'];
      _includeComments = settings['includeComments'];
      _includeVersionHistory = settings['includeVersionHistory'];
      _enableCollaboration = settings['enableCollaboration'];
    });
  }
  
  Future<void> _sharePattern() async {
    setState(() {
      _isSharing = true;
      _shareUrl = null;
      _errorMessage = null;
    });
    
    try {
      final shareUrl = await _sharingService.sharePattern(
        patternId: widget.patternId,
        blocks: widget.blocks,
        method: _selectedMethod,
        recipientEmail: _recipientEmail,
        message: _message,
      );
      
      setState(() {
        _shareUrl = shareUrl;
        _isSharing = false;
      });
      
      if (widget.onShareComplete != null) {
        widget.onShareComplete!(shareUrl);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing pattern: $e';
        _isSharing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Pattern',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Sharing method selection
            Text(
              'Sharing Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSharingMethodSelector(),
            const SizedBox(height: 16),
            
            // Email input (only for email sharing)
            if (_selectedMethod == SharingMethod.email) ...[
              Text(
                'Recipient Email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Enter recipient email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _recipientEmail = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Message input
            Text(
              'Message (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter a message to include with the share',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _message = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Sharing settings
            ExpansionTile(
              title: const Text('Sharing Settings'),
              children: [
                SwitchListTile(
                  title: const Text('Include Metadata'),
                  subtitle: const Text('Include creator and creation date'),
                  value: _includeMetadata,
                  onChanged: (value) {
                    setState(() {
                      _includeMetadata = value;
                    });
                    _sharingService.toggleIncludeMetadata();
                  },
                ),
                SwitchListTile(
                  title: const Text('Include Comments'),
                  subtitle: const Text('Include comments on the pattern'),
                  value: _includeComments,
                  onChanged: (value) {
                    setState(() {
                      _includeComments = value;
                    });
                    _sharingService.toggleIncludeComments();
                  },
                ),
                SwitchListTile(
                  title: const Text('Include Version History'),
                  subtitle: const Text('Include previous versions of the pattern'),
                  value: _includeVersionHistory,
                  onChanged: (value) {
                    setState(() {
                      _includeVersionHistory = value;
                    });
                    _sharingService.toggleIncludeVersionHistory();
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Collaboration'),
                  subtitle: const Text('Allow others to edit the pattern'),
                  value: _enableCollaboration,
                  onChanged: (value) {
                    setState(() {
                      _enableCollaboration = value;
                    });
                    _sharingService.toggleEnableCollaboration();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Share button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: Text(_isSharing ? 'Sharing...' : 'Share Pattern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isSharing || (_selectedMethod == SharingMethod.email && (_recipientEmail == null || _recipientEmail!.isEmpty))
                    ? null
                    : _sharePattern,
              ),
            ),
            
            // Share result
            if (_shareUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pattern Shared Successfully!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _shareUrl!,
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            // In a real app, this would copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSharingMethodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMethodChip(SharingMethod.link, 'Link', Icons.link),
        _buildMethodChip(SharingMethod.email, 'Email', Icons.email),
        _buildMethodChip(SharingMethod.qrCode, 'QR Code', Icons.qr_code),
        _buildMethodChip(SharingMethod.socialMedia, 'Social', Icons.share),
        _buildMethodChip(SharingMethod.exportFile, 'Export', Icons.file_download),
      ],
    );
  }
  
  Widget _buildMethodChip(SharingMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMethod = method;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
} 