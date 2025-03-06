import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// A widget providing comprehensive controls for text-to-speech functionality.
/// 
/// Features:
/// - Play/pause button for narration
/// - Volume slider control
/// - Speed (rate) control
/// - Character voice selection
/// - Visual indicators for active narration
class TTSControlWidget extends StatefulWidget {
  /// The text to be narrated
  final String? text;
  
  /// Content blocks for structured narration
  final List<Map<String, dynamic>>? contentBlocks;
  
  /// Current content block index (for structured content)
  final int currentBlockIndex;
  
  /// Callback when narration of a block is completed
  final Function(int)? onBlockComplete;
  
  /// Initial enabled state of TTS
  final bool initiallyEnabled;
  
  /// Whether to show expanded controls (volume, speed, etc.)
  final bool showExpandedControls;
  
  /// Whether this control is in compact mode (icon only)
  final bool compactMode;
  
  /// Available character voices for selection
  final Map<String, Map<String, dynamic>>? availableVoices;
  
  /// Callback when TTS enabled state changes
  final Function(bool)? onEnabledChanged;

  const TTSControlWidget({
    Key? key,
    this.text,
    this.contentBlocks,
    this.currentBlockIndex = 0,
    this.onBlockComplete,
    this.initiallyEnabled = true,
    this.showExpandedControls = false,
    this.compactMode = false,
    this.availableVoices,
    this.onEnabledChanged,
  }) : assert(text != null || contentBlocks != null, 
          'Either text or contentBlocks must be provided'),
       super(key: key);

  @override
  State<TTSControlWidget> createState() => _TTSControlWidgetState();
}

