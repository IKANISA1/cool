import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository]
///
/// Orchestrates data sources and handles error mapping.
class AuthRepositoryImpl implements AuthRepository {
  static final _log = Logger('AuthRepository');

  final AuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e, stackTrace) {
      _log.severe('Unexpected error signing out', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges;
  }

  @override
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null && user.isNotEmpty;
  }

  @override
  Future<Either<Failure, Unit>> signInAnonymously() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.signInAnonymously();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e, stackTrace) {
      _log.severe('Unexpected error signing in anonymously', e, stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
