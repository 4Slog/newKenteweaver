class TutorialInteractiveElements extends StatefulWidget {
  final TutorialVisualController controller;
  final NarrationService narrationService;
  final Function(String) onInteraction;

  TutorialInteractiveElements({
    required this.controller,
    required this.narrationService,
    required this.onInteraction,
  });

  @override
  _TutorialInteractiveElementsState createState() =>
      _TutorialInteractiveElementsState();
}

class _TutorialInteractiveElementsState extends State<TutorialInteractiveElements> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Navigation controls
        _buildNavigationControls(),
        
        // Help button
        _buildHelpButton(),
        
        // Interactive prompts
        _buildInteractivePrompts(),
        
        // Feedback indicators
        _buildFeedbackIndicators(),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replay button
          FloatingActionButton(
            heroTag: 'replay',
            mini: true,
            onPressed: () {
              widget.narrationService.replayCurrentNarration();
            },
            child: Icon(Icons.replay),
          ),
          SizedBox(width: 8),
          // Next button
          FloatingActionButton(
            heroTag: 'next',
            onPressed: widget.controller.isTransitioning
                ? null
                : () => widget.onInteraction('next'),
            child: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTapDown: (details) => _showHelpMenu(context, details.globalPosition),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.help_outline,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractivePrompts() {
    return ValueListenableBuilder<TutorialState>(
      valueListenable: widget.controller.currentStateNotifier,
      builder: (context, state, child) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _buildPromptForState(state),
        );
      },
    );
  }

  Widget _buildPromptForState(TutorialState state) {
    switch (state) {
      case TutorialState.blockIntroduction:
        return _buildTapPrompt('Tap any block to learn more about it');
      case TutorialState.firstBlock:
        return _buildDragPrompt('Drag the Start block to the workspace');
      case TutorialState.connecting:
        return _buildConnectionPrompt('Connect blocks by dragging them together');
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildTapPrompt(String message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app),
          SizedBox(width: 8),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildFeedbackIndicators() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.showFeedback,
      builder: (context, showFeedback, child) {
        if (!showFeedback) return SizedBox.shrink();
        
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                'Well done!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          child: Text('Replay Instructions'),
          onTap: () => widget.narrationService.replayCurrentNarration(),
        ),
        PopupMenuItem(
          child: Text('Show Hints'),
          onTap: () => widget.onInteraction('show_hints'),
        ),
        PopupMenuItem(
          child: Text('Skip Tutorial'),
          onTap: () => widget.onInteraction('skip'),
        ),
      ],
    );
  }
} 