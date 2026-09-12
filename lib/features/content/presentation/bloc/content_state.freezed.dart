// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ContentState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentStateCopyWith<$Res> {
  factory $ContentStateCopyWith(
    ContentState value,
    $Res Function(ContentState) then,
  ) = _$ContentStateCopyWithImpl<$Res, ContentState>;
}

/// @nodoc
class _$ContentStateCopyWithImpl<$Res, $Val extends ContentState>
    implements $ContentStateCopyWith<$Res> {
  _$ContentStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'ContentState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements ContentState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'ContentState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements ContentState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$WorldsLoadedImplCopyWith<$Res> {
  factory _$$WorldsLoadedImplCopyWith(
    _$WorldsLoadedImpl value,
    $Res Function(_$WorldsLoadedImpl) then,
  ) = __$$WorldsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<WorldEntity> worlds});
}

/// @nodoc
class __$$WorldsLoadedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$WorldsLoadedImpl>
    implements _$$WorldsLoadedImplCopyWith<$Res> {
  __$$WorldsLoadedImplCopyWithImpl(
    _$WorldsLoadedImpl _value,
    $Res Function(_$WorldsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? worlds = null}) {
    return _then(
      _$WorldsLoadedImpl(
        null == worlds
            ? _value._worlds
            : worlds // ignore: cast_nullable_to_non_nullable
                  as List<WorldEntity>,
      ),
    );
  }
}

/// @nodoc

class _$WorldsLoadedImpl implements _WorldsLoaded {
  const _$WorldsLoadedImpl(final List<WorldEntity> worlds) : _worlds = worlds;

