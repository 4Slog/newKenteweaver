import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pattern_difficulty.dart';
import '../../models/lesson_model.dart';
import '../../models/lesson_progress.dart';
import '../../models/progress_model.dart';
import 'unified_ai_service.dart';

class LearningSystem {
  static LearningSystem? _instance;
  late final SharedPreferences _prefs;
  late final UnifiedAIService _aiService;
  
  // Cache for frequently accessed data
  Map<String, LessonModel>? _lessonsCache;
  ProgressModel? _progressCache;
  
  LearningSystem._();

  static Future<LearningSystem> getInstance({
    required SharedPreferences prefs,
    required UnifiedAIService aiService,
  }) async {
    if (_instance == null) {
      _instance = LearningSystem._();
      _instance!._prefs = prefs;
      _instance!._aiService = aiService;
      await _instance!._loadInitialData();
    }
    return _instance!;
  }

  // Lesson Management
  Future<List<LessonModel>> getAvailableLessons({
    required String language,
    PatternDifficulty? difficulty,
  }) async {
    await _ensureLessonsLoaded();
    
    var lessons = _lessonsCache!.values.toList();
    
    if (difficulty != null) {
      lessons = lessons.where((l) => l.difficulty == difficulty).toList();
    }

    // Translate lesson content if needed
    if (language != 'en') {
      lessons = await Future.wait(
        lessons.map((lesson) => _translateLesson(lesson, language)),
      );
    }

    return lessons;
  }

  Future<LessonModel?> getNextLesson({
    required String userId,
    required String language,
  }) async {
    final progress = await getUserProgress(userId);
    final completedLessons = progress.completedLessons;
    
    await _ensureLessonsLoaded();
    
    // Find first incomplete lesson that meets prerequisites
    final availableLessons = _lessonsCache!.values.where((lesson) {
      if (completedLessons.contains(lesson.id)) return false;
      return _meetsPrerequisites(lesson, completedLessons);
    }).toList();

    if (availableLessons.isEmpty) return null;

    // Sort by difficulty and sequence
    availableLessons.sort((a, b) {
      final diffComp = a.difficulty.index.compareTo(b.difficulty.index);
      if (diffComp != 0) return diffComp;
      return a.sequence.compareTo(b.sequence);
    });

    final nextLesson = availableLessons.first;
    return language == 'en'
        ? nextLesson
        : await _translateLesson(nextLesson, language);
  }

  // Progress Tracking
  Future<ProgressModel> getUserProgress(String userId) async {
    if (_progressCache != null) return _progressCache!;

    final progressJson = _prefs.getString('user_progress_$userId');
    if (progressJson != null) {
      _progressCache = ProgressModel.fromJson(
        jsonDecode(progressJson) as Map<String, dynamic>,
      );
      return _progressCache!;
    }

    // Initialize new progress
    _progressCache = ProgressModel(
      userId: userId,
      currentLevel: PatternDifficulty.basic,
      completedLessons: [],
      skillLevels: {},
      achievements: [],
    );

    await _saveProgress(userId, _progressCache!);
    return _progressCache!;
  }

  Future<void> updateProgress({
    required String userId,
    required String lessonId,
    required Map<String, dynamic> results,
  }) async {
    final progress = await getUserProgress(userId);
    final lesson = _lessonsCache![lessonId];
    
    if (lesson == null) {
      throw Exception('Lesson not found: $lessonId');
    }

    // Update completed lessons
    if (!progress.completedLessons.contains(lessonId)) {
      progress.completedLessons.add(lessonId);
    }

    // Update skill levels
    for (final skill in lesson.skills) {
      final currentLevel = progress.skillLevels[skill] ?? 0;
      progress.skillLevels[skill] = currentLevel + 1;
    }

    // Check for level up
    if (_shouldLevelUp(progress)) {
      progress.currentLevel = PatternDifficulty.values[
        math.min(
          progress.currentLevel.index + 1,
          PatternDifficulty.values.length - 1,
        )
      ];
    }

    // Save progress
    await _saveProgress(userId, progress);
    _progressCache = progress;
  }

  // Tutorial System
  Future<Map<String, dynamic>> getTutorialContent({
    required String tutorialId,
    required String language,
    PatternDifficulty? difficulty,
  }) async {
    final baseContent = await _loadTutorialContent(tutorialId);
    
    if (language == 'en') return baseContent;

    // Translate tutorial content
    return {
      'steps': await Future.wait(
        (baseContent['steps'] as List).map((step) async {
          return {
            'title': await _aiService.translateContent(
              content: step['title'] as String,
              targetLanguage: language,
              isPremium: false,
            ),
            'content': await _aiService.translateContent(
              content: step['content'] as String,
              targetLanguage: language,
              isPremium: false,
            ),
            'hints': await Future.wait(
              (step['hints'] as List).map((hint) async {
                return _aiService.translateContent(
                  content: hint as String,
                  targetLanguage: language,
                  isPremium: false,
                );
              }),
            ),
          };
        }),
      ),
      'interactive_elements': baseContent['interactive_elements'],
    };
  }

