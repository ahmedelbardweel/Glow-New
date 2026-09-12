import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/child_profile_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterChildUseCase implements UseCase<ChildProfileEntity, RegisterChildParams> {
  final AuthRepository repository;

  RegisterChildUseCase(this.repository);

  @override
  Future<Either<Failure, ChildProfileEntity>> call(RegisterChildParams params) {
    return repository.registerChild(
      name: params.name,
      age: params.age,
      avatarUrl: params.avatarUrl,
    );
  }
}

class RegisterChildParams {
  final String name;
  final int age;
  final String avatarUrl;

  RegisterChildParams({
    required this.name,
    required this.age,
    required this.avatarUrl,
  });
}
