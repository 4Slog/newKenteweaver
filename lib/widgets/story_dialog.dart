import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class StoryDialog extends StatefulWidget {
  final String title;
  final String content;
  final String imagePath;
  final List<Map<String, dynamic>> contentBlocks;
  final bool hasChoices;
  final List<Map<String, dynamic>> choices;
  final bool ttsEnabled;

  const StoryDialog({
    super.key,
    required this.title,
    required this.content,
    required this.imagePath,
    this.contentBlocks = const [],
    required this.hasChoices,
    required this.choices,
    this.ttsEnabled = true,
  });

  @override
  State<StoryDialog> createState() => _StoryDialogState();
}

class _StoryDialogState extends State<StoryDialog> with SingleTickerProviderStateMixin {
  bool _isNarrating = false;
  late TTSService _ttsService;
  int _currentBlockIndex = 0;
  bool _isTyping = false;
  String _displayedText = '';
  
  // For text animation
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  
  // Character portraits
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
    _ttsService = TTSService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Start the typing animation for the first content block
    _initializeContent();
  }
  
  @override
  void dispose() {
    _stopNarration();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _initializeContent() {
    if (widget.contentBlocks.isNotEmpty) {
      _animateBlockText(0);
    } else {
      // If no content blocks, use the main content field
      _startTypingAnimation(widget.content);
      
      // Auto-narrate if enabled
      if (widget.ttsEnabled) {
        _startNarration();
      }
    }
  }
  
  void _animateBlockText(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= widget.contentBlocks.length) return;
    
    setState(() {
      _currentBlockIndex = blockIndex;
      _displayedText = '';
      _isTyping = true;
    });
    
    final block = widget.contentBlocks[blockIndex];
    final text = block['text'] as String;
    
    _startTypingAnimation(text);
    
    // If TTS is enabled, narrate this block
    if (widget.ttsEnabled && !_isNarrating) {
      _speakContentBlock(block);
    }
  }
  
  void _startTypingAnimation(String fullText) {
    _displayedText = '';
    _isTyping = true;
    
    // Calculate a reasonable typing speed (characters per second)
    // Adjust based on text length - longer texts should be faster
    final int charsPerSecond = fullText.length < 100 ? 25 : 40;
    final int totalDuration = (fullText.length / charsPerSecond * 1000).round();
    
    // Use a ticker to simulate typing effect
    int currentChar = 0;
    final tickInterval = (1000 / charsPerSecond).round();
    
    Future.doWhile(() async {
      if (!mounted || !_isTyping || currentChar >= fullText.length) {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _displayedText = fullText; // Ensure the full text is displayed
          });
        }
        return false;
      }
      
      await Future.delayed(Duration(milliseconds: tickInterval));
      
      if (mounted) {
        setState(() {
          currentChar++;
          _displayedText = fullText.substring(0, currentChar);
        });
        
        // Auto-scroll if needed
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
  
  void _speakContentBlock(Map<String, dynamic> block) async {
    if (!widget.ttsEnabled) return;
    
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
    
    // Move to next block if available
    if (mounted) {
      setState(() {
        _isNarrating = false;
      });
      
      // Advance to next block after a small delay
      if (_currentBlockIndex < widget.contentBlocks.length - 1) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _animateBlockText(_currentBlockIndex + 1);
          }
        });
      }
    }
  }
  
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
  
  Future<void> _setNarratorVoice() async {
    await _ttsService.setPitch(1.0);
    await _ttsService.setRate(0.45);
  }

  void _startNarration() async {
    if (!widget.ttsEnabled) return;
    
    setState(() {
      _isNarrating = true;
    });
    
    if (widget.contentBlocks.isNotEmpty) {
      // Handle structured content with content blocks
      _speakContentBlock(widget.contentBlocks.first);
    } else {
      // Legacy support for simple content
      await _ttsService.speak(widget.content);
      
      if (mounted) {
        setState(() {
          _isNarrating = false;
        });
      }
    }
  }
  
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
  
  void _toggleNarration() {
    if (_isNarrating) {
      _stopNarration();
    } else {
      _startNarration();
    }
  }
  
  void _skipTypingAnimation() {
    if (_isTyping) {
      setState(() {
        _isTyping = false;
        
        // Show full text of current block
        if (widget.contentBlocks.isNotEmpty) {
          _displayedText = widget.contentBlocks[_currentBlockIndex]['text'] as String;
        } else {
          _displayedText = widget.content;
        }
      });
    } else if (widget.contentBlocks.isNotEmpty && 
               _currentBlockIndex < widget.contentBlocks.length - 1) {
      // Move to next content block if available
      _animateBlockText(_currentBlockIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: widget.contentBlocks.isNotEmpty &&
               _currentBlockIndex < widget.contentBlocks.length && 
               widget.contentBlocks[_currentBlockIndex]['type'] == 'cultural_context'
          ? DecorationImage(
              image: const AssetImage('assets/images/story/background_pattern.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.2),
                BlendMode.lighten,
              ),
            )
          : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.kenteGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Content section
          if (widget.contentBlocks.isEmpty)
            _buildLegacyContent()
          else
            _buildStructuredContent(),
          
          // Narration control and choices
          _buildActionControls(),
        ],
      ),
    );
  }
  
  Widget _buildLegacyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image
        if (widget.imagePath.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              widget.imagePath,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        
        // Content
        GestureDetector(
          onTap: _skipTypingAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                _displayedText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStructuredContent() {
    if (_currentBlockIndex >= widget.contentBlocks.length) {
      return const SizedBox.shrink();
    }
    
    final block = widget.contentBlocks[_currentBlockIndex];
    final type = block['type'] as String;
    final hasImage = widget.imagePath.isNotEmpty;
    final hasSpeaker = block.containsKey('speaker') && block['speaker'] != null;
    final speakerName = hasSpeaker ? block['speaker'] as String : null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Character portrait and name for dialogue
        if (type == 'dialogue' && hasSpeaker)
          _buildCharacterHeader(speakerName!),
        
        // Image - show for narration or at beginning of sequence
        if (hasImage && (type == 'narration' || _currentBlockIndex == 0))
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                widget.imagePath,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
        const SizedBox(height: 16),
        
        // Content
        GestureDetector(
          onTap: _skipTypingAnimation,
          child: Container(
            decoration: type == 'dialogue'
                ? BoxDecoration(
                    color: AppTheme.kenteGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.kenteGold.withOpacity(0.3),
                      width: 1,
                    ),
                  )
                : null,
            padding: type == 'dialogue' ? const EdgeInsets.all(12) : EdgeInsets.zero,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                _displayedText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: type == 'dialogue' ? FontStyle.normal : FontStyle.normal,
                  color: type == 'cultural_context' ? AppTheme.kenteBlue : null,
                ),
              ),
            ),
          ),
        ),
        
        // Block navigation indicator if multiple blocks
        if (widget.contentBlocks.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ),
      ],
    );
  }
  
  Widget _buildCharacterHeader(String characterName) {
    final formattedName = characterName.split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
    
    final lowerName = characterName.toLowerCase();
    final hasCharacterImage = _characterImages.containsKey(lowerName) && 
                              _characterImages[lowerName]!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          if (hasCharacterImage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.kenteGold, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  _characterImages[lowerName]!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Text(
            formattedName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.kenteGold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        
        // Narration control
        if (widget.ttsEnabled)
          Center(
            child: IconButton(
              icon: Icon(_isNarrating ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleNarration,
              tooltip: _isNarrating ? 'Pause narration' : 'Play narration',
              color: AppTheme.kenteGold,
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Choices
        if (widget.hasChoices)
          ..._buildChoiceButtons()
        else
          _buildContinueButton(),
      ],
    );
  }
  
  List<Widget> _buildChoiceButtons() {
    return widget.choices.map((choice) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton(
          onPressed: () {
            _stopNarration();
            (choice['onTap'] as VoidCallback)();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.kenteGold,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            choice['text'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }
  
  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: () {
        _stopNarration();
        (widget.choices.first['onTap'] as VoidCallback)();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.kenteGold,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        widget.choices.first['text'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
