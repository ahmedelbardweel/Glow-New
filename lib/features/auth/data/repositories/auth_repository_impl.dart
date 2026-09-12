import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
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
    if (await networkInfo.isConnected) {
      try {
        final childProfile = await remoteDataSource.registerChild(
          name: name,
          age: age,
          avatarUrl: avatarUrl,
        );
        // Cache locally for offline use
        await localDataSource.cacheChild(childProfile);
        return Right(childProfile);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Offline fallback
      final cachedChild = await localDataSource.getLastChild();
      if (cachedChild != null) {
        return Right(cachedChild);
      }
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerParent({
    required String email,
    required String password,
    required String childCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.registerParent(
          email: email,
          password: password,
          childCode: childCode,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Offline fallback
      final cachedUser = await localDataSource.getLastUser();
      if (cachedUser != null && cachedUser.email == email && cachedUser.role == 'parent') {
        return Right(cachedUser);
      }
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginAdmin({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.loginAdmin(
          email: email,
          password: password,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Offline fallback for admin login
      final cachedUser = await localDataSource.getLastUser();
      if (cachedUser != null && cachedUser.email == email && cachedUser.role == 'admin') {
        return Right(cachedUser);
      }
      return const Left(ServerFailure('لا يوجد اتصال بالإنترنت، ولم نجد بيانات سابقة للدخول'));
    }
  }
}
