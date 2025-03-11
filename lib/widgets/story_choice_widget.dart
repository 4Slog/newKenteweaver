import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A widget that presents story choices to the user with
/// interactive UI elements and visual feedback.
class StoryChoiceWidget extends StatefulWidget {
  /// List of choices to display
  final List<Map<String, dynamic>> choices;
  
  /// Callback when a choice is selected
  final Function(String, Map<String, dynamic>) onChoiceSelected;
  
  /// How long to show selection animation before callback
  final Duration selectionDelay;
  
  /// Visual style for the choice buttons
  final StoryChoiceStyle style;
  
  /// Enable haptic feedback on selection
  final bool enableHapticFeedback;
  
  /// Maximum number of choices to display in one column
  /// If more choices, will use a scrollable view
  final int maxVisibleChoices;

  const StoryChoiceWidget({
    Key? key,
    required this.choices,
    required this.onChoiceSelected,
    this.selectionDelay = const Duration(milliseconds: 300),
    this.style = StoryChoiceStyle.standard,
    this.enableHapticFeedback = true,
    this.maxVisibleChoices = 4,
  }) : super(key: key);

  @override
  State<StoryChoiceWidget> createState() => _StoryChoiceWidgetState();
}

class _StoryChoiceWidgetState extends State<StoryChoiceWidget> with SingleTickerProviderStateMixin {
  /// Currently selected choice index
  int? _selectedIndex;
  
  /// Animation controller for selection visual feedback
  late AnimationController _animationController;
  