  final List<WorldEntity> _worlds;
  @override
  List<WorldEntity> get worlds {
    if (_worlds is EqualUnmodifiableListView) return _worlds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_worlds);
  }

  @override
  String toString() {
    return 'ContentState.worldsLoaded(worlds: $worlds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorldsLoadedImpl &&
            const DeepCollectionEquality().equals(other._worlds, _worlds));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_worlds));

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorldsLoadedImplCopyWith<_$WorldsLoadedImpl> get copyWith =>
      __$$WorldsLoadedImplCopyWithImpl<_$WorldsLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return worldsLoaded(worlds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return worldsLoaded?.call(worlds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (worldsLoaded != null) {
      return worldsLoaded(worlds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return worldsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return worldsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (worldsLoaded != null) {
      return worldsLoaded(this);
    }
    return orElse();
  }
}

abstract class _WorldsLoaded implements ContentState {
  const factory _WorldsLoaded(final List<WorldEntity> worlds) =
      _$WorldsLoadedImpl;

  List<WorldEntity> get worlds;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorldsLoadedImplCopyWith<_$WorldsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WorldAddedImplCopyWith<$Res> {
  factory _$$WorldAddedImplCopyWith(
    _$WorldAddedImpl value,
    $Res Function(_$WorldAddedImpl) then,
  ) = __$$WorldAddedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({WorldEntity world});
}

/// @nodoc
class __$$WorldAddedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$WorldAddedImpl>
    implements _$$WorldAddedImplCopyWith<$Res> {
  __$$WorldAddedImplCopyWithImpl(
    _$WorldAddedImpl _value,
    $Res Function(_$WorldAddedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? world = null}) {
    return _then(
      _$WorldAddedImpl(
        null == world
            ? _value.world
            : world // ignore: cast_nullable_to_non_nullable
                  as WorldEntity,
      ),
    );
  }
}

/// @nodoc

class _$WorldAddedImpl implements _WorldAdded {
  const _$WorldAddedImpl(this.world);

  @override
  final WorldEntity world;

  @override
  String toString() {
    return 'ContentState.worldAdded(world: $world)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorldAddedImpl &&
            (identical(other.world, world) || other.world == world));
  }

  @override
  int get hashCode => Object.hash(runtimeType, world);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorldAddedImplCopyWith<_$WorldAddedImpl> get copyWith =>
      __$$WorldAddedImplCopyWithImpl<_$WorldAddedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return worldAdded(world);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return worldAdded?.call(world);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (worldAdded != null) {
      return worldAdded(world);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return worldAdded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return worldAdded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (worldAdded != null) {
      return worldAdded(this);
    }
    return orElse();
  }
}

abstract class _WorldAdded implements ContentState {
  const factory _WorldAdded(final WorldEntity world) = _$WorldAddedImpl;

  WorldEntity get world;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorldAddedImplCopyWith<_$WorldAddedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MissionsLoadedImplCopyWith<$Res> {
  factory _$$MissionsLoadedImplCopyWith(
    _$MissionsLoadedImpl value,
    $Res Function(_$MissionsLoadedImpl) then,
  ) = __$$MissionsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<MissionEntity> missions});
}

/// @nodoc
class __$$MissionsLoadedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$MissionsLoadedImpl>
    implements _$$MissionsLoadedImplCopyWith<$Res> {
  __$$MissionsLoadedImplCopyWithImpl(
    _$MissionsLoadedImpl _value,
    $Res Function(_$MissionsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? missions = null}) {
    return _then(
      _$MissionsLoadedImpl(
        null == missions
            ? _value._missions
            : missions // ignore: cast_nullable_to_non_nullable
                  as List<MissionEntity>,
      ),
    );
  }
}

/// @nodoc

class _$MissionsLoadedImpl implements _MissionsLoaded {
  const _$MissionsLoadedImpl(final List<MissionEntity> missions)
    : _missions = missions;

  final List<MissionEntity> _missions;
  @override
  List<MissionEntity> get missions {
    if (_missions is EqualUnmodifiableListView) return _missions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missions);
  }

  @override
  String toString() {
    return 'ContentState.missionsLoaded(missions: $missions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissionsLoadedImpl &&
            const DeepCollectionEquality().equals(other._missions, _missions));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_missions));

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MissionsLoadedImplCopyWith<_$MissionsLoadedImpl> get copyWith =>
      __$$MissionsLoadedImplCopyWithImpl<_$MissionsLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return missionsLoaded(missions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return missionsLoaded?.call(missions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (missionsLoaded != null) {
      return missionsLoaded(missions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return missionsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return missionsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (missionsLoaded != null) {
      return missionsLoaded(this);
    }
    return orElse();
  }
}

abstract class _MissionsLoaded implements ContentState {
  const factory _MissionsLoaded(final List<MissionEntity> missions) =
      _$MissionsLoadedImpl;

  List<MissionEntity> get missions;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MissionsLoadedImplCopyWith<_$MissionsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MissionAddedImplCopyWith<$Res> {
  factory _$$MissionAddedImplCopyWith(
    _$MissionAddedImpl value,
    $Res Function(_$MissionAddedImpl) then,
  ) = __$$MissionAddedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MissionEntity mission});
}

/// @nodoc
class __$$MissionAddedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$MissionAddedImpl>
    implements _$$MissionAddedImplCopyWith<$Res> {
  __$$MissionAddedImplCopyWithImpl(
    _$MissionAddedImpl _value,
    $Res Function(_$MissionAddedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mission = null}) {
    return _then(
      _$MissionAddedImpl(
        null == mission
            ? _value.mission
            : mission // ignore: cast_nullable_to_non_nullable
                  as MissionEntity,
      ),
    );
  }
}

/// @nodoc

class _$MissionAddedImpl implements _MissionAdded {
  const _$MissionAddedImpl(this.mission);

  @override
  final MissionEntity mission;

  @override
  String toString() {
    return 'ContentState.missionAdded(mission: $mission)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissionAddedImpl &&
            (identical(other.mission, mission) || other.mission == mission));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mission);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MissionAddedImplCopyWith<_$MissionAddedImpl> get copyWith =>
      __$$MissionAddedImplCopyWithImpl<_$MissionAddedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return missionAdded(mission);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return missionAdded?.call(mission);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (missionAdded != null) {
      return missionAdded(mission);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return missionAdded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return missionAdded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (missionAdded != null) {
      return missionAdded(this);
    }
    return orElse();
  }
}

