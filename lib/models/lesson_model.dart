import 'lesson_type.dart';
import 'pattern_difficulty.dart';

class LessonModel {
  final String id;
  final String title;
  final String description;
  final LessonType type;
  final PatternDifficulty difficulty;
  final List<String> prerequisites;
  final Map<String, dynamic> content;
  final int sequence;
  final Map<String, dynamic> requirements;
  final List<String> skills;

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    this.prerequisites = const [],
    required this.content,
    this.sequence = 0,
    this.requirements = const {},
    this.skills = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: LessonType.values.firstWhere(
        (e) => e.toString() == 'LessonType.${json['type']}',
      ),
      difficulty: PatternDifficulty.values.firstWhere(
        (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
      ),
      prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
      content: json['content'] as Map<String, dynamic>,
      sequence: json['sequence'] as int? ?? 0,
      requirements: json['requirements'] as Map<String, dynamic>? ?? {},
      skills: List<String>.from(json['skills'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'prerequisites': prerequisites,
      'content': content,
      'sequence': sequence,
      'requirements': requirements,
      'skills': skills,
    };
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    LessonType? type,
    PatternDifficulty? difficulty,
    List<String>? prerequisites,
    Map<String, dynamic>? content,
    int? sequence,
    Map<String, dynamic>? requirements,
    List<String>? skills,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      prerequisites: prerequisites ?? this.prerequisites,
      content: content ?? this.content,
      sequence: sequence ?? this.sequence,
      requirements: requirements ?? this.requirements,
      skills: skills ?? this.skills,
    );
  }
}
