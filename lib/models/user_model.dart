class UserModel {
  final String id;
  final String name;
  final int level;
  final int experience;
  final int completedPatterns;
  final int completedChallenges;
  final Set<String> achievements;
  final Set<String> unlockedPatterns;
  final Set<String> viewedPatterns;
  final bool isPremium;
  final DateTime lastActiveDate;
  final int currentStreak;
  final Map<String, int> difficultyStats;

  UserModel({
    required this.id,
    required this.name,
    this.level = 1,
    this.experience = 0,
    this.completedPatterns = 0,
    this.completedChallenges = 0,
    Set<String>? achievements,
    Set<String>? unlockedPatterns,
    Set<String>? viewedPatterns,
    this.isPremium = false,
    required this.lastActiveDate,
    this.currentStreak = 0,
    Map<String, int>? difficultyStats,
  })  : achievements = achievements ?? {},
        unlockedPatterns = unlockedPatterns ?? {},
        viewedPatterns = viewedPatterns ?? {},
        difficultyStats = difficultyStats ?? {};

  int get xp => experience;
  String get username => name;

  UserModel copyWith({
    String? id,
    String? name,
    int? level,
    int? experience,
    int? completedPatterns,
    int? completedChallenges,
    Set<String>? achievements,
    Set<String>? unlockedPatterns,
    Set<String>? viewedPatterns,
    bool? isPremium,
    DateTime? lastActiveDate,
    int? currentStreak,
    Map<String, int>? difficultyStats,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      completedPatterns: completedPatterns ?? this.completedPatterns,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      achievements: achievements ?? this.achievements,
      unlockedPatterns: unlockedPatterns ?? this.unlockedPatterns,
      viewedPatterns: viewedPatterns ?? this.viewedPatterns,
      isPremium: isPremium ?? this.isPremium,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      difficultyStats: difficultyStats ?? this.difficultyStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'experience': experience,
      'completedPatterns': completedPatterns,
      'completedChallenges': completedChallenges,
      'achievements': achievements.toList(),
      'unlockedPatterns': unlockedPatterns.toList(),
      'viewedPatterns': viewedPatterns.toList(),
      'isPremium': isPremium,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'currentStreak': currentStreak,
      'difficultyStats': difficultyStats,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      experience: json['experience'] as int,
      completedPatterns: json['completedPatterns'] as int,
      completedChallenges: json['completedChallenges'] as int,
      achievements: Set<String>.from(json['achievements'] as List),
      unlockedPatterns: Set<String>.from(json['unlockedPatterns'] as List),
      viewedPatterns: Set<String>.from(json['viewedPatterns'] as List),
      isPremium: json['isPremium'] as bool,
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      currentStreak: json['currentStreak'] as int,
      difficultyStats: Map<String, int>.from(json['difficultyStats'] as Map),
    );
  }
}
