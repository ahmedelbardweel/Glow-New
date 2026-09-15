import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/story_entity.dart';
import '../repositories/content_repository.dart';

class GetStoriesParams {
  final String missionId;
  final bool forceRefresh;
  GetStoriesParams(this.missionId, {this.forceRefresh = false});
}

class GetStoriesUseCase implements UseCase<List<StoryEntity>, GetStoriesParams> {
  final ContentRepository repository;

  GetStoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<StoryEntity>>> call(GetStoriesParams params) async {
    return await repository.getStories(params.missionId, forceRefresh: params.forceRefresh);
  }
}

class AddStoryParams {
  final StoryEntity story;
  final File? audioFile;
  final File? characterFile;

  AddStoryParams(this.story, {this.audioFile, this.characterFile});
}

class AddStoryUseCase implements UseCase<StoryEntity, AddStoryParams> {
  final ContentRepository repository;

  AddStoryUseCase(this.repository);

  @override
  Future<Either<Failure, StoryEntity>> call(AddStoryParams params) async {
    return await repository.addStory(params.story, audioFile: params.audioFile, characterFile: params.characterFile);
  }
}

class UpdateStoryUseCase implements UseCase<StoryEntity, AddStoryParams> {
  final ContentRepository repository;

  UpdateStoryUseCase(this.repository);

  @override
  Future<Either<Failure, StoryEntity>> call(AddStoryParams params) async {
    return await repository.updateStory(params.story, audioFile: params.audioFile, characterFile: params.characterFile);
  }
}

class DeleteStoryUseCase implements UseCase<void, String> {
  final ContentRepository repository;

  DeleteStoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteStory(params);
  }
}
