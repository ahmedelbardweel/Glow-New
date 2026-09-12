import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/world_entity.dart';
import '../repositories/content_repository.dart';

class GetWorldsUseCase implements UseCase<List<WorldEntity>, NoParams> {
  final ContentRepository repository;

  GetWorldsUseCase(this.repository);

  @override
  Future<Either<Failure, List<WorldEntity>>> call(NoParams params) async {
    return await repository.getWorlds();
  }
}

class AddWorldUseCase implements UseCase<WorldEntity, WorldEntity> {
  final ContentRepository repository;

  AddWorldUseCase(this.repository);

  @override
  Future<Either<Failure, WorldEntity>> call(WorldEntity params) async {
    return await repository.addWorld(params);
  }
}
