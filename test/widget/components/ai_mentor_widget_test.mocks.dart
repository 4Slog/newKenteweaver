// Mocks generated by Mockito 5.4.5 from annotations
// in kente_codeweaver/test/widget/components/ai_mentor_widget_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:ui' as _i8;

import 'package:kente_codeweaver/models/pattern_difficulty.dart' as _i7;
import 'package:kente_codeweaver/models/story_model.dart' as _i2;
import 'package:kente_codeweaver/services/device_profile_service.dart' as _i5;
import 'package:kente_codeweaver/services/storage_service.dart' as _i6;
import 'package:kente_codeweaver/services/story_engine_service.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeStoryModel_0 extends _i1.SmartFake implements _i2.StoryModel {
  _FakeStoryModel_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStoryNode_1 extends _i1.SmartFake implements _i2.StoryNode {
  _FakeStoryNode_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [StoryEngineService].
///
/// See the documentation for Mockito's code generation for more information.
class MockStoryEngineService extends _i1.Mock
    implements _i3.StoryEngineService {
  MockStoryEngineService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
      ) as bool);

  @override
  _i4.Future<void> initialize({
    required _i5.DeviceProfileService? deviceProfileService,
    required _i6.StorageService? storageService,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #initialize,
          [],
          {
            #deviceProfileService: deviceProfileService,
            #storageService: storageService,
          },
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.StoryModel> generateStory({
    required String? storyId,
    required _i7.PatternDifficulty? difficulty,
    required List<String>? targetConcepts,
    String? language = 'en',
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #generateStory,
          [],
          {
            #storyId: storyId,
            #difficulty: difficulty,
            #targetConcepts: targetConcepts,
            #language: language,
          },
        ),
        returnValue: _i4.Future<_i2.StoryModel>.value(_FakeStoryModel_0(
          this,
          Invocation.method(
            #generateStory,
            [],
            {
              #storyId: storyId,
              #difficulty: difficulty,
              #targetConcepts: targetConcepts,
              #language: language,
            },
          ),
        )),
      ) as _i4.Future<_i2.StoryModel>);

  @override
  _i4.Future<_i2.StoryModel?> getStory(String? storyId) => (super.noSuchMethod(
        Invocation.method(
          #getStory,
          [storyId],
        ),
        returnValue: _i4.Future<_i2.StoryModel?>.value(),
      ) as _i4.Future<_i2.StoryModel?>);

  @override
  _i4.Future<void> setCurrentStory(String? storyId) => (super.noSuchMethod(
        Invocation.method(
          #setCurrentStory,
          [storyId],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> clearCache() => (super.noSuchMethod(
        Invocation.method(
          #clearCache,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.StoryNode> getNode(String? nodeId) => (super.noSuchMethod(
        Invocation.method(
          #getNode,
          [nodeId],
        ),
        returnValue: _i4.Future<_i2.StoryNode>.value(_FakeStoryNode_1(
          this,
          Invocation.method(
            #getNode,
            [nodeId],
          ),
        )),
      ) as _i4.Future<_i2.StoryNode>);

  @override
  void reset() => super.noSuchMethod(
        Invocation.method(
          #reset,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addListener(_i8.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void removeListener(_i8.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #removeListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void dispose() => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void notifyListeners() => super.noSuchMethod(
        Invocation.method(
          #notifyListeners,
          [],
        ),
        returnValueForMissingStub: null,
      );
}
