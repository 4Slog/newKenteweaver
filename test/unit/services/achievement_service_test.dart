import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:kente_codeweaver/services/achievement_service.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/services/audio_service.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/models/audio_model.dart' as audio;
import 'package:flutter/material.dart';
import 'achievement_service_test.mocks.dart';

@GenerateMocks([StorageService, AudioService])
void main() {
  late AchievementService achievementService;
  late MockStorageService mockStorage;
  late MockAudioService mockAudio;
  late GlobalKey<NavigatorState> mockNavigatorKey;
  const testUserId = 'test_user';

  setUp(() {
    mockStorage = MockStorageService();
    mockAudio = MockAudioService();
    mockNavigatorKey = GlobalKey<NavigatorState>();
    achievementService = AchievementService(
      mockStorage,
      mockAudio,
      mockNavigatorKey,
    );
  });

  group('Achievement Management', () {
    test('gets achievement list', () {
      final achievements = achievementService.getAllAchievements();
      expect(achievements, isNotEmpty);
      expect(achievements.first.id, equals('pattern_first'));
    });

    test('gets achievement by id', () {
      final achievement = achievementService.getAchievement('pattern_first');
      expect(achievement, isNotNull);
      expect(achievement?.title, equals('First Pattern'));
    });

    test('checks if user has achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '["pattern_first"]');

      final hasAchievement = await achievementService.hasAchievement(
        testUserId,
        'pattern_first',
      );
      expect(hasAchievement, isTrue);
    });
  });

  group('Achievement Progress', () {
    test('gets achievement progress', () async {
      when(mockStorage.read('achievement_progress_$testUserId'))
          .thenAnswer((_) async => '{"patterns_created": 7.0, "challenges_completed": 3.0}');

      final progress = await achievementService.getProgress(testUserId);
      expect(progress, isNotNull);
      expect(progress['patterns_created'], equals(7.0));
      expect(progress['challenges_completed'], equals(3.0));
    });

    test('updates achievement progress', () async {
      when(mockStorage.read('achievement_progress_$testUserId'))
          .thenAnswer((_) async => '{"patterns_created": 4.0}');
      when(mockStorage.write('achievement_progress_$testUserId', '{"patterns_created": 5.0}'))
          .thenAnswer((_) async => true);

      await achievementService.updateProgress(
        testUserId,
        'patterns_created',
        5.0,
      );

      verify(mockStorage.write(
        'achievement_progress_$testUserId',
        '{"patterns_created": 5.0}',
      )).called(1);
    });
  });

  group('Achievement Awards', () {
    test('awards new achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '[]');
      when(mockStorage.write('user_achievements_$testUserId', '["pattern_first"]'))
          .thenAnswer((_) async => true);
      when(mockAudio.soundEnabled).thenReturn(true);

      await achievementService.awardAchievement(testUserId, 'pattern_first');

      verify(mockStorage.write(
        'user_achievements_$testUserId',
        '["pattern_first"]',
      )).called(1);
      verify(mockAudio.playSoundEffect(audio.AudioType.achievement)).called(1);
    });

    test('prevents duplicate awards', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '["pattern_first"]');

      await achievementService.awardAchievement(testUserId, 'pattern_first');

      verifyNever(mockStorage.write('user_achievements_$testUserId', '["pattern_first"]'));
      verifyNever(mockAudio.playSoundEffect(audio.AudioType.achievement));
    });
  });

  group('Pattern Achievements', () {
    test('awards first pattern achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '[]');
      when(mockStorage.write('user_achievements_$testUserId', '["pattern_first"]'))
          .thenAnswer((_) async => true);
      when(mockAudio.soundEnabled).thenReturn(true);

      await achievementService.checkPatternAchievements(
        testUserId,
        1,
        ['basic_stripe'],
      );

      verify(mockStorage.write(
        'user_achievements_$testUserId',
        '["pattern_first"]',
      )).called(1);
    });

    test('awards pattern master achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '[]');
      when(mockStorage.write('user_achievements_$testUserId', '["pattern_master"]'))
          .thenAnswer((_) async => true);
      when(mockAudio.soundEnabled).thenReturn(true);

      await achievementService.checkPatternAchievements(
        testUserId,
        10,
        [
          'basic_stripe',
          'basic_zigzag',
          'basic_diamond',
          'basic_check',
        ],
      );

      verify(mockStorage.write(
        'user_achievements_$testUserId',
        '["pattern_master"]',
      )).called(1);
    });
  });

  group('Challenge Achievements', () {
    test('awards first challenge achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '[]');
      when(mockStorage.write('user_achievements_$testUserId', '["challenge_first"]'))
          .thenAnswer((_) async => true);
      when(mockAudio.soundEnabled).thenReturn(true);

      await achievementService.checkChallengeAchievements(
        testUserId,
        1,
        PatternDifficulty.basic,
      );

      verify(mockStorage.write(
        'user_achievements_$testUserId',
        '["challenge_first"]',
      )).called(1);
    });

    test('awards advanced challenge achievement', () async {
      when(mockStorage.read('user_achievements_$testUserId'))
          .thenAnswer((_) async => '[]');
      when(mockStorage.write('user_achievements_$testUserId', '["challenge_advanced"]'))
          .thenAnswer((_) async => true);
      when(mockAudio.soundEnabled).thenReturn(true);

      await achievementService.checkChallengeAchievements(
        testUserId,
        1,
        PatternDifficulty.advanced,
      );

      verify(mockStorage.write(
        'user_achievements_$testUserId',
        '["challenge_advanced"]',
      )).called(1);
    });
  });
} 