import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';
import '../services/audio_service.dart';
import '../models/content_block_model.dart';
import '../models/emotional_tone.dart';

/// Service responsible for handling story narration and audio feedback
class NarrationService extends ChangeNotifier {
  final TTSService _ttsService;
  final AudioService _audioService;
  
  bool _isPlaying = false;
  String _currentText = '';
  List<ContentBlock> _narrationQueue = [];
  int _currentBlockIndex = 0;
  
  /// Whether narration is currently playing
  bool get isPlaying => _isPlaying;
  
  /// The current narration text
  String get currentText => _currentText;
  
  /// The current narration queue
  List<ContentBlock> get narrationQueue => List.unmodifiable(_narrationQueue);
  
  /// The current block index
  int get currentBlockIndex => _currentBlockIndex;
  
  /// Creates a new instance of NarrationService
  NarrationService({
    required TTSService ttsService,
    required AudioService audioService,
  }) : _ttsService = ttsService,
       _audioService = audioService {
    // Listen for TTS completion events
    _ttsService.onComplete.listen((_) {
      _advanceNarration();
    });
  }
  
  /// Speak a simple text string using the default character and tone
  Future<void> speak(String text, {String? characterId, EmotionalTone? tone}) async {
    // Stop any ongoing narration
    await stop();
    
    // Set current text
    _currentText = text;
    _isPlaying = true;
    notifyListeners();
    
    // Speak the text
    await _ttsService.speakAsCharacter(
      text: text,
      characterId: characterId ?? 'narrator',
      tone: tone ?? EmotionalTone.neutral,
    );
  }
  
  /// Start narrating a list of content blocks
  Future<void> startNarration(List<ContentBlock> blocks) async {
    _narrationQueue = blocks;
    _currentBlockIndex = 0;
    _isPlaying = true;
    notifyListeners();
    
    await _narrateCurrentBlock();
  }
  
  /// Narrate the current block
  Future<void> _narrateCurrentBlock() async {
    if (_currentBlockIndex >= _narrationQueue.length) {
      _isPlaying = false;
      notifyListeners();
      return;
    }
    
    final block = _narrationQueue[_currentBlockIndex];
    _currentText = block.content;
    
    // Play appropriate background audio
    if (block.backgroundAudio != null) {
      await _audioService.playBackgroundSound(block.backgroundAudio);
    }
    
    // Speak with appropriate character and tone
    await _ttsService.speakAsCharacter(
      text: block.content,
      characterId: block.speaker ?? 'narrator',
      tone: block.emotionalTone,
    );
    
    notifyListeners();
  }
  
  /// Advance to the next narration block
  void _advanceNarration() {
    if (!_isPlaying) return;
    
    _currentBlockIndex++;
    if (_currentBlockIndex < _narrationQueue.length) {
      _narrateCurrentBlock();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  /// Pause narration
  void pauseNarration() {
    _isPlaying = false;
    _ttsService.stop();
    notifyListeners();
  }
  
  /// Resume narration
  void resumeNarration() {
    _isPlaying = true;
    _narrateCurrentBlock();
    notifyListeners();
  }
  
  /// Skip to next block
  void skipToNext() {
    _ttsService.stop();
    _advanceNarration();
  }
  
  /// Skip to previous block
  void skipToPrevious() {
    if (_currentBlockIndex > 0) {
      _ttsService.stop();
      _currentBlockIndex--;
      _narrateCurrentBlock();
    }
  }
  
  /// Get the text for the restart option
  String getRestartText() => 'Restart Narration';

  /// Get the text for the skip option
  String getSkipText() => 'Skip Narration';

  /// Get the text for the help option
  String getHelpText() => 'Show Help';
  
  /// Restart narration from the beginning
  void restartNarration() {
    _ttsService.stop();
    _currentBlockIndex = 0;
    _isPlaying = true;
    _narrateCurrentBlock();
    notifyListeners();
  }
  
  /// Stop narration completely
  Future<void> stop() async {
    await _ttsService.stop();
    _isPlaying = false;
    _narrationQueue = [];
    _currentBlockIndex = 0;
    _currentText = '';
    notifyListeners();
  }
} 