  /// Selection highlight animation
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.selectionDelay,
    );
    
    _selectionAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _selectedIndex != null) {
        // When animation completes, call the selection handler
        _completeSelection();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handle choice selection with animation and feedback
  void _handleChoiceSelection(int index) {
    if (_selectedIndex != null) return; // Prevent multiple selections
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Start animation for visual feedback
    _animationController.forward();
  }

  /// Complete the selection process after animation
  void _completeSelection() {
    if (_selectedIndex == null) return;
    
    final selectedChoice = widget.choices[_selectedIndex!];
    final choiceId = selectedChoice['id'] as String? ?? _selectedIndex.toString();
    
    widget.onChoiceSelected(choiceId, selectedChoice);
  }

  @override
  Widget build(BuildContext context) {
    // If no choices, return empty container
    if (widget.choices.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Decide if we need scrolling
    final needsScrolling = widget.choices.length > widget.maxVisibleChoices;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: _getContainerDecoration(),
      child: needsScrolling
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildChoiceButtons(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildChoiceButtons(),
            ),
    );
  }

  /// Build the list of choice buttons
  List<Widget> _buildChoiceButtons() {
    return List.generate(
      widget.choices.length,
      (index) => _buildChoiceButton(index),
    );
  }

  /// Build an individual choice button
  Widget _buildChoiceButton(int index) {
    final choice = widget.choices[index];
    final text = choice['text'] as String;
    final isDisabled = choice['disabled'] as bool? ?? false;
    final disabledReason = choice['disabled_reason'] as String?;
    final isSelected = _selectedIndex == index;
    
    // For visually marking consequences
    final hasPositiveConsequence = choice['consequence_type'] == 'positive';
    final hasNegativeConsequence = choice['consequence_type'] == 'negative';
    final hasUnknownConsequence = choice['consequence_type'] == 'unknown';
    
    // Choice button color based on consequence type and selection state
    Color buttonColor;
    if (isSelected) {
      buttonColor = AppTheme.kenteGold;
    } else if (isDisabled) {
      buttonColor = Colors.grey.shade300;
    } else if (hasPositiveConsequence) {
      buttonColor = Colors.green.shade100;
    } else if (hasNegativeConsequence) {
      buttonColor = Colors.red.shade100;
    } else if (hasUnknownConsequence) {
      buttonColor = Colors.purple.shade100;
    } else {
      buttonColor = Colors.white;
    }
    
    // Animated container for selection effect
    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: isSelected ? 4.0 * _selectionAnimation.value : 1.0,
                borderRadius: BorderRadius.circular(12),
                color: isSelected 
                    ? Color.lerp(buttonColor, AppTheme.kenteGold, _selectionAnimation.value)
                    : buttonColor,
                child: InkWell(
                  onTap: isDisabled ? null : () => _handleChoiceSelection(index),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: AppTheme.kenteGold.withOpacity(0.3),
                  highlightColor: AppTheme.kenteGold.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                    child: _buildChoiceContent(choice, isSelected, isDisabled),
                  ),
                ),
              ),
              
              // Show disabled reason if the choice is disabled and has a reason
              if (isDisabled && disabledReason != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    disabledReason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build the content of a choice button based on the style
  Widget _buildChoiceContent(Map<String, dynamic> choice, bool isSelected, bool isDisabled) {
    final text = choice['text'] as String;
    final description = choice['description'] as String?;
    final icon = choice['icon'] as IconData? ?? _getDefaultIcon(choice);
    
    switch (widget.style) {
      case StoryChoiceStyle.compact:
        return _buildCompactChoice(text, icon, isSelected, isDisabled);
      case StoryChoiceStyle.descriptive:
        return _buildDescriptiveChoice(text, description, icon, isSelected, isDisabled);
      case StoryChoiceStyle.standard:
        return _buildStandardChoice(text, icon, isSelected, isDisabled);
    }
  }

  /// Build a standard choice with text and optional icon
  Widget _buildStandardChoice(String text, IconData? icon, bool isSelected, bool isDisabled) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: isSelected 
                ? Colors.black 
                : isDisabled ? Colors.grey : AppTheme.kenteGold,
            size: 20,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? Colors.black 
                  : isDisabled ? Colors.grey.shade600 : Colors.black87,
            ),
          ),
        ),
        if (isSelected)
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.black,
          ),
      ],
    );
  }

  /// Build a compact choice (text only, center aligned)
  Widget _buildCompactChoice(String text, IconData? icon, bool isSelected, bool isDisabled) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? Colors.black 
              : isDisabled ? Colors.grey.shade600 : Colors.black87,
        ),
      ),
    );
  }

  /// Build a descriptive choice with title and description
  Widget _buildDescriptiveChoice(
    String text, 
    String? description, 
    IconData? icon, 
    bool isSelected, 
    bool isDisabled
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              icon,
              color: isSelected 
                  ? Colors.black 
                  : isDisabled ? Colors.grey : AppTheme.kenteGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Colors.black 
                      : isDisabled ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected 
                        ? Colors.black.withValues(alpha: 0.7)
                        : isDisabled ? Colors.grey.shade400 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isSelected)
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.black,
          ),
      ],
    );
  }

  /// Get container decoration based on style
  BoxDecoration _getContainerDecoration() {
    switch (widget.style) {
      case StoryChoiceStyle.compact:
        return const BoxDecoration(
          color: Colors.transparent,
        );
      case StoryChoiceStyle.descriptive:
        return BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        );
      case StoryChoiceStyle.standard:
        return const BoxDecoration(
          color: Colors.transparent,
        );
    }
  }

  /// Get default icon based on choice data
  IconData? _getDefaultIcon(Map<String, dynamic> choice) {
    final type = choice['type'] as String?;
    final consequenceType = choice['consequence_type'] as String?;
    
    if (type == 'action') return Icons.flash_on;
    if (type == 'dialogue') return Icons.chat_bubble_outline;
    if (type == 'wait') return Icons.hourglass_empty;
    if (type == 'exit') return Icons.exit_to_app;
    if (type == 'challenge') return Icons.extension;
    if (type == 'cultural') return Icons.info_outline;
    
    if (consequenceType == 'positive') return Icons.thumb_up_outlined;
    if (consequenceType == 'negative') return Icons.thumb_down_outlined;
    if (consequenceType == 'unknown') return Icons.help_outline;
    
    return null;
  }
}

/// Style options for choice buttons
enum StoryChoiceStyle {
  /// Standard style with left-aligned text and optional icon
  standard,
  
  /// Compact style with center-aligned text only
  compact,
  
  /// Descriptive style with title and description
  descriptive,
}

