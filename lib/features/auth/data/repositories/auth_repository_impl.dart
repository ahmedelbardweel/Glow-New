import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/network/network_info.dart';
import '../child_account_service.dart';
import '../../domain/entities/child_profile_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChildProfileEntity>> registerChild({
    required String name,
    required int age,
    required String avatarUrl,
  }) async {
    try {
      final childProfile = await GetIt.instance<ChildAccountService>().register(
        name: name,
        age: age,
        avatarUrl: avatarUrl,
      );
      return Right(childProfile);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerParent({
    required String email,
    required String password,
    required String childCode,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(ServerFailure('إنشاء الحساب يحتاج اتصالاً بالإنترنت.'));
    }
    try {
      final user = await remoteDataSource.registerParent(
        email: email,
        password: password,
        childCode: childCode,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginParent({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(ServerFailure('دخول ولي الأمر يحتاج اتصالاً بالإنترنت.'));
    }
    try {
      final user = await remoteDataSource.loginParent(
        email: email,
        password: password,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginAdmin({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        ServerFailure('دخول الإدارة يحتاج اتصالاً بالإنترنت.'),
      );
    }
    try {
      final user = await remoteDataSource.loginAdmin(
        email: email,
        password: password,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(userMessage(e)));
    }
  }
}
