import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/world_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/child_progress_entity.dart';

part 'content_state.freezed.dart';

@freezed
class ContentState with _$ContentState {
  const factory ContentState.initial() = _Initial;
  const factory ContentState.loading() = _Loading;
  
  const factory ContentState.worldsLoaded(List<WorldEntity> worlds) = _WorldsLoaded;
  const factory ContentState.worldAdded(WorldEntity world) = _WorldAdded;
  
  const factory ContentState.missionsLoaded(List<MissionEntity> missions) = _MissionsLoaded;
  const factory ContentState.missionAdded(MissionEntity mission) = _MissionAdded;
  
  const factory ContentState.storiesLoaded(List<StoryEntity> stories) = _StoriesLoaded;
  const factory ContentState.storyAdded(StoryEntity story) = _StoryAdded;
  
  const factory ContentState.questionsLoaded(List<QuestionEntity> questions) = _QuestionsLoaded;
  const factory ContentState.questionAdded(QuestionEntity question) = _QuestionAdded;
  
  const factory ContentState.completedMissionsLoaded(List<ChildProgressEntity> progressList) = _CompletedMissionsLoaded;
  const factory ContentState.missionCompleted() = _MissionCompleted;
  
  const factory ContentState.error(String message) = _Error;
}
