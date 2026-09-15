import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/world_entity.dart';
import '../repositories/content_repository.dart';

class GetWorldsParams {
  final bool forceRefresh;
  GetWorldsParams({this.forceRefresh = false});
}

class GetWorldsUseCase implements UseCase<List<WorldEntity>, GetWorldsParams> {
  final ContentRepository repository;

  GetWorldsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorldEntity>>> call(GetWorldsParams params) async {
    return await repository.getWorlds(forceRefresh: params.forceRefresh);
  }
}

class AddWorldUseCase implements UseCase<WorldEntity, WorldEntity> {
  final ContentRepository repository;

  AddWorldUseCase(this.repository);

  @override
  Future<Either<Failure, WorldEntity>> call(WorldEntity params) {
    return repository.addWorld(params);
  }
}

class UpdateWorldUseCase implements UseCase<WorldEntity, WorldEntity> {
  final ContentRepository repository;

  UpdateWorldUseCase(this.repository);

  @override
  Future<Either<Failure, WorldEntity>> call(WorldEntity params) {
    return repository.updateWorld(params);
  }
}

class DeleteWorldUseCase implements UseCase<void, String> {
  final ContentRepository repository;

  DeleteWorldUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteWorld(params);
  }
}
