import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kente_codeweaver/services/tutorial_service.dart';
import 'package:kente_codeweaver/services/ai_service.dart';
import 'package:kente_codeweaver/providers/user_provider.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';

// Create mock classes
class MockSharedPreferences extends Mock implements SharedPreferences {
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  
  @override
  Future<bool> remove(String key) async => true;
}

class MockAIService extends Mock implements AIService {
  @override
  Future<String> generateCulturalExplanation({
    required String patternType,
    required List<String> colors,
    bool useCache = true,
  }) async => 'color_blocks';
}

class MockUserProvider extends Mock implements UserProvider {
  @override
  int get level => 1;
  
  @override
  int get xp => 50;
  
  @override
  int get completedPatterns => 5;
  
  @override
  int get completedChallenges => 2;
  
  @override
  Map<String, int> get difficultyStats => {
    'basic': 3,
    'intermediate': 2,
    'advanced': 0,
    'master': 0,
  };
}

void main() {
  late TutorialService tutorialService;
  late MockSharedPreferences mockPrefs;
  late MockAIService mockAIService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockAIService = MockAIService();
    mockUserProvider = MockUserProvider();
    
    // Setup default behavior for mocks
    when(mockPrefs.getStringList('tutorial_lesson_progress')).thenReturn(null);
    when(mockPrefs.getStringList('tutorial_challenge_progress')).thenReturn(null);
    when(mockPrefs.getStringList('tutorial_hints_seen')).thenReturn(null);
    
    tutorialService = TutorialService(mockPrefs, mockAIService);
  });

  group('TutorialService Tests', () {
    test('Lesson completion tracking', () async {
      // Arrange
      const lessonId = 'basic_blocks';
      when(mockPrefs.getStringList('tutorial_lesson_progress')).thenReturn(null);

      // Act
      await tutorialService.markLessonCompleted(lessonId);

      // Assert
      verify(mockPrefs.setStringList('tutorial_lesson_progress', [lessonId])).called(1);
      expect(tutorialService.isLessonCompleted(lessonId), true);
    });

    test('Available lessons based on prerequisites', () {
      // Arrange
      when(mockPrefs.getStringList('tutorial_lesson_progress'))
          .thenReturn(['basic_blocks']);

      // Act
      final availableLessons = tutorialService.getAvailableLessons();

      // Assert
      expect(availableLessons, contains('color_blocks'));
      expect(availableLessons, isNot(contains('advanced_patterns')));
    });

    test('Challenge completion tracking', () async {
      // Arrange
      const challengeId = 'checker_basic';
      when(mockPrefs.getStringList('tutorial_challenge_progress')).thenReturn(null);

      // Act
      await tutorialService.markChallengeCompleted(challengeId);

      // Assert
      verify(mockPrefs.setStringList('tutorial_challenge_progress', [challengeId])).called(1);
      expect(tutorialService.isChallengeCompleted(challengeId), true);
    });

    test('Hint system', () {
      // Arrange
      const lessonId = 'basic_blocks';
      final currentState = {
        'blockCount': 0,
        'hasPattern': false,
        'colors': <String>[],
      };

      // Act
      final hint = tutorialService.getContextualHint(
        lessonId: lessonId,
        currentState: currentState,
        difficulty: PatternDifficulty.basic,
      );

      // Assert
      expect(hint, contains('Start by dragging blocks'));
    });

    test('Next suggested lesson', () async {
      // Arrange
      when(mockPrefs.getStringList('tutorial_lesson_progress'))
          .thenReturn(['basic_blocks']);

      // Act
      final nextLesson = await tutorialService.getNextSuggestedLesson(
        userProvider: mockUserProvider,
      );

      // Assert
      expect(nextLesson, isNotNull);
      expect(nextLesson, equals('color_blocks'));
    });

    test('Progress reset', () async {
      // Arrange
      when(mockPrefs.getStringList('tutorial_lesson_progress'))
          .thenReturn(['basic_blocks']);
      when(mockPrefs.getStringList('tutorial_challenge_progress'))
          .thenReturn(['checker_basic']);
      when(mockPrefs.getStringList('tutorial_hints_seen'))
          .thenReturn(['hint1']);

      // Act
      await tutorialService.resetProgress();

      // Assert
      verify(mockPrefs.remove('tutorial_lesson_progress')).called(1);
      verify(mockPrefs.remove('tutorial_challenge_progress')).called(1);
      verify(mockPrefs.remove('tutorial_hints_seen')).called(1);
      expect(tutorialService.isLessonCompleted('basic_blocks'), false);
    });
  });
}
