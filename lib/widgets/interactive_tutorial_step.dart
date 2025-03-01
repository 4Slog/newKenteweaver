import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_tutorial_hint.dart';

enum TutorialStepType {
  introduction,
  blockDragging,
  patternSelection,
  colorSelection,
  loopUsage,
  rowColumns,
  culturalContext,
  challenge,
}

class InteractiveTutorialStep extends StatefulWidget {
  final String title;
  final String description;
  final TutorialStepType type;
  final String? imageAsset;
  final Widget? interactiveArea;
  final bool isCompleted;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final String? hint;
  final Widget? nextStepPreview;

  const InteractiveTutorialStep({
    Key? key,
    required this.title,
    required this.description,
    required this.type,
    this.imageAsset,
    this.interactiveArea,
    this.isCompleted = false,
    this.onComplete,
    this.onSkip,
    this.hint,
    this.nextStepPreview,
  }) : super(key: key);

  @override
  State<InteractiveTutorialStep> createState() => _InteractiveTutorialStepState();
}

class _InteractiveTutorialStepState extends State<InteractiveTutorialStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _showHint = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });

    if (_showHint) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 32),
            _buildDescription(),
            if (widget.imageAsset != null)
              _buildImage(),
            if (widget.interactiveArea != null)
              _buildInteractiveArea(),
            if (widget.hint != null && _showHint)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AnimatedTutorialHint(
                  text: widget.hint!,
                  onClose: _toggleHint,
                ),
              ),
            const SizedBox(height: 24),
            _buildActions(),
            if (widget.nextStepPreview != null && widget.isCompleted)
              _buildNextStepPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildTypeIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color backgroundColor;
    Color iconColor;

    switch (widget.type) {
      case TutorialStepType.introduction:
        icon = Icons.lightbulb_outline;
        backgroundColor = Colors.amber.withOpacity(0.1);
        iconColor = Colors.amber[800]!;
        break;
      case TutorialStepType.blockDragging:
        icon = Icons.drag_indicator;
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
        break;
      case TutorialStepType.patternSelection:
        icon = Icons.grid_on;
        backgroundColor = AppTheme.kenteBlue.withOpacity(0.1);
        iconColor = AppTheme.kenteBlue;
        break;
      case TutorialStepType.colorSelection:
        icon = Icons.palette;
        backgroundColor = Colors.purple.withOpacity(0.1);
        iconColor = Colors.purple;
        break;
      case TutorialStepType.loopUsage:
        icon = Icons.repeat;
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        break;
      case TutorialStepType.rowColumns:
        icon = Icons.table_chart;
        backgroundColor = Colors.teal.withOpacity(0.1);
        iconColor = Colors.teal;
        break;
      case TutorialStepType.culturalContext:
        icon = Icons.history_edu;
        backgroundColor = AppTheme.kenteGold.withOpacity(0.1);
        iconColor = AppTheme.kenteGold;
        break;
      case TutorialStepType.challenge:
        icon = Icons.emoji_events;
        backgroundColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.description,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          widget.imageAsset!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 32,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInteractiveArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: GestureDetector(
        onTap: () {
          if (!_hasInteracted) {
            setState(() {
              _hasInteracted = true;
            });
          }
        },
        child: widget.interactiveArea,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.hint != null)
          TextButton.icon(
            onPressed: _toggleHint,
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 18,
            ),
            label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.kenteGold,
            ),
          )
        else
          const SizedBox(),

        Row(
          children: [
            if (widget.onSkip != null && !widget.isCompleted)
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('Skip'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            const SizedBox(width: 8),
            if (widget.onComplete != null && !widget.isCompleted)
              ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kenteGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Continue'),
              )
            else if (widget.isCompleted)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextStepPreview() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Next Step',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[200]!,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: 0.7,
                child: widget.nextStepPreview,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
