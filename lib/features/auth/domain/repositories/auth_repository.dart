import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/child_profile_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, ChildProfileEntity>> registerChild({
    required String name,
    required int age,
    required String avatarUrl,
  });

  Future<Either<Failure, UserEntity>> registerParent({
    required String email,
    required String password,
    required String childCode,
  });

  Future<Either<Failure, UserEntity>> loginAdmin({
    required String email,
    required String password,
  });
}
