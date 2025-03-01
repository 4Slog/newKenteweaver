import 'pattern_difficulty.dart';

class ProgressModel {
  final String userId;
  PatternDifficulty currentLevel;
  List<String> completedLessons;
  Map<String, int> skillLevels;
  List<String> achievements;

  ProgressModel({
    required this.userId,
    required this.currentLevel,
    required this.completedLessons,
    required this.skillLevels,
    required this.achievements,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      userId: json['userId'] as String,
      currentLevel: PatternDifficulty.values.firstWhere(
        (d) => d.toString() == 'PatternDifficulty.${json['currentLevel']}',
      ),
      completedLessons: List<String>.from(json['completedLessons'] as List),
      skillLevels: Map<String, int>.from(json['skillLevels'] as Map),
      achievements: List<String>.from(json['achievements'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentLevel': currentLevel.toString().split('.').last,
      'completedLessons': completedLessons,
      'skillLevels': skillLevels,
      'achievements': achievements,
    };
  }
}