/// Extension to create story choices from simple data structures
extension StoryChoiceExtension on StoryChoiceWidget {
  /// Create a standard choice widget from a list of text choices
  static StoryChoiceWidget fromTextChoices({
    required List<String> choices,
    required Function(int) onSelected,
    StoryChoiceStyle style = StoryChoiceStyle.standard,
    bool enableHapticFeedback = true,
  }) {
    final formattedChoices = choices.asMap().entries.map((entry) {
      return {
        'id': entry.key.toString(),
        'text': entry.value,
      };
    }).toList();
    
    return StoryChoiceWidget(
      choices: formattedChoices,
      onChoiceSelected: (id, choice) => onSelected(int.parse(id)),
      style: style,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
  
  /// Create a widget for a yes/no choice
  static StoryChoiceWidget yesNo({
    required Function(bool) onSelected,
    String yesText = 'Yes',
    String noText = 'No',
    bool enableHapticFeedback = true,
  }) {
    return StoryChoiceWidget(
      choices: [
        {
          'id': 'yes',
          'text': yesText,
          'icon': Icons.check_circle_outline,
          'consequence_type': 'positive',
        },
        {
          'id': 'no',
          'text': noText,
          'icon': Icons.cancel_outlined,
          'consequence_type': 'negative',
        },
      ],
      onChoiceSelected: (id, choice) => onSelected(id == 'yes'),
      enableHapticFeedback: enableHapticFeedback,
    );
  }
  
  /// Create a widget for continue/cancel options
  static StoryChoiceWidget continueCancelChoice({
    required Function(bool) onSelected,
    String continueText = 'Continue',
    String cancelText = 'Cancel',
    String? continueDescription,
    String? cancelDescription,
    bool enableHapticFeedback = true,
  }) {
    return StoryChoiceWidget(
      choices: [
        {
          'id': 'continue',
          'text': continueText,
          'description': continueDescription,
          'icon': Icons.arrow_forward,
          'consequence_type': 'positive',
        },
        {
          'id': 'cancel',
          'text': cancelText,
          'description': cancelDescription,
          'icon': Icons.close,
          'consequence_type': 'negative',
        },
      ],
      style: continueDescription != null || cancelDescription != null 
          ? StoryChoiceStyle.descriptive 
          : StoryChoiceStyle.standard,
      onChoiceSelected: (id, choice) => onSelected(id == 'continue'),
      enableHapticFeedback: enableHapticFeedback,
    );
  }
  
  /// Create a widget for a list of cultural choices
  static StoryChoiceWidget culturalChoices({
    required List<Map<String, dynamic>> culturalOptions,
    required Function(String) onSelected,
    StoryChoiceStyle style = StoryChoiceStyle.descriptive,
    bool enableHapticFeedback = true,
  }) {
    // Transform cultural options into the expected choice format
    final choices = culturalOptions.map((option) {
      return {
        'id': option['id'],
        'text': option['title'],
        'description': option['description'],
        'icon': Icons.info_outline,
        'type': 'cultural',
      };
    }).toList();
    
    return StoryChoiceWidget(
      choices: choices,
      onChoiceSelected: (id, choice) => onSelected(id),
      style: style,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
  
  /// Create a widget for coding challenge choices
  static StoryChoiceWidget challengeChoices({
    required List<Map<String, dynamic>> challenges,
    required Function(String) onSelected,
    List<String>? completedChallenges,
    StoryChoiceStyle style = StoryChoiceStyle.descriptive,
    bool enableHapticFeedback = true,
  }) {
    // Transform challenges into the expected choice format
    final choices = challenges.map((challenge) {
      final challengeId = challenge['id'] as String;
      final isCompleted = completedChallenges?.contains(challengeId) ?? false;
      
      return {
        'id': challengeId,
        'text': challenge['title'],
        'description': challenge['description'],
        'icon': isCompleted ? Icons.check_circle : Icons.extension,
        'type': 'challenge',
        'consequence_type': isCompleted ? 'positive' : null,
      };
    }).toList();
    
    return StoryChoiceWidget(
      choices: choices,
      onChoiceSelected: (id, choice) => onSelected(id),
      style: style,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
}
