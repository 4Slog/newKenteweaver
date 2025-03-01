enum PatternDifficulty {
  basic,
  intermediate,
  advanced,
  master;

  String get displayName {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Basic';
      case PatternDifficulty.intermediate:
        return 'Intermediate';
      case PatternDifficulty.advanced:
        return 'Advanced';
      case PatternDifficulty.master:
        return 'Master';
    }
  }

  String get description {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Learn the fundamentals of pattern creation';
      case PatternDifficulty.intermediate:
        return 'Explore more complex patterns and combinations';
      case PatternDifficulty.advanced:
        return 'Master advanced techniques and cultural meanings';
      case PatternDifficulty.master:
        return 'Create your own innovative patterns';
    }
  }

  int get requiredScore {
    switch (this) {
      case PatternDifficulty.basic:
        return 0;
      case PatternDifficulty.intermediate:
        return 70;
      case PatternDifficulty.advanced:
        return 80;
      case PatternDifficulty.master:
        return 90;
    }
  }
}
