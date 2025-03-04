import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

/// A widget for displaying story content with animations and styling
/// based on the content type. Supports different content types such as
/// narration, dialogue, and cultural context with appropriate styling.
class StoryContentDisplay extends StatefulWidget {
  /// List of content blocks to display
  final List<Map<String, dynamic>> contentBlocks;
  
  /// Enable text-to-speech narration
  final bool enableTTS;
  
  /// Callback when a block is completed (read or skipped)
  final Function(Map<String, dynamic>)? onBlockComplete;
  
  /// Path to the background image (if any)
  final String? backgroundImagePath;
  
  /// Auto-advance through blocks
  final bool autoAdvance;
  
  /// Initial block index to display
  final int initialBlockIndex;

  const StoryContentDisplay({
    Key? key,
    required this.contentBlocks,
    this.enableTTS = true,
    this.onBlockComplete,
    this.backgroundImagePath,
    this.autoAdvance = false,
    this.initialBlockIndex = 0,
  }) : super(key: key);

  @override
  State<StoryContentDisplay> createState() => _StoryContentDisplayState();
}

class _StoryContentDisplayState extends State<StoryContentDisplay>
    with SingleTickerProviderStateMixin {
  /// Current block index being displayed
  int _currentBlockIndex = 0;
  
  /// Text-to-speech service
  late TTSService _ttsService;
  
  /// Whether narration is active
  bool _isNarrating = false;
  
  /// Animation controller for text and transitions
  late AnimationController _animationController;
  
  /// Text fade-in animation
  late Animation<double> _textFadeAnimation;
  
  /// Typing animation state
  bool _isTyping = false;
  
  /// Text currently displayed (used for typing animation)
  String _displayedText = '';
  
  /// Scroll controller for text scrolling
  final ScrollController _scrollController = ScrollController();
  
  /// Character portrait mapping
  final Map<String, String> _characterImages = {
    'kwaku': 'assets/images/characters/ananse_neutral.png',
    'nana yaw': 'assets/images/characters/nana_yaw.png',
    'auntie efua': 'assets/images/characters/auntie_efua.png',
    'ama': 'assets/images/characters/ama.png',
    'narrator': '',
  };

  @override
  void initState() {
    super.initState();
    _currentBlockIndex = widget.initialBlockIndex;
    _ttsService = TTSService();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _textFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    // Start displaying the initial content block
    if (widget.contentBlocks.isNotEmpty) {
      _displayContentBlock(_currentBlockIndex);
    }
  }

  @override
  void didUpdateWidget(StoryContentDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If content blocks changed or initial index changed, update display
    if (widget.contentBlocks != oldWidget.contentBlocks ||
        widget.initialBlockIndex != oldWidget.initialBlockIndex) {
      // Stop any ongoing narration
      _stopNarration();
      
      setState(() {
        _currentBlockIndex = widget.initialBlockIndex;
      });
      
      // Display the new content
      if (widget.contentBlocks.isNotEmpty) {
        _displayContentBlock(_currentBlockIndex);
      }
    }
    
    // Update TTS state if TTS setting changed
    if (widget.enableTTS != oldWidget.enableTTS && !widget.enableTTS) {
      _stopNarration();
    }
  }

  @override
  void dispose() {
    _stopNarration();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Display a specific content block with appropriate animations
  void _displayContentBlock(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= widget.contentBlocks.length) return;
    
    setState(() {
      _currentBlockIndex = blockIndex;
      _displayedText = '';
      _isTyping = true;
    });
    
    // Reset and start animation
    _animationController.reset();
    _animationController.forward();
    
    // Get the content block
    final block = widget.contentBlocks[blockIndex];
    final text = block['text'] as String;
    
    // Start typing animation
    _startTypingAnimation(text);
    
    // Start narration if enabled
    if (widget.enableTTS && !_isNarrating) {
      _speakContentBlock(block);
    }
  }

  /// Start the typing animation for text
  void _startTypingAnimation(String fullText) {
    _displayedText = '';
    _isTyping = true;
    
    // Calculate a reasonable typing speed based on text length
    final int charsPerSecond = fullText.length < 100 ? 25 : 40;
    final tickInterval = (1000 / charsPerSecond).round();
    
    int currentChar = 0;
    
    Future.doWhile(() async {
      if (!mounted || !_isTyping || currentChar >= fullText.length) {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _displayedText = fullText; // Ensure full text is shown
          });
          
          // Auto-advance to next block if enabled
          if (widget.autoAdvance && 
              _currentBlockIndex < widget.contentBlocks.length - 1 &&
              !_isNarrating) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              _moveToNextBlock();
            }
          }
        }
        return false;
      }
      
      await Future.delayed(Duration(milliseconds: tickInterval));
      
      if (mounted) {
        setState(() {
          currentChar++;
          _displayedText = fullText.substring(0, currentChar);
        });
        
        // Auto-scroll for longer text
        if (_scrollController.hasClients && 
            _scrollController.position.maxScrollExtent > 0) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      
      return true;
    });
  }

  /// Skip the typing animation and show the full text
  void _skipTypingAnimation() {
    if (_isTyping) {
      setState(() {
        _isTyping = false;
        
        // Show full text of current block
        if (_currentBlockIndex < widget.contentBlocks.length) {
          _displayedText = widget.contentBlocks[_currentBlockIndex]['text'] as String;
        }
      });
    } else {
      // If not typing, move to next block
      _moveToNextBlock();
    }
  }

  /// Move to the next content block if available
  void _moveToNextBlock() {
    if (_currentBlockIndex < widget.contentBlocks.length - 1) {
      // Call completion callback if provided
      if (widget.onBlockComplete != null) {
        widget.onBlockComplete!(widget.contentBlocks[_currentBlockIndex]);
      }
      
      _displayContentBlock(_currentBlockIndex + 1);
    } else if (widget.onBlockComplete != null) {
      // Call completion callback for the last block
      widget.onBlockComplete!(widget.contentBlocks[_currentBlockIndex]);
    }
  }

  /// Move to the previous content block if available
  void _moveToPreviousBlock() {
    if (_currentBlockIndex > 0) {
      _displayContentBlock(_currentBlockIndex - 1);
    }
  }

  /// Speak a content block using TTS
  void _speakContentBlock(Map<String, dynamic> block) async {
    if (!widget.enableTTS) return;
    
    setState(() {
      _isNarrating = true;
    });
    
    // Adjust voice based on speaker if present
    if (block.containsKey('speaker') && block['speaker'] != null) {
      await _setVoiceForCharacter(block['speaker'] as String);
    } else {
      await _setNarratorVoice();
    }
    
    // Speak the text
    await _ttsService.speak(block['text'] as String);
    
    if (mounted) {
      setState(() {
        _isNarrating = false;
      });
      
      // Auto-advance to next block if enabled
      if (widget.autoAdvance && _currentBlockIndex < widget.contentBlocks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _moveToNextBlock();
        }
      }
    }
  }

  /// Set TTS voice parameters for a specific character
  Future<void> _setVoiceForCharacter(String character) async {
    final lowerChar = character.toLowerCase();
    
    // Adjust voice parameters based on character
    switch (lowerChar) {
      case 'kwaku':
        await _ttsService.setPitch(1.2);
        await _ttsService.setRate(0.5);
        break;
      case 'nana yaw':
        await _ttsService.setPitch(0.8);
        await _ttsService.setRate(0.4);
        break;
      case 'auntie efua':
        await _ttsService.setPitch(1.1);
        await _ttsService.setRate(0.45);
        break;
      case 'ama':
        await _ttsService.setPitch(1.3);
        await _ttsService.setRate(0.5);
        break;
      default:
        await _setNarratorVoice();
    }
  }

  /// Set TTS voice parameters for the narrator
  Future<void> _setNarratorVoice() async {
    await _ttsService.setPitch(1.0);
    await _ttsService.setRate(0.45);
  }

  /// Stop any ongoing narration
  void _stopNarration() async {
    if (_isNarrating) {
      await _ttsService.stop();
      if (mounted) {
        setState(() {
          _isNarrating = false;
        });
      }
    }
  }

  /// Toggle narration on/off
  void _toggleNarration() {
    if (_isNarrating) {
      _stopNarration();
    } else {
      _speakContentBlock(widget.contentBlocks[_currentBlockIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentBlocks.isEmpty) {
      return const Center(
        child: Text('No content to display'),
      );
    }
    
    return Container(
      decoration: widget.backgroundImagePath != null
          ? BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.backgroundImagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.9),
                  BlendMode.lighten,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: _buildCurrentContent(),
              ),
            ),
          ),
          
          // Navigation controls
          _buildNavigationControls(),
        ],
      ),
    );
  }

  /// Build the content for the current block
  Widget _buildCurrentContent() {
    if (_currentBlockIndex >= widget.contentBlocks.length) {
      return const SizedBox.shrink();
    }
    
    final block = widget.contentBlocks[_currentBlockIndex];
    final type = block['type'] as String? ?? 'narration';
    final hasSpeaker = block.containsKey('speaker') && block['speaker'] != null;
    final speakerName = hasSpeaker ? block['speaker'] as String : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character header for dialogue
        if (type == 'dialogue' && hasSpeaker)
          _buildCharacterHeader(speakerName!),
          
        // Content text with appropriate styling
        GestureDetector(
          onTap: _skipTypingAnimation,
          child: Container(
            decoration: _getDecoration(type),
            padding: _getPadding(type),
            width: double.infinity,
            child: Text(
              _displayedText,
              style: _getTextStyle(context, type),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the character header with portrait
  Widget _buildCharacterHeader(String characterName) {
    final formattedName = characterName.split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
    
    final lowerName = characterName.toLowerCase();
    final hasCharacterImage = _characterImages.containsKey(lowerName) && 
                              _characterImages[lowerName]!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          if (hasCharacterImage)
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.kenteGold, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  _characterImages[lowerName]!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(Icons.person),
                ),
              ),
            ),
          Text(
            formattedName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.kenteGold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation and control buttons
  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentBlockIndex > 0 ? _moveToPreviousBlock : null,
            tooltip: 'Previous',
          ),
          
          // Narration control
          if (widget.enableTTS)
            IconButton(
              icon: Icon(_isNarrating ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleNarration,
              tooltip: _isNarrating ? 'Pause narration' : 'Play narration',
              color: AppTheme.kenteGold,
            ),
          
          // Navigation indicator
          if (widget.contentBlocks.length > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.contentBlocks.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBlockIndex == index
                        ? AppTheme.kenteGold
                        : Colors.grey.withOpacity(0.3),
                  ),
                );
              }),
            ),
          
          // Next button
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentBlockIndex < widget.contentBlocks.length - 1 
                ? _moveToNextBlock 
                : null,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  /// Get decoration based on content type
  BoxDecoration? _getDecoration(String type) {
    switch (type) {
      case 'dialogue':
        return BoxDecoration(
          color: AppTheme.kenteGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.kenteGold.withOpacity(0.3),
            width: 1,
          ),
        );
      case 'cultural_context':
        return BoxDecoration(
          color: AppTheme.kenteBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.kenteBlue.withOpacity(0.3),
            width: 1,
          ),
        );
      case 'instruction':
        return BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        );
      default:
        return null;
    }
  }

  /// Get padding based on content type
  EdgeInsets _getPadding(String type) {
    switch (type) {
      case 'dialogue':
      case 'cultural_context':
      case 'instruction':
        return const EdgeInsets.all(16);
      default:
        return EdgeInsets.zero;
    }
  }

  /// Get text style based on content type
  TextStyle? _getTextStyle(BuildContext context, String type) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    
    switch (type) {
      case 'dialogue':
        return baseStyle?.copyWith(
          fontStyle: FontStyle.normal,
        );
      case 'cultural_context':
        return baseStyle?.copyWith(
          color: AppTheme.kenteBlue,
          fontStyle: FontStyle.italic,
        );
      case 'instruction':
        return baseStyle?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        );
      case 'narration':
        return baseStyle?.copyWith(
          color: Colors.black87,
        );
      default:
        return baseStyle;
    }
  }
}
