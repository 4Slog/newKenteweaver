import 'package:flutter/foundation.dart';

/// Service responsible for handling tutorial narration and audio feedback
class NarrationService {
  bool _isPlaying = false;
  String _currentText = '';

  /// Toggles the playback state of the current narration
  void togglePlayback() {
    _isPlaying = !_isPlaying;
  }

  /// Skips to the next narration section
  void skipToNext() {
    // Implementation for skipping to next section
  }

  /// Gets the text for the restart option
  String getRestartText() => 'Restart Tutorial';

  /// Gets the text for the skip option
  String getSkipText() => 'Skip Tutorial';

  /// Gets the text for the help option
  String getHelpText() => 'Show Help';

  /// Gets the current narration text
  String getCurrentText() => _currentText;

  /// Sets the current narration text
  void setCurrentText(String text) {
    _currentText = text;
  }

  /// Checks if narration is currently playing
  bool isPlaying() => _isPlaying;
} 
