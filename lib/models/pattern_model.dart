enum PatternDifficulty {
  basic,
  intermediate,
  advanced,
  expert,
}

class Pattern {
  final String id;
  final String name;
  final String description;
  final PatternDifficulty difficulty;
  final Map<String, dynamic> metadata;

  Pattern({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.metadata = const {},
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: PatternDifficulty.values.firstWhere(
        (d) => d.toString() == 'PatternDifficulty.${json['difficulty']}',
        orElse: () => PatternDifficulty.basic,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'metadata': metadata,
    };
  }
} 