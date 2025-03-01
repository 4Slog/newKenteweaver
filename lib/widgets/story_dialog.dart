import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class StoryDialog extends StatefulWidget {
  final String title;
  final String content;
  final String imagePath;
  final bool hasChoices;
  final List<Map<String, dynamic>> choices;

  const StoryDialog({
    super.key,
    required this.title,
    required this.content,
    required this.imagePath,
    required this.hasChoices,
    required this.choices,
  });

  @override
  State<StoryDialog> createState() => _StoryDialogState();
}

class _StoryDialogState extends State<StoryDialog> {
  bool _isNarrating = false;
  late TTSService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = TTSService();
    
    // Start narration automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNarration();
    });
  }
  
  @override
  void dispose() {
    _stopNarration();
    super.dispose();
  }
  
  void _startNarration() async {
    if (_ttsService.ttsEnabled) {
      setState(() {
        _isNarrating = true;
      });
      
      // Narrate the title and content
      final fullText = "${widget.title}. ${widget.content}";
      await _ttsService.speak(fullText);
      
      // Update state when narration is complete
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            widget.content,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Narration control
          IconButton(
            icon: Icon(_isNarrating ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleNarration,
            tooltip: _isNarrating ? 'Pause narration' : 'Play narration',
            color: AppTheme.kenteGold,
          ),
          const SizedBox(height: 16),
          
          // Choices
          if (widget.hasChoices)
            Column(
              children: widget.choices.map((choice) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      _stopNarration(); // Stop narration when a choice is made
                      (choice['onTap'] as VoidCallback)();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(choice['text'] as String),
                  ),
                );
              }).toList(),
            )
          else
            ElevatedButton(
              onPressed: () {
                _stopNarration(); // Stop narration when continuing
                (widget.choices.first['onTap'] as VoidCallback)();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: Text(widget.choices.first['text'] as String),
            ),
        ],
      ),
    );
  }
}
