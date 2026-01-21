import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implementation of [ProfileRepository]
class ProfileRepositoryImpl implements ProfileRepository {
  static final _log = Logger('ProfileRepository');

  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Profile>> getProfile() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final profile = await remoteDataSource.getProfile();
      return Right(profile);
    } on ServerException catch (e) {
      _log.warning('Server error getting profile: ${e.message}');
      return Left(ServerFailure(message: e.message, code: e.code));
    } on AuthException catch (e) {
      _log.warning('Auth error getting profile: ${e.message}');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _log.severe('Unexpected error getting profile', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> getProfileById(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final profile = await remoteDataSource.getProfileById(userId);
      return Right(profile);
    } on ServerException catch (e) {
      _log.warning('Server error getting profile by ID: ${e.message}');
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.severe('Unexpected error getting profile by ID', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> createProfile({
    required String name,
    required UserRole role,
    required String countryCode,
    List<String> languages = const [],
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final profile = await remoteDataSource.createProfile(
        name: name,
        role: role,
        countryCode: countryCode,
        languages: languages,
        vehicleCategory: vehicleCategory,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );
      return Right(profile);
    } on ServerException catch (e) {
      _log.warning('Server error creating profile: ${e.message}');
      return Left(ServerFailure(message: e.message, code: e.code));
    } on AuthException catch (e) {
      _log.warning('Auth error creating profile: ${e.message}');
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      _log.severe('Unexpected error creating profile', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile({
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final profile = await remoteDataSource.updateProfile(
        name: name,
        role: role,
        countryCode: countryCode,
        languages: languages,
        vehicleCategory: vehicleCategory,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );
      return Right(profile);
    } on ServerException catch (e) {
      _log.warning('Server error updating profile: ${e.message}');
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _log.severe('Unexpected error updating profile', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasProfile() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final exists = await remoteDataSource.hasProfile();
      return Right(exists);
    } catch (e) {
      _log.warning('Error checking profile existence', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(String filePath) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final url = await remoteDataSource.uploadAvatar(filePath);
      return Right(url);
    } on ServerException catch (e) {
      _log.warning('Server error uploading avatar: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      _log.severe('Unexpected error uploading avatar', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
