import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:kente_codeweaver/services/pattern_render_service.dart';
import 'package:kente_codeweaver/services/device_profile_service.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/models/pattern_difficulty.dart';
import 'package:flutter/material.dart';

@GenerateMocks([DeviceProfileService, StorageService])
void main() {
  late PatternRenderService renderService;
  late MockDeviceProfileService mockDeviceProfile;
  late MockStorageService mockStorage;

  setUp(() {
    mockDeviceProfile = MockDeviceProfileService();
    mockStorage = MockStorageService();
    renderService = PatternRenderService();
    renderService.initialize(
      deviceProfileService: mockDeviceProfile,
      storageService: mockStorage,
    );
  });

  group('Pattern Generation', () {
    test('generates basic pattern successfully', () async {
      final blocks = [
        {
          'type': 'repeat',
          'parameters': {
            'count': 4,
            'pattern': [1, 0, 1, 0],
          },
        },
      ];

      final pattern = await renderService.renderPattern(
        patternId: 'test_pattern',
        blocks: blocks,
        previewSize: const Size(100, 100),
      );

      expect(pattern, isNotNull);
      expect(pattern['grid'], isNotEmpty);
      expect(pattern['colors'], isNotEmpty);
      expect(pattern['size'], isNotNull);
    });

    test('handles empty block list gracefully', () async {
      final pattern = await renderService.renderPattern(
        patternId: 'empty_pattern',
        blocks: [],
        previewSize: const Size(100, 100),
      );

      expect(pattern, isNotNull);
      expect(pattern['grid'], isNotEmpty);
      expect(pattern['grid'], allOf(
        isList,
        hasLength(greaterThan(0)),
      ));
    });

    test('applies zigzag pattern correctly', () async {
      final blocks = [
        {
          'type': 'zigzag',
          'parameters': {
            'amplitude': 2,
            'period': 4,
          },
        },
      ];

      final pattern = await renderService.renderPattern(
        patternId: 'zigzag_pattern',
        blocks: blocks,
        previewSize: const Size(100, 100),
      );

      expect(pattern['grid'], isNotEmpty);
      // Verify zigzag pattern characteristics
      final grid = pattern['grid'] as List<List<int>>;
      bool foundPeak = false;
      bool foundValley = false;
      
      for (var row in grid) {
        if (row.contains(1)) {
          if (row.indexOf(1) < grid[0].length ~/ 2) foundPeak = true;
          if (row.indexOf(1) > grid[0].length ~/ 2) foundValley = true;
        }
      }
      
      expect(foundPeak && foundValley, isTrue);
    });
  });

  group('Pattern Caching', () {
    test('caches generated pattern', () async {
      final patternId = 'cache_test';
      final blocks = [
        {
          'type': 'repeat',
          'parameters': {
            'count': 2,
            'pattern': [1, 0],
          },
        },
      ];

      // Generate pattern first time
      final pattern1 = await renderService.renderPattern(
        patternId: patternId,
        blocks: blocks,
        previewSize: const Size(100, 100),
      );

      // Get pattern from cache
      final pattern2 = await renderService.getPattern(patternId);

      expect(pattern2, isNotNull);
      expect(pattern2, equals(pattern1));
    });

    test('clears cache successfully', () async {
      final patternId = 'clear_test';
      final blocks = [
        {
          'type': 'repeat',
          'parameters': {
            'count': 2,
            'pattern': [1, 0],
          },
        },
      ];

      await renderService.renderPattern(
        patternId: patternId,
        blocks: blocks,
        previewSize: const Size(100, 100),
      );

      renderService.clearCache();
      final pattern = await renderService.getPattern(patternId);
      expect(pattern, isNull);
    });
  });

  group('Pattern Information', () {
    test('retrieves pattern info correctly', () {
      final info = renderService.getPatternInfo('adinkra_gye_nyame');
      
      expect(info, isNotNull);
      expect(info?['name'], equals('Gye Nyame'));
      expect(info?['difficulty'], equals('basic'));
      expect(info?['conceptTaught'], equals('sequential_execution'));
    });

    test('returns available patterns', () {
      final patterns = renderService.getAvailablePatterns();
      
      expect(patterns, isNotNull);
      expect(patterns, isNotEmpty);
      expect(patterns, contains('adinkra_gye_nyame'));
    });
  });

  group('Pattern Unlocking', () {
    test('checks pattern unlock status', () {
      when(mockDeviceProfile.currentProfile).thenReturn(null);
      
      final isUnlocked = renderService.isPatternUnlocked('test_pattern');
      expect(isUnlocked, isFalse);
    });

    test('saves pattern successfully', () async {
      final patternId = 'save_test';
      final pattern = {
        'grid': [[1, 0], [0, 1]],
        'colors': ['#000000', '#FFFFFF'],
      };

      when(mockStorage.write(any, any)).thenAnswer((_) async => true);
      when(mockDeviceProfile.currentProfile).thenReturn(null);

      await renderService.savePattern(patternId, pattern);
      
      verify(mockStorage.write(any, any)).called(1);
    });
  });
} 