import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pattern_difficulty.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  UserModel? get user => _user;
  bool get isInitialized => _isInitialized;

  // Getters that delegate to user model
  String get username => _user?.username ?? 'Guest';
  int get level => _user?.level ?? 1;
  int get xp => _user?.xp ?? 0;
  int get completedPatterns => _user?.completedPatterns ?? 0;
  int get completedChallenges => _user?.completedChallenges ?? 0;
  bool get isPremium => _user?.isPremium ?? false;
  Set<String> get unlockedAchievements => _user?.achievements ?? {};
  Set<String> get viewedPatterns => _user?.viewedPatterns ?? {};
  DateTime get lastActiveDate => _user?.lastActiveDate ?? DateTime.now();
  int get currentStreak => _user?.currentStreak ?? 0;
  Map<String, int> get difficultyStats => _user?.difficultyStats ?? {};
  
  // New getters for story progress
  Set<String> get masteredConcepts => _user?.masteredConcepts ?? {};
  List<String> get completedStories => _user?.completedStories ?? [];
  List<String> get inProgressStories => _user?.inProgressStories ?? [];

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadUser();
    
    if (_user == null) {
      // Create new user if none exists
      _user = UserModel(
        id: const Uuid().v4(),
        name: 'Guest',
        lastActiveDate: DateTime.now(),
      );
      await _saveUser();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final userId = _prefs?.getString('userId');
    if (userId != null) {
      final lastActiveDate = _prefs?.getString('lastActiveDate') != null
          ? DateTime.parse(_prefs!.getString('lastActiveDate')!)
          : DateTime.now();

      final difficultyStatsStr = _prefs?.getString('difficultyStats');
      Map<String, int> difficultyStats = {};
      if (difficultyStatsStr != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(difficultyStatsStr);
          difficultyStats = decoded.map((key, value) => MapEntry(key, value as int));
        } catch (e) {
          print('Error decoding difficultyStats: $e');
        }
      }
      
      // Load story progress
      final storyProgressStr = _prefs?.getString('storyProgress');
      Map<String, dynamic> storyProgress = {};
      if (storyProgressStr != null) {
        try {
          storyProgress = json.decode(storyProgressStr);
        } catch (e) {
          print('Error decoding storyProgress: $e');
        }
      }
      
      // Load mastered concepts
      final masteredConceptsList = _prefs?.getStringList('masteredConcepts') ?? [];
      
      // Load choice history
      final choiceHistoryStr = _prefs?.getString('choiceHistory');
      List<UserChoice> choiceHistory = [];
      if (choiceHistoryStr != null) {
        try {
          final List<dynamic> decoded = json.decode(choiceHistoryStr);
          choiceHistory = decoded
              .map((item) => UserChoice.fromJson(item))
              .toList();
        } catch (e) {
          print('Error decoding choiceHistory: $e');
        }
      }

      _user = UserModel(
        id: userId,
        name: _prefs?.getString('userName') ?? 'Guest',
        level: _prefs?.getInt('userLevel') ?? 1,
        experience: _prefs?.getInt('userExperience') ?? 0,
        completedPatterns: _prefs?.getInt('completedPatterns') ?? 0,
        completedChallenges: _prefs?.getInt('completedChallenges') ?? 0,
        achievements: _prefs?.getStringList('achievements')?.toSet() ?? {},
        unlockedPatterns: _prefs?.getStringList('unlockedPatterns')?.toSet() ?? {},
        viewedPatterns: _prefs?.getStringList('viewedPatterns')?.toSet() ?? {},
        isPremium: _prefs?.getBool('isPremium') ?? false,
        lastActiveDate: lastActiveDate,
        currentStreak: _prefs?.getInt('currentStreak') ?? 0,
        difficultyStats: difficultyStats,
        masteredConcepts: masteredConceptsList.toSet(),
        storyProgress: storyProgress,
        choiceHistory: choiceHistory,
      );
      notifyListeners();
    }
  }

  Future<void> _saveUser() async {
    if (_user == null || _prefs == null) return;

    final now = DateTime.now();
    await _prefs!.setString('userId', _user!.id);
    await _prefs!.setString('userName', _user!.name);
    await _prefs!.setInt('userLevel', _user!.level);
    await _prefs!.setInt('userExperience', _user!.experience);
    await _prefs!.setInt('completedPatterns', _user!.completedPatterns);
    await _prefs!.setInt('completedChallenges', _user!.completedChallenges);
    await _prefs!.setStringList('achievements', _user!.achievements.toList());
    await _prefs!.setStringList('unlockedPatterns', _user!.unlockedPatterns.toList());
    await _prefs!.setStringList('viewedPatterns', _user!.viewedPatterns.toList());
    await _prefs!.setBool('isPremium', _user!.isPremium);
    await _prefs!.setString('lastActiveDate', now.toIso8601String());
    await _prefs!.setInt('currentStreak', _user!.currentStreak);
    await _prefs!.setString('difficultyStats', json.encode(_user!.difficultyStats));
    
    // Save new story tracking data
    await _prefs!.setStringList('masteredConcepts', _user!.masteredConcepts.toList());
    await _prefs!.setString('storyProgress', json.encode(_user!.storyProgress));
    await _prefs!.setString('choiceHistory', 
        json.encode(_user!.choiceHistory.map((c) => c.toJson()).toList()));

    // Update the user model with the new lastActiveDate
    _user = _user!.copyWith(lastActiveDate: now);
  }

  void setUsername(String newName) {
    if (_user != null) {
      _user = _user!.copyWith(name: newName);
      _saveUser();
      notifyListeners();
    }
  }

  void incrementXP(int amount) {
    if (_user != null) {
      _user = _user!.copyWith(
        experience: _user!.experience + amount,
      );
      _checkLevelUp();
      _saveUser();
      notifyListeners();
    }
  }

  void incrementChallenges() {
    if (_user != null) {
      _user = _user!.copyWith(
        completedChallenges: _user!.completedChallenges + 1,
        experience: _user!.experience + 25,
      );
      _checkLevelUp();
      _saveUser();
      notifyListeners();
    }
  }

  void incrementPatterns() {
    if (_user != null) {
      _user = _user!.copyWith(
        completedPatterns: _user!.completedPatterns + 1,
        experience: _user!.experience + 10,
      );
      _checkLevelUp();
      _saveUser();
      notifyListeners();
    }
  }

  void unlockAchievement(String achievement) {
    if (_user != null && !_user!.achievements.contains(achievement)) {
      _user = _user!.copyWith(
        achievements: {..._user!.achievements, achievement},
        experience: _user!.experience + 50,
      );
      _checkLevelUp();
      _saveUser();
      notifyListeners();
    }
  }

  bool hasAchievement(String achievement) {
    return _user?.achievements.contains(achievement) ?? false;
  }

  bool hasCompletedChallenge(String challengeId) {
    return _user?.achievements.contains('challenge_$challengeId') ?? false;
  }

  bool hasCreatedPattern(String patternType) {
    return _user?.unlockedPatterns.contains(patternType) ?? false;
  }
  
  bool hasConceptMastered(String conceptId) {
    return _user?.achievements.contains('concept_mastered_$conceptId') ?? false;
  }

  void recordPatternCreated(String patternType, PatternDifficulty difficulty) {
    if (_user != null) {
      final xpGain = _calculateXP(difficulty);
      _user = _user!.copyWith(
        experience: _user!.experience + xpGain,
        unlockedPatterns: {..._user!.unlockedPatterns, patternType},
      );
      _checkLevelUp();
      _saveUser();
      notifyListeners();
    }
  }

  int _calculateXP(PatternDifficulty difficulty) {
    switch (difficulty) {
      case PatternDifficulty.basic:
        return 10;
      case PatternDifficulty.intermediate:
        return 25;
      case PatternDifficulty.advanced:
        return 50;
      case PatternDifficulty.master:
        return 100;
    }
  }

  void _checkLevelUp() {
    if (_user == null) return;

    final currentLevel = _user!.level;
    final newLevel = (_user!.experience / 100).floor() + 1;

    if (newLevel > currentLevel) {
      _user = _user!.copyWith(level: newLevel);
      // TODO: Trigger level up celebration
    }
  }
  
  // Record mastered concepts
  Future<void> recordConceptMastery(List<String> concepts) async {
    if (_user == null) return;
    
    // Update mastered concepts in user model
    _user = _user!.copyWith(
      masteredConcepts: {..._user!.masteredConcepts, ...concepts.toSet()},
      experience: _user!.experience + (concepts.length * 10), // XP for mastering concepts
    );
    
    // Check for level up
    _checkLevelUp();
    
    // Save user data
    await _saveUser();
    notifyListeners();
  }
  
  // Record story progress
  Future<void> recordStoryProgress({
    required String storyId,
    required double completionScore,
    required List<String> conceptsPracticed,
    required List<String> choicesMade,
  }) async {
    if (_user == null) return;
    
    // Create progress entry
    final progressEntry = {
      'completionScore': completionScore,
      'conceptsPracticed': conceptsPracticed,
      'choicesMade': choicesMade,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    // Update story progress
    final updatedProgress = Map<String, dynamic>.from(_user!.storyProgress);
    updatedProgress[storyId] = progressEntry;
    
    // Check if this is a newly completed story
    final wasCompleted = _user!.getStoryCompletionScore(storyId) >= 0.9;
    final isNowCompleted = completionScore >= 0.9;
    
    // Award XP for completion if newly completed
    int additionalXP = 0;
    if (!wasCompleted && isNowCompleted) {
      additionalXP = 50; // Base XP for completing a story
      
      // Increment completed challenges
      _user = _user!.copyWith(
        completedChallenges: _user!.completedChallenges + 1,
      );
    }
    
    // Update user model
    _user = _user!.copyWith(
      storyProgress: updatedProgress,
      experience: _user!.experience + additionalXP,
    );
    
    // Check for level up
    _checkLevelUp();
    
    // Save user data
    await _saveUser();
    notifyListeners();
  }
  
  // Record a user choice
  Future<void> recordUserChoice(UserChoice choice) async {
    if (_user == null) return;
    
    // Add to choice history
    final updatedChoices = List<UserChoice>.from(_user!.choiceHistory);
    updatedChoices.add(choice);
    
    // Keep only the most recent 100 choices to avoid excessive storage
    if (updatedChoices.length > 100) {
      updatedChoices.removeAt(0);
    }
    
    // Update user model
    _user = _user!.copyWith(
      choiceHistory: updatedChoices,
    );
    
    // Save user data
    await _saveUser();
    notifyListeners();
  }
  
  // Get story completion percentage
  double getStoryCompletionPercentage(String storyId) {
    return _user?.getStoryCompletionScore(storyId) ?? 0.0;
  }
  
  // Check if user has mastered a concept
  bool hasConceptMastery(String concept) {
    return _user?.masteredConcepts.contains(concept) ?? false;
  }
  
  // Get all choices for a specific story
  List<UserChoice> getChoicesForStory(String storyId) {
    if (_user == null) return [];
    
    return _user!.choiceHistory.where((choice) => 
      choice.nodeId.startsWith(storyId)
    ).toList();
  }

  void updateLastActive() {
    if (_user != null) {
      final now = DateTime.now();
      final difference = now.difference(_user!.lastActiveDate).inDays;
      
      if (difference == 1) {
        // Increment streak for consecutive days
        _user = _user!.copyWith(
          currentStreak: _user!.currentStreak + 1,
          lastActiveDate: now,
        );
      } else if (difference > 1) {
        // Reset streak if more than a day has passed
        _user = _user!.copyWith(
          currentStreak: 1,
          lastActiveDate: now,
        );
      }
      
      _saveUser();
      notifyListeners();
    }
  }
}
