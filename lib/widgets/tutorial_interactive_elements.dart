import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TutorialVisualController extends ChangeNotifier {
  final ValueNotifier<TutorialState> currentState = ValueNotifier(TutorialState.initial);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String> statusMessage = ValueNotifier('');

  void updateState(TutorialState newState) {
    currentState.value = newState;
    notifyListeners();
  }

  void setLoading(bool loading, [String message = '']) {
    isLoading.value = loading;
    statusMessage.value = message;
    notifyListeners();
  }

  void updateProgress(double progress, {Curve curve = Curves.easeInOut}) {
    // Implementation for progress updates
  }

  void showHint(String hint, {Curve curve = Curves.easeInOut}) {
    // Implementation for showing hints
  }

  void hideHint({Curve curve = Curves.easeInOut}) {
    // Implementation for hiding hints
  }
}

class TutorialInteractiveElements extends StatefulWidget {
  final TutorialVisualController controller;
  final TTSService ttsService;

  const TutorialInteractiveElements({
    super.key,
    required this.controller,
    required this.ttsService,
  });

  @override
  State<TutorialInteractiveElements> createState() => _TutorialInteractiveElementsState();
}

class _TutorialInteractiveElementsState extends State<TutorialInteractiveElements> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildNavigationControls(),
        _buildStatusOverlay(),
        _buildInteractionOverlay(),
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
          FloatingActionButton(
            onPressed: () {
              if (widget.ttsService.isSpeaking) {
                widget.ttsService.stop();
              } else {
                widget.ttsService.speak(_getStatusText(widget.controller.currentState.value));
              }
            },
            child: const Icon(Icons.play_arrow),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () {
              widget.ttsService.stop();
              widget.controller.updateState(TutorialState.next);
            },
            child: const Icon(Icons.skip_next),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: GestureDetector(
        onTapUp: (details) => _showOptionsMenu(context, details.globalPosition),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(),
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionOverlay() {
    return ValueListenableBuilder<TutorialState>(
      valueListenable: widget.controller.currentState,
      builder: (context, state, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStateSpecificOverlay(state),
        );
      },
    );
  }

  Widget _buildStateSpecificOverlay(TutorialState state) {
    switch (state) {
      case TutorialState.initial:
        return _buildDragPrompt();
      case TutorialState.dragging:
        return _buildConnectionPrompt();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDragPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app),
          const SizedBox(width: 8),
          Text('Drag a block to start'),
        ],
      ),
    );
  }

  Widget _buildConnectionPrompt() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.autorenew,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.controller.statusMessage.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _showOptionsMenu(BuildContext context, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'restart',
          child: Text('Restart Tutorial'),
        ),
        const PopupMenuItem<String>(
          value: 'skip',
          child: Text('Skip Tutorial'),
        ),
        const PopupMenuItem<String>(
          value: 'help',
          child: Text('Get Help'),
        ),
      ],
    );

    if (result != null) {
      switch (result) {
        case 'restart':
          widget.controller.updateState(TutorialState.initial);
          break;
        case 'skip':
          widget.controller.updateState(TutorialState.completed);
          break;
        case 'help':
          widget.controller.showHint('Try connecting blocks to create patterns');
          break;
      }
    }
  }

  IconData _getStatusIcon() {
    switch (widget.controller.currentState.value) {
      case TutorialState.initial:
        return Icons.play_circle_outline;
      case TutorialState.dragging:
        return Icons.drag_indicator;
      case TutorialState.connecting:
        return Icons.link;
      case TutorialState.completed:
        return Icons.check_circle_outline;
      case TutorialState.error:
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(TutorialState state) {
    switch (state) {
      case TutorialState.initial:
        return 'Start the tutorial';
      case TutorialState.dragging:
        return 'Drag blocks to build';
      case TutorialState.connecting:
        return 'Connect the blocks';
      case TutorialState.completed:
        return 'Tutorial completed';
      case TutorialState.error:
        return 'Something went wrong';
      default:
        return 'Tutorial in progress';
    }
  }
}

enum TutorialState {
  initial,
  dragging,
  connecting,
  completed,
  error,
  next,
} 
