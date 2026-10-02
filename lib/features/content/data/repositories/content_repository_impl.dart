import 'dart:async';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/resource_manager.dart';
import '../../domain/entities/world_entity.dart';
import '../../domain/entities/mission_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/child_progress_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_local_data_source.dart';
import '../datasources/content_remote_data_source.dart';
import '../models/world_model.dart';
import '../models/mission_model.dart';
import '../models/story_model.dart';
import '../models/question_model.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remoteDataSource;
  final ContentLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ResourceManager resourceManager;

  ContentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.resourceManager,
  });

  @override
  Future<Either<Failure, List<WorldEntity>>> getWorlds({bool forceRefresh = false}) async {
    final cachedWorlds = await localDataSource.getCachedWorlds();
    if (!forceRefresh && cachedWorlds.isNotEmpty) {
      unawaited(_refreshWorlds());
      return Right(cachedWorlds);
    }
    if (!await networkInfo.isConnected) {
      if (cachedWorlds.isNotEmpty) return Right(cachedWorlds);
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة محلياً'));
    }
    try {
      final worlds = await remoteDataSource.getWorlds().timeout(const Duration(seconds: 4));
      await localDataSource.cacheWorlds(worlds);
      return Right(worlds);
    } catch (e) {
      if (cachedWorlds.isNotEmpty) return Right(cachedWorlds);
      return const Left(ServerFailure('تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.'));
    }
  }

  Future<void> _refreshWorlds() async {
    if (!await networkInfo.isConnected) return;
    try {
      final worlds = await remoteDataSource.getWorlds().timeout(const Duration(seconds: 6));
      await localDataSource.cacheWorlds(worlds);
      for (final world in worlds) {
        if (world.imageUrl.isNotEmpty) {
          resourceManager.downloadAndCacheInBackground(world.imageUrl, folder: 'images');
        }
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, WorldEntity>> addWorld(WorldEntity world) async {
    if (await networkInfo.isConnected) {
      try {
        final model = WorldModel(
          id: world.id,
          title: world.title,
          description: world.description,
          imageUrl: world.imageUrl,
        );
        final result = await remoteDataSource.addWorld(model);
        // Update local cache
        final current = await localDataSource.getCachedWorlds();
        current.add(result);
        await localDataSource.cacheWorlds(current);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<MissionEntity>>> getMissions(String worldId, {bool forceRefresh = false}) async {
    final cachedMissions = await localDataSource.getCachedMissions(worldId);
    if (!forceRefresh && cachedMissions.isNotEmpty) {
      unawaited(_refreshMissions(worldId));
      return Right(cachedMissions);
    }
    if (!await networkInfo.isConnected) {
      if (cachedMissions.isNotEmpty) return Right(cachedMissions);
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا توجد مهام محفوظة'));
    }
    try {
      final missions = await remoteDataSource.getMissions(worldId).timeout(const Duration(seconds: 4));
      await localDataSource.cacheMissions(worldId, missions);
      return Right(missions);
    } catch (e) {
      if (cachedMissions.isNotEmpty) return Right(cachedMissions);
      return const Left(ServerFailure('تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.'));
    }
  }

  Future<void> _refreshMissions(String worldId) async {
    if (!await networkInfo.isConnected) return;
    try {
      final missions = await remoteDataSource.getMissions(worldId).timeout(const Duration(seconds: 6));
      await localDataSource.cacheMissions(worldId, missions);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, MissionEntity>> addMission(MissionEntity mission) async {
    if (await networkInfo.isConnected) {
      try {
        final model = MissionModel(
          id: mission.id,
          worldId: mission.worldId,
          title: mission.title,
          badgeName: mission.badgeName,
          starsReward: mission.starsReward,
          orderIndex: mission.orderIndex,
        );
        final result = await remoteDataSource.addMission(model);
        final current = await localDataSource.getCachedMissions(mission.worldId);
        current.add(result);
        await localDataSource.cacheMissions(mission.worldId, current);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<StoryEntity>>> getStories(String missionId, {bool forceRefresh = false}) async {
    final cachedStories = await localDataSource.getCachedStories(missionId);
    if (!forceRefresh && cachedStories.isNotEmpty) {
      unawaited(_refreshStories(missionId));
      return Right(cachedStories);
    }
    if (!await networkInfo.isConnected) {
      if (cachedStories.isNotEmpty) return Right(cachedStories);
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا توجد قصص محفوظة'));
    }
    try {
      final stories = await remoteDataSource.getStories(missionId).timeout(const Duration(seconds: 4));
      await localDataSource.cacheStories(missionId, stories);
      return Right(stories);
    } catch (e) {
      if (cachedStories.isNotEmpty) return Right(cachedStories);
      return const Left(ServerFailure('تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.'));
    }
  }

  Future<void> _refreshStories(String missionId) async {
    if (!await networkInfo.isConnected) return;
    try {
      final stories = await remoteDataSource.getStories(missionId).timeout(const Duration(seconds: 6));
      await localDataSource.cacheStories(missionId, stories);
      for (final story in stories) {
        resourceManager.cacheCharacterModels(story.characterName, story.timelineData);
        if (story.audioUrl != null && story.audioUrl!.isNotEmpty) {
          resourceManager.downloadAndCacheInBackground(story.audioUrl!, folder: 'audio');
        }
        if (story.imageUrl.isNotEmpty) {
          resourceManager.downloadAndCacheInBackground(story.imageUrl, folder: 'images');
        }
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, StoryEntity>> addStory(StoryEntity story, {File? audioFile, File? characterFile}) async {
    if (await networkInfo.isConnected) {
      try {
        final model = StoryModel.fromEntity(story);
        final result = await remoteDataSource.addStory(model, audioFile: audioFile, characterFile: characterFile);
        final current = await localDataSource.getCachedStories(story.missionId);
        current.add(result);
        await localDataSource.cacheStories(story.missionId, current);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getQuestions(String missionId, {bool forceRefresh = false}) async {
    final cachedQuestions = await localDataSource.getCachedQuestions(missionId);
    if (!forceRefresh && cachedQuestions.isNotEmpty) {
      unawaited(_refreshQuestions(missionId));
      return Right(cachedQuestions);
    }
    if (!await networkInfo.isConnected) {
      if (cachedQuestions.isNotEmpty) return Right(cachedQuestions);
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا توجد أسئلة محفوظة'));
    }
    try {
      final questions = await remoteDataSource.getQuestions(missionId).timeout(const Duration(seconds: 4));
      await localDataSource.cacheQuestions(missionId, questions);
      return Right(questions);
    } catch (e) {
      if (cachedQuestions.isNotEmpty) return Right(cachedQuestions);
      return const Left(ServerFailure('تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.'));
    }
  }

  Future<void> _refreshQuestions(String missionId) async {
    if (!await networkInfo.isConnected) return;
    try {
      final questions = await remoteDataSource.getQuestions(missionId).timeout(const Duration(seconds: 6));
      await localDataSource.cacheQuestions(missionId, questions);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, QuestionEntity>> addQuestion(QuestionEntity question) async {
    try {
      final questionModel = QuestionModel(
        id: question.id,
        missionId: question.missionId,
        questionText: question.questionText,
        options: question.options,
        correctAnswerIndex: question.correctAnswerIndex,
      );
      final addedQuestion = await remoteDataSource.addQuestion(questionModel);
      final current = await localDataSource.getCachedQuestions(question.missionId);
      current.add(addedQuestion);
      await localDataSource.cacheQuestions(question.missionId, current);
      return Right(addedQuestion);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> completeMission(String missionId, String childId) async {
    try {
      // 1. Find mission details for badge & stars reward from local cache
      final allMissions = await localDataSource.getAllCachedMissions();
      MissionModel? matchedMission;
      for (var m in allMissions) {
        if (m.id == missionId) {
          matchedMission = m;
          break;
        }
      }

      // 2. Save locally immediately so child progress is updated with 0 latency
      await localDataSource.saveLocalCompletedMission(
        childId: childId,
        missionId: missionId,
        missionTitle: matchedMission?.title,
        badgeName: matchedMission?.badgeName,
        starsReward: matchedMission?.starsReward,
      );

      // 3. Sync to Supabase in background if connected, otherwise queue for later
      if (await networkInfo.isConnected) {
        remoteDataSource.completeMission(missionId, childId).catchError((_) async {
          await localDataSource.addPendingCompletion(childId, missionId);
        });
      } else {
        await localDataSource.addPendingCompletion(childId, missionId);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<ChildProgressEntity>>> getCompletedMissions(String childId) async {
    final cachedProgress = await localDataSource.getCachedChildProgress(childId);
    if (cachedProgress.isNotEmpty) {
      unawaited(_refreshProgress(childId));
      return Right(cachedProgress);
    }
    if (!await networkInfo.isConnected) return Right(cachedProgress);
    try {
      final progressList = await remoteDataSource
          .getCompletedMissions(childId)
          .timeout(const Duration(seconds: 4));
      await localDataSource.cacheChildProgress(childId, progressList);
      return Right(progressList);
    } catch (_) {
      return Right(cachedProgress);
    }
  }

  Future<void> _refreshProgress(String childId) async {
    if (!await networkInfo.isConnected) return;
    try {
      final progressList = await remoteDataSource
          .getCompletedMissions(childId)
          .timeout(const Duration(seconds: 6));
      final local = await localDataSource.getCachedChildProgress(childId);
      final remoteIds = progressList.map((item) => item.missionId).toSet();
      final kept = local.where((item) => !remoteIds.contains(item.missionId));
      await localDataSource.cacheChildProgress(childId, [
        ...progressList,
        ...kept,
      ]);
    } catch (_) {}
  }

  @override
  Future<Either<Failure, WorldEntity>> updateWorld(WorldEntity world) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateWorld(WorldModel.fromEntity(world));
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorld(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteWorld(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, MissionEntity>> updateMission(MissionEntity mission) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateMission(MissionModel.fromEntity(mission));
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMission(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteMission(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, StoryEntity>> updateStory(StoryEntity story, {File? audioFile, File? characterFile}) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateStory(
          StoryModel.fromEntity(story),
          audioFile: audioFile,
          characterFile: characterFile,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteStory(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, QuestionEntity>> updateQuestion(QuestionEntity question) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateQuestion(QuestionModel.fromEntity(question));
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteQuestion(id);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(userMessage(e)));
      }
    } else {
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت'));
    }
  }
}