abstract class _MissionAdded implements ContentState {
  const factory _MissionAdded(final MissionEntity mission) = _$MissionAddedImpl;

  MissionEntity get mission;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MissionAddedImplCopyWith<_$MissionAddedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StoriesLoadedImplCopyWith<$Res> {
  factory _$$StoriesLoadedImplCopyWith(
    _$StoriesLoadedImpl value,
    $Res Function(_$StoriesLoadedImpl) then,
  ) = __$$StoriesLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<StoryEntity> stories});
}

/// @nodoc
class __$$StoriesLoadedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$StoriesLoadedImpl>
    implements _$$StoriesLoadedImplCopyWith<$Res> {
  __$$StoriesLoadedImplCopyWithImpl(
    _$StoriesLoadedImpl _value,
    $Res Function(_$StoriesLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? stories = null}) {
    return _then(
      _$StoriesLoadedImpl(
        null == stories
            ? _value._stories
            : stories // ignore: cast_nullable_to_non_nullable
                  as List<StoryEntity>,
      ),
    );
  }
}

/// @nodoc

class _$StoriesLoadedImpl implements _StoriesLoaded {
  const _$StoriesLoadedImpl(final List<StoryEntity> stories)
    : _stories = stories;

  final List<StoryEntity> _stories;
  @override
  List<StoryEntity> get stories {
    if (_stories is EqualUnmodifiableListView) return _stories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stories);
  }

  @override
  String toString() {
    return 'ContentState.storiesLoaded(stories: $stories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoriesLoadedImpl &&
            const DeepCollectionEquality().equals(other._stories, _stories));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_stories));

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoriesLoadedImplCopyWith<_$StoriesLoadedImpl> get copyWith =>
      __$$StoriesLoadedImplCopyWithImpl<_$StoriesLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return storiesLoaded(stories);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return storiesLoaded?.call(stories);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (storiesLoaded != null) {
      return storiesLoaded(stories);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return storiesLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return storiesLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (storiesLoaded != null) {
      return storiesLoaded(this);
    }
    return orElse();
  }
}

abstract class _StoriesLoaded implements ContentState {
  const factory _StoriesLoaded(final List<StoryEntity> stories) =
      _$StoriesLoadedImpl;

  List<StoryEntity> get stories;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoriesLoadedImplCopyWith<_$StoriesLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StoryAddedImplCopyWith<$Res> {
  factory _$$StoryAddedImplCopyWith(
    _$StoryAddedImpl value,
    $Res Function(_$StoryAddedImpl) then,
  ) = __$$StoryAddedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StoryEntity story});
}

/// @nodoc
class __$$StoryAddedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$StoryAddedImpl>
    implements _$$StoryAddedImplCopyWith<$Res> {
  __$$StoryAddedImplCopyWithImpl(
    _$StoryAddedImpl _value,
    $Res Function(_$StoryAddedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? story = null}) {
    return _then(
      _$StoryAddedImpl(
        null == story
            ? _value.story
            : story // ignore: cast_nullable_to_non_nullable
                  as StoryEntity,
      ),
    );
  }
}

/// @nodoc

class _$StoryAddedImpl implements _StoryAdded {
  const _$StoryAddedImpl(this.story);

  @override
  final StoryEntity story;

  @override
  String toString() {
    return 'ContentState.storyAdded(story: $story)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryAddedImpl &&
            (identical(other.story, story) || other.story == story));
  }

  @override
  int get hashCode => Object.hash(runtimeType, story);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryAddedImplCopyWith<_$StoryAddedImpl> get copyWith =>
      __$$StoryAddedImplCopyWithImpl<_$StoryAddedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return storyAdded(story);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return storyAdded?.call(story);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (storyAdded != null) {
      return storyAdded(story);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return storyAdded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return storyAdded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (storyAdded != null) {
      return storyAdded(this);
    }
    return orElse();
  }
}

