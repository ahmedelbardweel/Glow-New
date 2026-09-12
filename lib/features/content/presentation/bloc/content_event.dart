import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/world_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/question_entity.dart';

part 'content_event.freezed.dart';

@freezed
class ContentEvent with _$ContentEvent {
  const factory ContentEvent.getWorlds() = _GetWorlds;
  const factory ContentEvent.addWorld(WorldEntity world) = _AddWorld;
  const factory ContentEvent.updateWorld(WorldEntity world) = _UpdateWorld;
  const factory ContentEvent.deleteWorld(String id) = _DeleteWorld;
  
  const factory ContentEvent.getMissions(String worldId) = _GetMissions;
  const factory ContentEvent.addMission(MissionEntity mission) = _AddMission;
  const factory ContentEvent.updateMission(MissionEntity mission) = _UpdateMission;
  const factory ContentEvent.deleteMission(String id) = _DeleteMission;
  
  const factory ContentEvent.getStories(String missionId) = _GetStories;
  const factory ContentEvent.addStory(StoryEntity story, {File? audioFile, File? characterFile}) = _AddStory;
  const factory ContentEvent.updateStory(StoryEntity story, {File? audioFile, File? characterFile}) = _UpdateStory;
  const factory ContentEvent.deleteStory(String id) = _DeleteStory;
  
  const factory ContentEvent.getQuestions(String missionId) = _GetQuestions;
  const factory ContentEvent.addQuestion(QuestionEntity question) = _AddQuestion;
  const factory ContentEvent.updateQuestion(QuestionEntity question) = _UpdateQuestion;
  const factory ContentEvent.deleteQuestion(String id) = _DeleteQuestion;
  
  const factory ContentEvent.completeMission(String missionId, String childId) = _CompleteMission;
  const factory ContentEvent.getCompletedMissions(String childId) = _GetCompletedMissions;
}
