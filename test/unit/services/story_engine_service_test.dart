import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:kente_codeweaver/services/story_engine_service.dart';
import 'package:kente_codeweaver/services/device_profile_service.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';

@GenerateMocks([DeviceProfileService, StorageService])
void main() {
  late StoryEngineService storyEngine;
  late MockDeviceProfileService mockDeviceProfile;
  late MockStorageService mockStorage;

  setUp(() {
    mockDeviceProfile = MockDeviceProfileService();
    mockStorage = MockStorageService();
    storyEngine = StoryEngineService();
    storyEngine.initialize(
      deviceProfileService: mockDeviceProfile,
      storageService: mockStorage,
    );
  });

  group('Story Generation', () {
    test('generates introduction story successfully', () async {
      final story = await storyEngine.generateStory(
        storyId: 'intro_tutorial',
        difficulty: PatternDifficulty.basic,
        targetConcepts: ['app_introduction', 'basic_blocks'],
        language: 'en',
      );

      expect(story, isNotNull);
      expect(story.id, equals('intro_tutorial'));
      expect(story.difficulty, equals(PatternDifficulty.basic));
      expect(story.learningConcepts, contains('app_introduction'));
      expect(story.startNode, isNotNull);
      expect(story.nodes, isNotEmpty);
    });

    test('handles story generation failure gracefully', () async {
      // Simulate API failure
      when(mockStorage.read(any)).thenThrow(Exception('API Error'));

      final story = await storyEngine.generateStory(
        storyId: 'test_story',
        difficulty: PatternDifficulty.basic,
        targetConcepts: ['loops'],
        language: 'en',
      );

      // Should return fallback story
      expect(story, isNotNull);
      expect(story.id, equals('test_story'));
      expect(story.nodes, isNotEmpty);
    });
  });

  group('Story Node Management', () {
    test('retrieves story node successfully', () async {
      final nodeId = 'test_node';
      final node = await storyEngine.getNode(nodeId);

      expect(node, isNotNull);
      expect(node.id, equals(nodeId));
      expect(node.content, isNotEmpty);
      expect(node.choices, isNotNull);
    });

    test('handles missing node gracefully', () async {
      final nodeId = 'non_existent_node';
      final node = await storyEngine.getNode(nodeId);

      expect(node, isNotNull);
      expect(node.content, contains('Welcome'));
      expect(node.choices, isNotEmpty);
    });
  });

  group('Story Persistence', () {
    test('saves current story successfully', () async {
      final storyId = 'test_story';
      final story = await storyEngine.generateStory(
        storyId: storyId,
        difficulty: PatternDifficulty.basic,
        targetConcepts: ['loops'],
        language: 'en',
      );

      await storyEngine.setCurrentStory(storyId);
      
      expect(storyEngine.currentStory, equals(story));
      verify(mockStorage.write(any, any)).called(1);
    });

    test('loads story from storage', () async {
      final storyId = 'saved_story';
      when(mockStorage.read('story_$storyId')).thenAnswer((_) async => 
        '{"id":"saved_story","title":"Test","description":"Test Story","difficulty":"basic","nodes":{}}'
      );

      final story = await storyEngine.getStory(storyId);
      
      expect(story, isNotNull);
      expect(story?.id, equals(storyId));
    });
  });

  group('Story State Management', () {
    test('resets state correctly', () async {
      // Set up initial state
      await storyEngine.generateStory(
        storyId: 'test_story',
        difficulty: PatternDifficulty.basic,
        targetConcepts: ['loops'],
        language: 'en',
      );

      storyEngine.reset();
      
      expect(storyEngine.currentStory, isNull);
      expect(storyEngine.currentNode, isNull);
    });
  });
} 