abstract class _StoryAdded implements ContentState {
  const factory _StoryAdded(final StoryEntity story) = _$StoryAddedImpl;

  StoryEntity get story;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryAddedImplCopyWith<_$StoryAddedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$QuestionsLoadedImplCopyWith<$Res> {
  factory _$$QuestionsLoadedImplCopyWith(
    _$QuestionsLoadedImpl value,
    $Res Function(_$QuestionsLoadedImpl) then,
  ) = __$$QuestionsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<QuestionEntity> questions});
}

/// @nodoc
class __$$QuestionsLoadedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$QuestionsLoadedImpl>
    implements _$$QuestionsLoadedImplCopyWith<$Res> {
  __$$QuestionsLoadedImplCopyWithImpl(
    _$QuestionsLoadedImpl _value,
    $Res Function(_$QuestionsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? questions = null}) {
    return _then(
      _$QuestionsLoadedImpl(
        null == questions
            ? _value._questions
            : questions // ignore: cast_nullable_to_non_nullable
                  as List<QuestionEntity>,
      ),
    );
  }
}

/// @nodoc

class _$QuestionsLoadedImpl implements _QuestionsLoaded {
  const _$QuestionsLoadedImpl(final List<QuestionEntity> questions)
    : _questions = questions;

  final List<QuestionEntity> _questions;
  @override
  List<QuestionEntity> get questions {
    if (_questions is EqualUnmodifiableListView) return _questions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questions);
  }

  @override
  String toString() {
    return 'ContentState.questionsLoaded(questions: $questions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionsLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._questions,
              _questions,
            ));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_questions));

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionsLoadedImplCopyWith<_$QuestionsLoadedImpl> get copyWith =>
      __$$QuestionsLoadedImplCopyWithImpl<_$QuestionsLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return questionsLoaded(questions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return questionsLoaded?.call(questions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (questionsLoaded != null) {
      return questionsLoaded(questions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return questionsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return questionsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (questionsLoaded != null) {
      return questionsLoaded(this);
    }
    return orElse();
  }
}

abstract class _QuestionsLoaded implements ContentState {
  const factory _QuestionsLoaded(final List<QuestionEntity> questions) =
      _$QuestionsLoadedImpl;

  List<QuestionEntity> get questions;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionsLoadedImplCopyWith<_$QuestionsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$QuestionAddedImplCopyWith<$Res> {
  factory _$$QuestionAddedImplCopyWith(
    _$QuestionAddedImpl value,
    $Res Function(_$QuestionAddedImpl) then,
  ) = __$$QuestionAddedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({QuestionEntity question});
}

/// @nodoc
class __$$QuestionAddedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$QuestionAddedImpl>
    implements _$$QuestionAddedImplCopyWith<$Res> {
  __$$QuestionAddedImplCopyWithImpl(
    _$QuestionAddedImpl _value,
    $Res Function(_$QuestionAddedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? question = null}) {
    return _then(
      _$QuestionAddedImpl(
        null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as QuestionEntity,
      ),
    );
  }
}

/// @nodoc

class _$QuestionAddedImpl implements _QuestionAdded {
  const _$QuestionAddedImpl(this.question);

  @override
  final QuestionEntity question;

  @override
  String toString() {
    return 'ContentState.questionAdded(question: $question)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionAddedImpl &&
            (identical(other.question, question) ||
                other.question == question));
  }

  @override
  int get hashCode => Object.hash(runtimeType, question);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionAddedImplCopyWith<_$QuestionAddedImpl> get copyWith =>
      __$$QuestionAddedImplCopyWithImpl<_$QuestionAddedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return questionAdded(question);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return questionAdded?.call(question);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (questionAdded != null) {
      return questionAdded(question);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return questionAdded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return questionAdded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (questionAdded != null) {
      return questionAdded(this);
    }
    return orElse();
  }
}

abstract class _QuestionAdded implements ContentState {
  const factory _QuestionAdded(final QuestionEntity question) =
      _$QuestionAddedImpl;

  QuestionEntity get question;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionAddedImplCopyWith<_$QuestionAddedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompletedMissionsLoadedImplCopyWith<$Res> {
  factory _$$CompletedMissionsLoadedImplCopyWith(
    _$CompletedMissionsLoadedImpl value,
    $Res Function(_$CompletedMissionsLoadedImpl) then,
  ) = __$$CompletedMissionsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<ChildProgressEntity> progressList});
}

/// @nodoc
class __$$CompletedMissionsLoadedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$CompletedMissionsLoadedImpl>
    implements _$$CompletedMissionsLoadedImplCopyWith<$Res> {
  __$$CompletedMissionsLoadedImplCopyWithImpl(
    _$CompletedMissionsLoadedImpl _value,
    $Res Function(_$CompletedMissionsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? progressList = null}) {
    return _then(
      _$CompletedMissionsLoadedImpl(
        null == progressList
            ? _value._progressList
            : progressList // ignore: cast_nullable_to_non_nullable
                  as List<ChildProgressEntity>,
      ),
    );
  }
}

/// @nodoc

class _$CompletedMissionsLoadedImpl implements _CompletedMissionsLoaded {
  const _$CompletedMissionsLoadedImpl(
    final List<ChildProgressEntity> progressList,
  ) : _progressList = progressList;

  final List<ChildProgressEntity> _progressList;
  @override
  List<ChildProgressEntity> get progressList {
    if (_progressList is EqualUnmodifiableListView) return _progressList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_progressList);
  }

  @override
  String toString() {
    return 'ContentState.completedMissionsLoaded(progressList: $progressList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedMissionsLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._progressList,
              _progressList,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_progressList),
  );

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletedMissionsLoadedImplCopyWith<_$CompletedMissionsLoadedImpl>
  get copyWith =>
      __$$CompletedMissionsLoadedImplCopyWithImpl<
        _$CompletedMissionsLoadedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return completedMissionsLoaded(progressList);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return completedMissionsLoaded?.call(progressList);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completedMissionsLoaded != null) {
      return completedMissionsLoaded(progressList);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return completedMissionsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return completedMissionsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (completedMissionsLoaded != null) {
      return completedMissionsLoaded(this);
    }
    return orElse();
  }
}

