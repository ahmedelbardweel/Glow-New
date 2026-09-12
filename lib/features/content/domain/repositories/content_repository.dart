import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/world_entity.dart';
import '../entities/mission_entity.dart';
import '../entities/story_entity.dart';
import '../entities/question_entity.dart';
import '../entities/child_progress_entity.dart';

abstract class ContentRepository {
  Future<Either<Failure, List<WorldEntity>>> getWorlds();
  Future<Either<Failure, WorldEntity>> addWorld(WorldEntity world);
  Future<Either<Failure, WorldEntity>> updateWorld(WorldEntity world);
  Future<Either<Failure, void>> deleteWorld(String id);
  
  Future<Either<Failure, List<MissionEntity>>> getMissions(String worldId);
  Future<Either<Failure, MissionEntity>> addMission(MissionEntity mission);
  Future<Either<Failure, MissionEntity>> updateMission(MissionEntity mission);
  Future<Either<Failure, void>> deleteMission(String id);
  
  Future<Either<Failure, List<StoryEntity>>> getStories(String missionId);
  Future<Either<Failure, StoryEntity>> addStory(StoryEntity story, {File? audioFile, File? characterFile});
  Future<Either<Failure, StoryEntity>> updateStory(StoryEntity story, {File? audioFile, File? characterFile});
  Future<Either<Failure, void>> deleteStory(String id);
  
  // Questions
  Future<Either<Failure, List<QuestionEntity>>> getQuestions(String missionId);
  Future<Either<Failure, QuestionEntity>> addQuestion(QuestionEntity question);
  Future<Either<Failure, QuestionEntity>> updateQuestion(QuestionEntity question);
  Future<Either<Failure, void>> deleteQuestion(String id);

  // Progress
  Future<Either<Failure, void>> completeMission(String missionId, String childId);
  Future<Either<Failure, List<ChildProgressEntity>>> getCompletedMissions(String childId);
}
