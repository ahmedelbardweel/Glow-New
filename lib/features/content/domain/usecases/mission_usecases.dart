import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mission_entity.dart';
import '../entities/child_progress_entity.dart';
import '../repositories/content_repository.dart';

class GetMissionsUseCase implements UseCase<List<MissionEntity>, String> {
  final ContentRepository repository;

  GetMissionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MissionEntity>>> call(String worldId) async {
    return await repository.getMissions(worldId);
  }
}

class AddMissionUseCase implements UseCase<MissionEntity, MissionEntity> {
  final ContentRepository repository;

  AddMissionUseCase(this.repository);

  @override
  Future<Either<Failure, MissionEntity>> call(MissionEntity params) {
    return repository.addMission(params);
  }
}

class UpdateMissionUseCase implements UseCase<MissionEntity, MissionEntity> {
  final ContentRepository repository;

  UpdateMissionUseCase(this.repository);

  @override
  Future<Either<Failure, MissionEntity>> call(MissionEntity params) {
    return repository.updateMission(params);
  }
}

class DeleteMissionUseCase implements UseCase<void, String> {
  final ContentRepository repository;

  DeleteMissionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteMission(params);
  }
}

class CompleteMissionParams {
  final String missionId;
  final String childId;

  CompleteMissionParams(this.missionId, this.childId);
}

class CompleteMissionUseCase implements UseCase<void, CompleteMissionParams> {
  final ContentRepository repository;

  CompleteMissionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteMissionParams params) async {
    return await repository.completeMission(params.missionId, params.childId);
  }
}

class GetCompletedMissionsUseCase implements UseCase<List<ChildProgressEntity>, String> {
  final ContentRepository repository;

  GetCompletedMissionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChildProgressEntity>>> call(String childId) async {
    return await repository.getCompletedMissions(childId);
  }
}
