import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/story_entity.dart';
import '../repositories/content_repository.dart';

class GetStoriesUseCase implements UseCase<List<StoryEntity>, String> {
  final ContentRepository repository;

  GetStoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<StoryEntity>>> call(String missionId) async {
    return await repository.getStories(missionId);
  }
}

class AddStoryParams {
  final StoryEntity story;
  final File? audioFile;

  AddStoryParams(this.story, {this.audioFile});
}

class AddStoryUseCase implements UseCase<StoryEntity, AddStoryParams> {
  final ContentRepository repository;

  AddStoryUseCase(this.repository);

  @override
  Future<Either<Failure, StoryEntity>> call(AddStoryParams params) async {
    return await repository.addStory(params.story, audioFile: params.audioFile);
  }
}
