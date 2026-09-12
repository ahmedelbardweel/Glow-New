import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParentUseCase implements UseCase<UserEntity, RegisterParentParams> {
  final AuthRepository repository;

  RegisterParentUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParentParams params) {
    return repository.registerParent(
      email: params.email,
      password: params.password,
      childCode: params.childCode,
    );
  }
}

class RegisterParentParams {
  final String email;
  final String password;
  final String childCode;

  RegisterParentParams({
    required this.email,
    required this.password,
    required this.childCode,
  });
}
