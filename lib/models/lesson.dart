import 'lesson_type.dart';
import 'pattern_difficulty.dart';

class Lesson {
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

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.prerequisites,
    required this.content,
    this.sequence = 0,
    this.requirements = const {},
    this.skills = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: LessonType.values.firstWhere(
        (e) => e.toString() == 'LessonType.${json['type']}',
      ),
      difficulty: PatternDifficulty.values.firstWhere(
        (e) => e.toString() == 'PatternDifficulty.${json['difficulty']}',
      ),
      prerequisites: List<String>.from(json['prerequisites'] as List),
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
}
