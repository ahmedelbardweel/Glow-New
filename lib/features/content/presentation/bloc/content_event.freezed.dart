// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ContentEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentEventCopyWith<$Res> {
  factory $ContentEventCopyWith(
    ContentEvent value,
    $Res Function(ContentEvent) then,
  ) = _$ContentEventCopyWithImpl<$Res, ContentEvent>;
}

/// @nodoc
class _$ContentEventCopyWithImpl<$Res, $Val extends ContentEvent>
    implements $ContentEventCopyWith<$Res> {
  _$ContentEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$GetWorldsImplCopyWith<$Res> {
  factory _$$GetWorldsImplCopyWith(
    _$GetWorldsImpl value,
    $Res Function(_$GetWorldsImpl) then,
  ) = __$$GetWorldsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GetWorldsImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$GetWorldsImpl>
    implements _$$GetWorldsImplCopyWith<$Res> {
  __$$GetWorldsImplCopyWithImpl(
    _$GetWorldsImpl _value,
    $Res Function(_$GetWorldsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$GetWorldsImpl implements _GetWorlds {
  const _$GetWorldsImpl();

  @override
  String toString() {
    return 'ContentEvent.getWorlds()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GetWorldsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return getWorlds();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return getWorlds?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getWorlds != null) {
      return getWorlds();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return getWorlds(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return getWorlds?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getWorlds != null) {
      return getWorlds(this);
    }
    return orElse();
  }
}

abstract class _GetWorlds implements ContentEvent {
  const factory _GetWorlds() = _$GetWorldsImpl;
}

/// @nodoc
abstract class _$$AddWorldImplCopyWith<$Res> {
  factory _$$AddWorldImplCopyWith(
    _$AddWorldImpl value,
    $Res Function(_$AddWorldImpl) then,
  ) = __$$AddWorldImplCopyWithImpl<$Res>;
  @useResult
  $Res call({WorldEntity world});
}

/// @nodoc
class __$$AddWorldImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$AddWorldImpl>
    implements _$$AddWorldImplCopyWith<$Res> {
  __$$AddWorldImplCopyWithImpl(
    _$AddWorldImpl _value,
    $Res Function(_$AddWorldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? world = null}) {
    return _then(
      _$AddWorldImpl(
        null == world
            ? _value.world
            : world // ignore: cast_nullable_to_non_nullable
                  as WorldEntity,
      ),
    );
  }
}

/// @nodoc

class _$AddWorldImpl implements _AddWorld {
  const _$AddWorldImpl(this.world);

  @override
  final WorldEntity world;

  @override
  String toString() {
    return 'ContentEvent.addWorld(world: $world)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddWorldImpl &&
            (identical(other.world, world) || other.world == world));
  }

  @override
  int get hashCode => Object.hash(runtimeType, world);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddWorldImplCopyWith<_$AddWorldImpl> get copyWith =>
      __$$AddWorldImplCopyWithImpl<_$AddWorldImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return addWorld(world);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return addWorld?.call(world);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addWorld != null) {
      return addWorld(world);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return addWorld(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return addWorld?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addWorld != null) {
      return addWorld(this);
    }
    return orElse();
  }
}

abstract class _AddWorld implements ContentEvent {
  const factory _AddWorld(final WorldEntity world) = _$AddWorldImpl;

  WorldEntity get world;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddWorldImplCopyWith<_$AddWorldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GetMissionsImplCopyWith<$Res> {
  factory _$$GetMissionsImplCopyWith(
    _$GetMissionsImpl value,
    $Res Function(_$GetMissionsImpl) then,
  ) = __$$GetMissionsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String worldId});
}

/// @nodoc
class __$$GetMissionsImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$GetMissionsImpl>
    implements _$$GetMissionsImplCopyWith<$Res> {
  __$$GetMissionsImplCopyWithImpl(
    _$GetMissionsImpl _value,
    $Res Function(_$GetMissionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? worldId = null}) {
    return _then(
      _$GetMissionsImpl(
        null == worldId
            ? _value.worldId
            : worldId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GetMissionsImpl implements _GetMissions {
  const _$GetMissionsImpl(this.worldId);

  @override
  final String worldId;

  @override
  String toString() {
    return 'ContentEvent.getMissions(worldId: $worldId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetMissionsImpl &&
            (identical(other.worldId, worldId) || other.worldId == worldId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, worldId);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetMissionsImplCopyWith<_$GetMissionsImpl> get copyWith =>
      __$$GetMissionsImplCopyWithImpl<_$GetMissionsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return getMissions(worldId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return getMissions?.call(worldId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getMissions != null) {
      return getMissions(worldId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return getMissions(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return getMissions?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getMissions != null) {
      return getMissions(this);
    }
    return orElse();
  }
}

abstract class _GetMissions implements ContentEvent {
  const factory _GetMissions(final String worldId) = _$GetMissionsImpl;

  String get worldId;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetMissionsImplCopyWith<_$GetMissionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddMissionImplCopyWith<$Res> {
  factory _$$AddMissionImplCopyWith(
    _$AddMissionImpl value,
    $Res Function(_$AddMissionImpl) then,
  ) = __$$AddMissionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MissionEntity mission});
}

/// @nodoc
class __$$AddMissionImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$AddMissionImpl>
    implements _$$AddMissionImplCopyWith<$Res> {
  __$$AddMissionImplCopyWithImpl(
    _$AddMissionImpl _value,
    $Res Function(_$AddMissionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mission = null}) {
    return _then(
      _$AddMissionImpl(
        null == mission
            ? _value.mission
            : mission // ignore: cast_nullable_to_non_nullable
                  as MissionEntity,
      ),
    );
  }
}

/// @nodoc

class _$AddMissionImpl implements _AddMission {
  const _$AddMissionImpl(this.mission);

  @override
  final MissionEntity mission;

  @override
  String toString() {
    return 'ContentEvent.addMission(mission: $mission)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddMissionImpl &&
            (identical(other.mission, mission) || other.mission == mission));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mission);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddMissionImplCopyWith<_$AddMissionImpl> get copyWith =>
      __$$AddMissionImplCopyWithImpl<_$AddMissionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return addMission(mission);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return addMission?.call(mission);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addMission != null) {
      return addMission(mission);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return addMission(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return addMission?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addMission != null) {
      return addMission(this);
    }
    return orElse();
  }
}

abstract class _AddMission implements ContentEvent {
  const factory _AddMission(final MissionEntity mission) = _$AddMissionImpl;

  MissionEntity get mission;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddMissionImplCopyWith<_$AddMissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GetStoriesImplCopyWith<$Res> {
  factory _$$GetStoriesImplCopyWith(
    _$GetStoriesImpl value,
    $Res Function(_$GetStoriesImpl) then,
  ) = __$$GetStoriesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String missionId});
}

/// @nodoc
class __$$GetStoriesImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$GetStoriesImpl>
    implements _$$GetStoriesImplCopyWith<$Res> {
  __$$GetStoriesImplCopyWithImpl(
    _$GetStoriesImpl _value,
    $Res Function(_$GetStoriesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? missionId = null}) {
    return _then(
      _$GetStoriesImpl(
        null == missionId
            ? _value.missionId
            : missionId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GetStoriesImpl implements _GetStories {
  const _$GetStoriesImpl(this.missionId);

  @override
  final String missionId;

  @override
  String toString() {
    return 'ContentEvent.getStories(missionId: $missionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetStoriesImpl &&
            (identical(other.missionId, missionId) ||
                other.missionId == missionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, missionId);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetStoriesImplCopyWith<_$GetStoriesImpl> get copyWith =>
      __$$GetStoriesImplCopyWithImpl<_$GetStoriesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return getStories(missionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return getStories?.call(missionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getStories != null) {
      return getStories(missionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return getStories(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return getStories?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getStories != null) {
      return getStories(this);
    }
    return orElse();
  }
}

abstract class _GetStories implements ContentEvent {
  const factory _GetStories(final String missionId) = _$GetStoriesImpl;

  String get missionId;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetStoriesImplCopyWith<_$GetStoriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddStoryImplCopyWith<$Res> {
  factory _$$AddStoryImplCopyWith(
    _$AddStoryImpl value,
    $Res Function(_$AddStoryImpl) then,
  ) = __$$AddStoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StoryEntity story, File? audioFile});
}

/// @nodoc
class __$$AddStoryImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$AddStoryImpl>
    implements _$$AddStoryImplCopyWith<$Res> {
  __$$AddStoryImplCopyWithImpl(
    _$AddStoryImpl _value,
    $Res Function(_$AddStoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? story = null, Object? audioFile = freezed}) {
    return _then(
      _$AddStoryImpl(
        null == story
            ? _value.story
            : story // ignore: cast_nullable_to_non_nullable
                  as StoryEntity,
        audioFile: freezed == audioFile
            ? _value.audioFile
            : audioFile // ignore: cast_nullable_to_non_nullable
                  as File?,
      ),
    );
  }
}

/// @nodoc

class _$AddStoryImpl implements _AddStory {
  const _$AddStoryImpl(this.story, {this.audioFile});

  @override
  final StoryEntity story;
  @override
  final File? audioFile;

  @override
  String toString() {
    return 'ContentEvent.addStory(story: $story, audioFile: $audioFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddStoryImpl &&
            (identical(other.story, story) || other.story == story) &&
            (identical(other.audioFile, audioFile) ||
                other.audioFile == audioFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, story, audioFile);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddStoryImplCopyWith<_$AddStoryImpl> get copyWith =>
      __$$AddStoryImplCopyWithImpl<_$AddStoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return addStory(story, audioFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return addStory?.call(story, audioFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addStory != null) {
      return addStory(story, audioFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return addStory(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return addStory?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addStory != null) {
      return addStory(this);
    }
    return orElse();
  }
}

abstract class _AddStory implements ContentEvent {
  const factory _AddStory(final StoryEntity story, {final File? audioFile}) =
      _$AddStoryImpl;

  StoryEntity get story;
  File? get audioFile;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddStoryImplCopyWith<_$AddStoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GetQuestionsImplCopyWith<$Res> {
  factory _$$GetQuestionsImplCopyWith(
    _$GetQuestionsImpl value,
    $Res Function(_$GetQuestionsImpl) then,
  ) = __$$GetQuestionsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String missionId});
}

/// @nodoc
class __$$GetQuestionsImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$GetQuestionsImpl>
    implements _$$GetQuestionsImplCopyWith<$Res> {
  __$$GetQuestionsImplCopyWithImpl(
    _$GetQuestionsImpl _value,
    $Res Function(_$GetQuestionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? missionId = null}) {
    return _then(
      _$GetQuestionsImpl(
        null == missionId
            ? _value.missionId
            : missionId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GetQuestionsImpl implements _GetQuestions {
  const _$GetQuestionsImpl(this.missionId);

  @override
  final String missionId;

  @override
  String toString() {
    return 'ContentEvent.getQuestions(missionId: $missionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetQuestionsImpl &&
            (identical(other.missionId, missionId) ||
                other.missionId == missionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, missionId);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetQuestionsImplCopyWith<_$GetQuestionsImpl> get copyWith =>
      __$$GetQuestionsImplCopyWithImpl<_$GetQuestionsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return getQuestions(missionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return getQuestions?.call(missionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getQuestions != null) {
      return getQuestions(missionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return getQuestions(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return getQuestions?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getQuestions != null) {
      return getQuestions(this);
    }
    return orElse();
  }
}

abstract class _GetQuestions implements ContentEvent {
  const factory _GetQuestions(final String missionId) = _$GetQuestionsImpl;

  String get missionId;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetQuestionsImplCopyWith<_$GetQuestionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddQuestionImplCopyWith<$Res> {
  factory _$$AddQuestionImplCopyWith(
    _$AddQuestionImpl value,
    $Res Function(_$AddQuestionImpl) then,
  ) = __$$AddQuestionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({QuestionEntity question});
}

/// @nodoc
class __$$AddQuestionImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$AddQuestionImpl>
    implements _$$AddQuestionImplCopyWith<$Res> {
  __$$AddQuestionImplCopyWithImpl(
    _$AddQuestionImpl _value,
    $Res Function(_$AddQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? question = null}) {
    return _then(
      _$AddQuestionImpl(
        null == question
            ? _value.question
            : question // ignore: cast_nullable_to_non_nullable
                  as QuestionEntity,
      ),
    );
  }
}

/// @nodoc

class _$AddQuestionImpl implements _AddQuestion {
  const _$AddQuestionImpl(this.question);

  @override
  final QuestionEntity question;

  @override
  String toString() {
    return 'ContentEvent.addQuestion(question: $question)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddQuestionImpl &&
            (identical(other.question, question) ||
                other.question == question));
  }

  @override
  int get hashCode => Object.hash(runtimeType, question);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddQuestionImplCopyWith<_$AddQuestionImpl> get copyWith =>
      __$$AddQuestionImplCopyWithImpl<_$AddQuestionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return addQuestion(question);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return addQuestion?.call(question);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addQuestion != null) {
      return addQuestion(question);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return addQuestion(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return addQuestion?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (addQuestion != null) {
      return addQuestion(this);
    }
    return orElse();
  }
}

abstract class _AddQuestion implements ContentEvent {
  const factory _AddQuestion(final QuestionEntity question) = _$AddQuestionImpl;

  QuestionEntity get question;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddQuestionImplCopyWith<_$AddQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompleteMissionImplCopyWith<$Res> {
  factory _$$CompleteMissionImplCopyWith(
    _$CompleteMissionImpl value,
    $Res Function(_$CompleteMissionImpl) then,
  ) = __$$CompleteMissionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String missionId, String childId});
}

/// @nodoc
class __$$CompleteMissionImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$CompleteMissionImpl>
    implements _$$CompleteMissionImplCopyWith<$Res> {
  __$$CompleteMissionImplCopyWithImpl(
    _$CompleteMissionImpl _value,
    $Res Function(_$CompleteMissionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? missionId = null, Object? childId = null}) {
    return _then(
      _$CompleteMissionImpl(
        null == missionId
            ? _value.missionId
            : missionId // ignore: cast_nullable_to_non_nullable
                  as String,
        null == childId
            ? _value.childId
            : childId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$CompleteMissionImpl implements _CompleteMission {
  const _$CompleteMissionImpl(this.missionId, this.childId);

  @override
  final String missionId;
  @override
  final String childId;

  @override
  String toString() {
    return 'ContentEvent.completeMission(missionId: $missionId, childId: $childId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteMissionImpl &&
            (identical(other.missionId, missionId) ||
                other.missionId == missionId) &&
            (identical(other.childId, childId) || other.childId == childId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, missionId, childId);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompleteMissionImplCopyWith<_$CompleteMissionImpl> get copyWith =>
      __$$CompleteMissionImplCopyWithImpl<_$CompleteMissionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return completeMission(missionId, childId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return completeMission?.call(missionId, childId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (completeMission != null) {
      return completeMission(missionId, childId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return completeMission(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return completeMission?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (completeMission != null) {
      return completeMission(this);
    }
    return orElse();
  }
}

abstract class _CompleteMission implements ContentEvent {
  const factory _CompleteMission(final String missionId, final String childId) =
      _$CompleteMissionImpl;

  String get missionId;
  String get childId;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteMissionImplCopyWith<_$CompleteMissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GetCompletedMissionsImplCopyWith<$Res> {
  factory _$$GetCompletedMissionsImplCopyWith(
    _$GetCompletedMissionsImpl value,
    $Res Function(_$GetCompletedMissionsImpl) then,
  ) = __$$GetCompletedMissionsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String childId});
}

/// @nodoc
class __$$GetCompletedMissionsImplCopyWithImpl<$Res>
    extends _$ContentEventCopyWithImpl<$Res, _$GetCompletedMissionsImpl>
    implements _$$GetCompletedMissionsImplCopyWith<$Res> {
  __$$GetCompletedMissionsImplCopyWithImpl(
    _$GetCompletedMissionsImpl _value,
    $Res Function(_$GetCompletedMissionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? childId = null}) {
    return _then(
      _$GetCompletedMissionsImpl(
        null == childId
            ? _value.childId
            : childId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GetCompletedMissionsImpl implements _GetCompletedMissions {
  const _$GetCompletedMissionsImpl(this.childId);

  @override
  final String childId;

  @override
  String toString() {
    return 'ContentEvent.getCompletedMissions(childId: $childId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetCompletedMissionsImpl &&
            (identical(other.childId, childId) || other.childId == childId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, childId);

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetCompletedMissionsImplCopyWith<_$GetCompletedMissionsImpl>
  get copyWith =>
      __$$GetCompletedMissionsImplCopyWithImpl<_$GetCompletedMissionsImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() getWorlds,
    required TResult Function(WorldEntity world) addWorld,
    required TResult Function(String worldId) getMissions,
    required TResult Function(MissionEntity mission) addMission,
    required TResult Function(String missionId) getStories,
    required TResult Function(StoryEntity story, File? audioFile) addStory,
    required TResult Function(String missionId) getQuestions,
    required TResult Function(QuestionEntity question) addQuestion,
    required TResult Function(String missionId, String childId) completeMission,
    required TResult Function(String childId) getCompletedMissions,
  }) {
    return getCompletedMissions(childId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? getWorlds,
    TResult? Function(WorldEntity world)? addWorld,
    TResult? Function(String worldId)? getMissions,
    TResult? Function(MissionEntity mission)? addMission,
    TResult? Function(String missionId)? getStories,
    TResult? Function(StoryEntity story, File? audioFile)? addStory,
    TResult? Function(String missionId)? getQuestions,
    TResult? Function(QuestionEntity question)? addQuestion,
    TResult? Function(String missionId, String childId)? completeMission,
    TResult? Function(String childId)? getCompletedMissions,
  }) {
    return getCompletedMissions?.call(childId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? getWorlds,
    TResult Function(WorldEntity world)? addWorld,
    TResult Function(String worldId)? getMissions,
    TResult Function(MissionEntity mission)? addMission,
    TResult Function(String missionId)? getStories,
    TResult Function(StoryEntity story, File? audioFile)? addStory,
    TResult Function(String missionId)? getQuestions,
    TResult Function(QuestionEntity question)? addQuestion,
    TResult Function(String missionId, String childId)? completeMission,
    TResult Function(String childId)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getCompletedMissions != null) {
      return getCompletedMissions(childId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_GetWorlds value) getWorlds,
    required TResult Function(_AddWorld value) addWorld,
    required TResult Function(_GetMissions value) getMissions,
    required TResult Function(_AddMission value) addMission,
    required TResult Function(_GetStories value) getStories,
    required TResult Function(_AddStory value) addStory,
    required TResult Function(_GetQuestions value) getQuestions,
    required TResult Function(_AddQuestion value) addQuestion,
    required TResult Function(_CompleteMission value) completeMission,
    required TResult Function(_GetCompletedMissions value) getCompletedMissions,
  }) {
    return getCompletedMissions(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_GetWorlds value)? getWorlds,
    TResult? Function(_AddWorld value)? addWorld,
    TResult? Function(_GetMissions value)? getMissions,
    TResult? Function(_AddMission value)? addMission,
    TResult? Function(_GetStories value)? getStories,
    TResult? Function(_AddStory value)? addStory,
    TResult? Function(_GetQuestions value)? getQuestions,
    TResult? Function(_AddQuestion value)? addQuestion,
    TResult? Function(_CompleteMission value)? completeMission,
    TResult? Function(_GetCompletedMissions value)? getCompletedMissions,
  }) {
    return getCompletedMissions?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_GetWorlds value)? getWorlds,
    TResult Function(_AddWorld value)? addWorld,
    TResult Function(_GetMissions value)? getMissions,
    TResult Function(_AddMission value)? addMission,
    TResult Function(_GetStories value)? getStories,
    TResult Function(_AddStory value)? addStory,
    TResult Function(_GetQuestions value)? getQuestions,
    TResult Function(_AddQuestion value)? addQuestion,
    TResult Function(_CompleteMission value)? completeMission,
    TResult Function(_GetCompletedMissions value)? getCompletedMissions,
    required TResult orElse(),
  }) {
    if (getCompletedMissions != null) {
      return getCompletedMissions(this);
    }
    return orElse();
  }
}

abstract class _GetCompletedMissions implements ContentEvent {
  const factory _GetCompletedMissions(final String childId) =
      _$GetCompletedMissionsImpl;

  String get childId;

  /// Create a copy of ContentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetCompletedMissionsImplCopyWith<_$GetCompletedMissionsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
