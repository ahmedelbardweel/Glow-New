import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginAdminUseCase implements UseCase<UserEntity, LoginAdminParams> {
  final AuthRepository repository;

  LoginAdminUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginAdminParams params) {
    return repository.loginAdmin(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginAdminParams {
  final String email;
  final String password;

  LoginAdminParams({
    required this.email,
    required this.password,
  });
}