class _TTSControlWidgetState extends State<TTSControlWidget> 
    with SingleTickerProviderStateMixin {
  /// Text-to-speech service
  late TTSService _ttsService;
  
  /// Whether narration is currently active
  bool _isNarrating = false;
  
  /// Whether TTS is enabled
  late bool _ttsEnabled;
  
  /// Current volume level (0.0 to 1.0)
  double _volume = 1.0;
  
  /// Current speech rate (0.25 to 2.0)
  double _rate = 0.5;
  
  /// Current voice pitch (0.5 to 2.0)
  double _pitch = 1.0;
  
  /// Current voice selection
  String? _selectedVoice;
  
  /// Animation controller for visual effects
  late AnimationController _animationController;
  
  /// Show expanded controls
  late bool _showExpanded;
  
  /// Default voice options
  final Map<String, Map<String, dynamic>> _defaultVoices = {
    'narrator': {
      'label': 'Narrator',
      'pitch': 1.0,
      'rate': 0.45,
    },
    'kwaku': {
      'label': 'Kwaku',
      'pitch': 1.2,
      'rate': 0.5,
    },
    'nana_yaw': {
      'label': 'Nana Yaw',
      'pitch': 0.8,
      'rate': 0.4,
    },
    'auntie_efua': {
      'label': 'Auntie Efua',
      'pitch': 1.1,
      'rate': 0.45,
    },
    'ama': {
      'label': 'Ama',
      'pitch': 1.3,
      'rate': 0.5,
    },
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize TTS service
    _ttsService = TTSService();
    
    // Initialize state from props
    _ttsEnabled = widget.initiallyEnabled;
    _showExpanded = widget.showExpandedControls;
    
    // Sync state with TTS service
    _initializeTtsState();
    
    // Initialize animation controller for visual feedback
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    
    // Stop any ongoing narration
    if (_isNarrating) {
      _ttsService.stop();
    }
    
    super.dispose();
  }
  
  @override
  void didUpdateWidget(TTSControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Stop narration if content changes
    if (oldWidget.text != widget.text || 
        oldWidget.contentBlocks != widget.contentBlocks) {
      if (_isNarrating) {
        _ttsService.stop();
        setState(() {
          _isNarrating = false;
        });
      }
    }
  }
  
  /// Initialize state from TTS service settings
  Future<void> _initializeTtsState() async {
    setState(() {
      _volume = _ttsService.ttsVolume;
      _rate = _ttsService.ttsRate;
      _pitch = _ttsService.ttsPitch;
    });
  }
  
  /// Toggle narration on/off
  void _toggleNarration() async {
    if (!_ttsEnabled) return;
    
    if (_isNarrating) {
      await _ttsService.stop();
      setState(() {
        _isNarrating = false;
      });
    } else {
      setState(() {
        _isNarrating = true;
      });
      
      try {
        if (widget.contentBlocks != null && widget.contentBlocks!.isNotEmpty) {
          await _narrateContentBlock(widget.currentBlockIndex);
        } else if (widget.text != null) {
          await _ttsService.speak(widget.text!);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isNarrating = false;
          });
        }
      }
    }
  }
  
  /// Narrate a specific content block
  Future<void> _narrateContentBlock(int blockIndex) async {
    if (widget.contentBlocks == null || 
        blockIndex >= widget.contentBlocks!.length) {
      return;
    }
    
    final block = widget.contentBlocks![blockIndex];
    final text = block['text'] as String;
    
    // Set voice based on speaker if present
    if (block.containsKey('speaker') && block['speaker'] != null) {
      await _setVoiceForCharacter(block['speaker'] as String);
    } else {
      await _setNarratorVoice();
    }
    
    // Speak the text
    await _ttsService.speak(text);
    
    // Trigger completion callback if provided
    if (widget.onBlockComplete != null) {
      widget.onBlockComplete!(blockIndex);
    }
  }
  
  /// Set TTS voice parameters for a specific character
  Future<void> _setVoiceForCharacter(String character) async {
    final lowerChar = character.toLowerCase();
    
    // Get voice settings from available voices or defaults
    Map<String, dynamic>? voiceSettings;
    
    if (widget.availableVoices != null &&
        widget.availableVoices!.containsKey(lowerChar)) {
      voiceSettings = widget.availableVoices![lowerChar];
    } else if (_defaultVoices.containsKey(lowerChar)) {
      voiceSettings = _defaultVoices[lowerChar];
    }
    
    if (voiceSettings != null) {
      final pitch = voiceSettings.containsKey('pitch') ? voiceSettings['pitch'] as double? ?? 1.0 : 1.0;
      final rate = voiceSettings.containsKey('rate') ? voiceSettings['rate'] as double? ?? 0.5 : 0.5;
      
      await _ttsService.setPitch(pitch);
      await _ttsService.setRate(rate);
    } else {
      // Default fallback
      await _setNarratorVoice();
    }
  }
  
  /// Set TTS voice parameters for narrator
  Future<void> _setNarratorVoice() async {
    await _ttsService.setPitch(1.0);
    await _ttsService.setRate(0.45);
  }
  
  /// Toggle TTS enabled state
  void _toggleTtsEnabled() async {
    final newState = !_ttsEnabled;
    await _ttsService.toggleTTS(newState);
    
    setState(() {
      _ttsEnabled = newState;
    });
    
    // If disabling while narrating, stop narration
    if (!newState && _isNarrating) {
      await _ttsService.stop();
      setState(() {
        _isNarrating = false;
      });
    }
    
    // Trigger callback if provided
    if (widget.onEnabledChanged != null) {
      widget.onEnabledChanged!(newState);
    }
  }
  
  /// Update TTS volume
  Future<void> _updateVolume(double value) async {
    await _ttsService.setVolume(value);
    setState(() {
      _volume = value;
    });
  }
  
  /// Update TTS rate (speed)
  Future<void> _updateRate(double value) async {
    await _ttsService.setRate(value);
    setState(() {
      _rate = value;
    });
  }
  
  /// Update TTS pitch
  Future<void> _updatePitch(double value) async {
    await _ttsService.setPitch(value);
    setState(() {
      _pitch = value;
    });
  }
  
  /// Toggle expanded controls visibility
  void _toggleExpandedControls() {
    setState(() {
      _showExpanded = !_showExpanded;
    });
  }
  
  /// Set voice from selection
  Future<void> _setVoiceFromSelection(String? voiceKey) async {
    if (voiceKey == null) return;
    
    setState(() {
      _selectedVoice = voiceKey;
    });
    
    Map<String, dynamic>? voiceSettings;
    
    if (widget.availableVoices != null && 
        widget.availableVoices!.containsKey(voiceKey)) {
      voiceSettings = widget.availableVoices![voiceKey];
    } else if (_defaultVoices.containsKey(voiceKey)) {
      voiceSettings = _defaultVoices[voiceKey];
    }
    
    if (voiceSettings != null) {
      final pitch = voiceSettings.containsKey('pitch') ? voiceSettings['pitch'] as double? ?? 1.0 : 1.0;
      final rate = voiceSettings.containsKey('rate') ? voiceSettings['rate'] as double? ?? 0.5 : 0.5;
      
      await _ttsService.setPitch(pitch);
      await _ttsService.setRate(rate);
      
      setState(() {
        _pitch = pitch;
        _rate = rate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // For compact mode (icon only)
    if (widget.compactMode) {
      return _buildCompactControl();
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TTS enable/disable toggle
            IconButton(
              icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
              tooltip: _ttsEnabled ? 'Disable narration' : 'Enable narration',
              onPressed: _toggleTtsEnabled,
              color: _ttsEnabled ? AppTheme.kenteGold : Colors.grey,
            ),
            
            const SizedBox(width: 8),
            
            // Play/pause button
            IconButton(
              icon: _buildAnimatedPlayIcon(),
              onPressed: _ttsEnabled ? _toggleNarration : null,
              tooltip: _isNarrating ? 'Pause narration' : 'Play narration',
              color: _ttsEnabled 
                ? (_isNarrating ? AppTheme.kenteGold : Colors.black87)
                : Colors.grey,
            ),
            
            const SizedBox(width: 8),
            
            // Expand/collapse controls button
            IconButton(
              icon: Icon(_showExpanded ? Icons.expand_less : Icons.expand_more),
              tooltip: _showExpanded ? 'Hide controls' : 'Show controls',
              onPressed: _toggleExpandedControls,
              color: Colors.black87,
            ),
          ],
        ),
        
        // Expanded controls section
        if (_showExpanded) ...[
          const SizedBox(height: 8),
          
          // Voice selection
          if (_getAvailableVoices().isNotEmpty) ...[
            _buildVoiceSelector(),
            const SizedBox(height: 12),
          ],
          
          // Volume control
          _buildSliderControl(
            label: 'Volume',
            icon: Icons.volume_up,
            value: _volume,
            min: 0.0,
            max: 1.0,
            onChanged: _updateVolume,
          ),
          
          const SizedBox(height: 8),
          
          // Speed control
          _buildSliderControl(
            label: 'Speed',
            icon: Icons.speed,
            value: _rate,
            min: 0.25,
            max: 1.0,
            onChanged: _updateRate,
          ),
          
          const SizedBox(height: 8),
          
          // Pitch control
          _buildSliderControl(
            label: 'Pitch',
            icon: Icons.tune,
            value: _pitch,
            min: 0.5,
            max: 2.0,
            onChanged: _updatePitch,
          ),
        ],
      ],
    );
  }
  
  /// Build the compact version (icon only)
  Widget _buildCompactControl() {
    return IconButton(
      icon: _isNarrating
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Icon(
                  Icons.graphic_eq,
                  color: Color.lerp(
                    AppTheme.kenteGold,
                    Colors.black87,
                    _animationController.value,
                  ),
                );
              },
            )
          : Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
      tooltip: _isNarrating
          ? 'Narrating...'
          : _ttsEnabled
              ? 'Disable narration'
              : 'Enable narration',
      onPressed: _isNarrating ? _toggleNarration : _toggleTtsEnabled,
      color: _ttsEnabled ? AppTheme.kenteGold : Colors.grey,
    );
  }
  
  /// Build an animated play icon that pulses when active
  Widget _buildAnimatedPlayIcon() {
    if (!_isNarrating) {
      return const Icon(Icons.play_arrow);
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Icon(
          Icons.pause,
          size: 24 + (_animationController.value * 4),
        );
      },
    );
  }
  
  /// Build a slider control with label and icon
  Widget _buildSliderControl({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).toInt(),
            onChanged: _ttsEnabled ? onChanged : null,
            activeColor: AppTheme.kenteGold,
            label: value.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }
  
  /// Build a voice selection dropdown
  Widget _buildVoiceSelector() {
    final voices = _getAvailableVoices();
    
    return Row(
      children: [
        const Icon(Icons.record_voice_over, size: 20, color: Colors.black54),
        const SizedBox(width: 8),
        const Text(
          'Voice',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, 
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            isExpanded: true,
            value: _selectedVoice ?? 'narrator',
            onChanged: _ttsEnabled ? _setVoiceFromSelection : null,
            items: voices.entries.map((entry) {
              final label = entry.value.containsKey('label') 
                  ? entry.value['label'] as String? ?? entry.key
                  : entry.key;
                  
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  /// Get available voices map
  Map<String, Map<String, dynamic>> _getAvailableVoices() {
    return widget.availableVoices ?? _defaultVoices;
  }
}