abstract class _CompletedMissionsLoaded implements ContentState {
  const factory _CompletedMissionsLoaded(
    final List<ChildProgressEntity> progressList,
  ) = _$CompletedMissionsLoadedImpl;

  List<ChildProgressEntity> get progressList;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletedMissionsLoadedImplCopyWith<_$CompletedMissionsLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MissionCompletedImplCopyWith<$Res> {
  factory _$$MissionCompletedImplCopyWith(
    _$MissionCompletedImpl value,
    $Res Function(_$MissionCompletedImpl) then,
  ) = __$$MissionCompletedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$MissionCompletedImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$MissionCompletedImpl>
    implements _$$MissionCompletedImplCopyWith<$Res> {
  __$$MissionCompletedImplCopyWithImpl(
    _$MissionCompletedImpl _value,
    $Res Function(_$MissionCompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$MissionCompletedImpl implements _MissionCompleted {
  const _$MissionCompletedImpl();

  @override
  String toString() {
    return 'ContentState.missionCompleted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$MissionCompletedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return missionCompleted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return missionCompleted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (missionCompleted != null) {
      return missionCompleted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return missionCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return missionCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (missionCompleted != null) {
      return missionCompleted(this);
    }
    return orElse();
  }
}

abstract class _MissionCompleted implements ContentState {
  const factory _MissionCompleted() = _$MissionCompletedImpl;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'ContentState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<WorldEntity> worlds) worldsLoaded,
    required TResult Function(WorldEntity world) worldAdded,
    required TResult Function(List<MissionEntity> missions) missionsLoaded,
    required TResult Function(MissionEntity mission) missionAdded,
    required TResult Function(List<StoryEntity> stories) storiesLoaded,
    required TResult Function(StoryEntity story) storyAdded,
    required TResult Function(List<QuestionEntity> questions) questionsLoaded,
    required TResult Function(QuestionEntity question) questionAdded,
    required TResult Function(List<ChildProgressEntity> progressList)
    completedMissionsLoaded,
    required TResult Function() missionCompleted,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult? Function(WorldEntity world)? worldAdded,
    TResult? Function(List<MissionEntity> missions)? missionsLoaded,
    TResult? Function(MissionEntity mission)? missionAdded,
    TResult? Function(List<StoryEntity> stories)? storiesLoaded,
    TResult? Function(StoryEntity story)? storyAdded,
    TResult? Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult? Function(QuestionEntity question)? questionAdded,
    TResult? Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult? Function()? missionCompleted,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<WorldEntity> worlds)? worldsLoaded,
    TResult Function(WorldEntity world)? worldAdded,
    TResult Function(List<MissionEntity> missions)? missionsLoaded,
    TResult Function(MissionEntity mission)? missionAdded,
    TResult Function(List<StoryEntity> stories)? storiesLoaded,
    TResult Function(StoryEntity story)? storyAdded,
    TResult Function(List<QuestionEntity> questions)? questionsLoaded,
    TResult Function(QuestionEntity question)? questionAdded,
    TResult Function(List<ChildProgressEntity> progressList)?
    completedMissionsLoaded,
    TResult Function()? missionCompleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_WorldsLoaded value) worldsLoaded,
    required TResult Function(_WorldAdded value) worldAdded,
    required TResult Function(_MissionsLoaded value) missionsLoaded,
    required TResult Function(_MissionAdded value) missionAdded,
    required TResult Function(_StoriesLoaded value) storiesLoaded,
    required TResult Function(_StoryAdded value) storyAdded,
    required TResult Function(_QuestionsLoaded value) questionsLoaded,
    required TResult Function(_QuestionAdded value) questionAdded,
    required TResult Function(_CompletedMissionsLoaded value)
    completedMissionsLoaded,
    required TResult Function(_MissionCompleted value) missionCompleted,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_WorldsLoaded value)? worldsLoaded,
    TResult? Function(_WorldAdded value)? worldAdded,
    TResult? Function(_MissionsLoaded value)? missionsLoaded,
    TResult? Function(_MissionAdded value)? missionAdded,
    TResult? Function(_StoriesLoaded value)? storiesLoaded,
    TResult? Function(_StoryAdded value)? storyAdded,
    TResult? Function(_QuestionsLoaded value)? questionsLoaded,
    TResult? Function(_QuestionAdded value)? questionAdded,
    TResult? Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult? Function(_MissionCompleted value)? missionCompleted,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_WorldsLoaded value)? worldsLoaded,
    TResult Function(_WorldAdded value)? worldAdded,
    TResult Function(_MissionsLoaded value)? missionsLoaded,
    TResult Function(_MissionAdded value)? missionAdded,
    TResult Function(_StoriesLoaded value)? storiesLoaded,
    TResult Function(_StoryAdded value)? storyAdded,
    TResult Function(_QuestionsLoaded value)? questionsLoaded,
    TResult Function(_QuestionAdded value)? questionAdded,
    TResult Function(_CompletedMissionsLoaded value)? completedMissionsLoaded,
    TResult Function(_MissionCompleted value)? missionCompleted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements ContentState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of ContentState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
