import '../models/lesson.dart';
import '../models/lesson_type.dart';
import '../models/pattern_difficulty.dart';

class LessonService {
  Future<List<Lesson>> getAvailableLessons({
    required LessonType type,
    required PatternDifficulty difficulty,
  }) async {
    // Simulated delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock lessons
    return [
      Lesson(
        id: '1',
        title: 'Introduction to Patterns',
        description: 'Learn the basics of Kente patterns',
        type: type,
        difficulty: difficulty,
        prerequisites: [],
        content: {
          'steps': [
            'Understanding basic shapes',
            'Creating simple patterns',
            'Combining patterns',
          ],
        },
        skills: [
          'Pattern Recognition',
          'Basic Shapes',
          'Color Theory',
        ],
      ),
      Lesson(
        id: '2',
        title: 'Advanced Patterns',
        description: 'Create complex Kente patterns',
        type: type,
        difficulty: difficulty,
        prerequisites: ['Basic Patterns'],
        content: {
          'steps': [
            'Working with symmetry',
            'Color combinations',
            'Cultural meanings',
          ],
        },
        skills: [
          'Pattern Composition',
          'Symmetry',
          'Cultural Design',
          'Advanced Color Theory',
        ],
      ),
    ];
  }

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    // Simulated delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock progress data
    return {
      'completedLessons': ['1', '2'],
      'currentLevel': 'intermediate',
      'totalScore': 85,
    };
  }

  Future<String> getPersonalizedPath({
    required String userId,
    required PatternDifficulty currentLevel,
    required Map<String, dynamic> progress,
  }) async {
    // Simulated delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock path generation
    return 'path_${currentLevel.toString().split('.').last}_$userId';
  }
}
