/// Represents the different states of the tutorial
enum TutorialState {
  initial,
  introduction,
  workspaceReveal,
  blockDragging,
  patternSelection,
  colorSelection,
  loopUsage,
  rowColumns,
  culturalContext,
  challenge,
  complete,
  next;

  String get displayName {
    switch (this) {
      case TutorialState.initial:
        return 'Getting Started';
      case TutorialState.introduction:
        return 'Introduction';
      case TutorialState.workspaceReveal:
        return 'Workspace';
      case TutorialState.blockDragging:
        return 'Block Dragging';
      case TutorialState.patternSelection:
        return 'Pattern Selection';
      case TutorialState.colorSelection:
        return 'Color Selection';
      case TutorialState.loopUsage:
        return 'Loop Usage';
      case TutorialState.rowColumns:
        return 'Rows and Columns';
      case TutorialState.culturalContext:
        return 'Cultural Context';
      case TutorialState.challenge:
        return 'Challenge';
      case TutorialState.complete:
        return 'Complete';
      case TutorialState.next:
        return 'Next';
    }
  }
} 
