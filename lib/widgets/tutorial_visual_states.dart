enum TutorialState {
  introduction,
  workspaceReveal,
  blockIntroduction,
  firstBlock,
  connecting,
  patternPreview,
  completion
}

class TutorialVisualController extends ChangeNotifier {
  TutorialState _currentState = TutorialState.introduction;
  bool _isTransitioning = false;
  double _progressValue = 0.0;

  // Animated properties
  final workspaceOpacity = ValueNotifier<double>(0.0);
  final blockScale = ValueNotifier<double>(1.0);
  final highlightIntensity = ValueNotifier<double>(0.0);
  
  TutorialState get currentState => _currentState;
  bool get isTransitioning => _isTransitioning;
  double get progress => _progressValue;

  Future<void> transitionTo(TutorialState newState) async {
    _isTransitioning = true;
    notifyListeners();

    // Handle state-specific transitions
    switch (newState) {
      case TutorialState.workspaceReveal:
        await _animateWorkspaceReveal();
        break;
      case TutorialState.blockIntroduction:
        await _animateBlockIntroduction();
        break;
      // Add more state transitions...
    }

    _currentState = newState;
    _isTransitioning = false;
    _updateProgress();
    notifyListeners();
  }

  Future<void> _animateWorkspaceReveal() async {
    await workspaceOpacity.animateTo(
      1.0,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _animateBlockIntroduction() async {
    await blockScale.animateTo(
      1.2,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
    await blockScale.animateTo(
      1.0,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
  }

  void _updateProgress() {
    _progressValue = _currentState.index / TutorialState.values.length;
    notifyListeners();
  }
} 