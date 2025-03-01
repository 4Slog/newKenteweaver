enum LessonType {
  tutorial,
  pattern,
  story,
  challenge,
  assessment,
  project;

  String get displayName {
    switch (this) {
      case LessonType.tutorial:
        return 'Tutorial';
      case LessonType.pattern:
        return 'Pattern Creation';
      case LessonType.story:
        return 'Story';
      case LessonType.challenge:
        return 'Challenge';
      case LessonType.assessment:
        return 'Assessment';
      case LessonType.project:
        return 'Project';
    }
  }
}
