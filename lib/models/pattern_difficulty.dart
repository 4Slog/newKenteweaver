/// Represents the difficulty level of a pattern
enum PatternDifficulty {
  basic,
  intermediate,
  advanced,
  expert;

  /// Creates a PatternDifficulty from JSON data
  factory PatternDifficulty.fromJson(Map<String, dynamic> json) {
    final String value = json['value'] as String;
    return PatternDifficulty.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => PatternDifficulty.basic,
    );
  }

  /// Converts the PatternDifficulty to JSON
  Map<String, dynamic> toJson() {
    return {
      'value': toString().split('.').last,
    };
  }

  String get displayName {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Basic';
      case PatternDifficulty.intermediate:
        return 'Intermediate';
      case PatternDifficulty.advanced:
        return 'Advanced';
      case PatternDifficulty.expert:
        return 'Expert';
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
      case PatternDifficulty.expert:
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
      case PatternDifficulty.expert:
        return 90;
    }
  }
}