  Future<void> markTutorialComplete({
    required String userId,
    required String tutorialId,
  }) async {
    final key = 'completed_tutorials_$userId';
    final completed = _prefs.getStringList(key) ?? [];
    
    if (!completed.contains(tutorialId)) {
      completed.add(tutorialId);
      await _prefs.setStringList(key, completed);
    }
  }

  Future<bool> isTutorialComplete({
    required String userId,
    required String tutorialId,
  }) async {
    final completed = _prefs.getStringList('completed_tutorials_$userId') ?? [];
    return completed.contains(tutorialId);
  }

  // Helper Methods
  Future<void> _loadInitialData() async {
    await _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessonsJson = await _loadLessonsJson();
      _lessonsCache = Map.fromEntries(
        (lessonsJson['lessons'] as List).map((lesson) {
          final model = LessonModel.fromJson(lesson as Map<String, dynamic>);
          return MapEntry(model.id, model);
        }),
      );
    } catch (e) {
      _lessonsCache = {};
      print('Error loading lessons: $e');
    }
  }

  Future<Map<String, dynamic>> _loadLessonsJson() async {
    // In a real app, this would load from assets or API
    return {
      'lessons': [
        // Basic lessons would be defined here
      ],
    };
  }

  Future<void> _ensureLessonsLoaded() async {
    if (_lessonsCache == null) {
      await _loadLessons();
    }
  }

  bool _meetsPrerequisites(
    LessonModel lesson,
    List<String> completedLessons,
  ) {
    final prerequisites = lesson.requirements['lessons_completed'] as List?;
    if (prerequisites == null || prerequisites.isEmpty) return true;
    
    return prerequisites.every(
      (prereq) => completedLessons.contains(prereq),
    );
  }

  bool _shouldLevelUp(ProgressModel progress) {
    final lessonsInCurrentLevel = _lessonsCache!.values.where(
      (l) => l.difficulty == progress.currentLevel,
    ).length;

    final completedInLevel = _lessonsCache!.values.where((l) {
      return l.difficulty == progress.currentLevel &&
          progress.completedLessons.contains(l.id);
    }).length;

    return completedInLevel >= lessonsInCurrentLevel * 0.8;
  }

  Future<void> _saveProgress(String userId, ProgressModel progress) async {
    await _prefs.setString(
      'user_progress_$userId',
      jsonEncode(progress.toJson()),
    );
  }

  Future<LessonModel> _translateLesson(
    LessonModel lesson,
    String language,
  ) async {
    return LessonModel(
      id: lesson.id,
      title: await _aiService.translateContent(
        content: lesson.title,
        targetLanguage: language,
        isPremium: false,
      ),
      description: await _aiService.translateContent(
        content: lesson.description,
        targetLanguage: language,
        isPremium: false,
      ),
      type: lesson.type,
      difficulty: lesson.difficulty,
      sequence: lesson.sequence,
      skills: lesson.skills,
      requirements: lesson.requirements,
      content: await _translateLessonContent(lesson.content, language),
    );
  }

  Future<Map<String, dynamic>> _translateLessonContent(
    Map<String, dynamic> content,
    String language,
  ) async {
    final translatedContent = Map<String, dynamic>.from(content);
    
    // Translate text content
    for (final key in ['introduction', 'conclusion']) {
      if (content[key] != null) {
        translatedContent[key] = await _aiService.translateContent(
          content: content[key] as String,
          targetLanguage: language,
          isPremium: false,
        );
      }
    }

    // Translate steps
    if (content['steps'] != null) {
      translatedContent['steps'] = await Future.wait(
        (content['steps'] as List).map((step) async {
          final translatedStep = Map<String, dynamic>.from(step as Map<String, dynamic>);
          translatedStep['title'] = await _aiService.translateContent(
            content: step['title'] as String,
            targetLanguage: language,
            isPremium: false,
          );
          translatedStep['description'] = await _aiService.translateContent(
            content: step['description'] as String,
            targetLanguage: language,
            isPremium: false,
          );
          return translatedStep;
        }),
      );
    }

    return translatedContent;
  }

  Future<Map<String, dynamic>> _loadTutorialContent(String tutorialId) async {
    // In a real app, this would load from assets or API
    return {
      'steps': [
        {
          'title': 'Welcome to Pattern Creation',
          'content': 'Learn how to create beautiful Kente patterns.',
          'hints': [
            'Start with basic shapes',
            'Experiment with colors',
          ],
        },
      ],
      'interactive_elements': {
        'animations': ['intro_animation'],
        'clickable_areas': ['pattern_grid', 'color_palette'],
      },
    };
  }
}
