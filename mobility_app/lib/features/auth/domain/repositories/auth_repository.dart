import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Auth repository interface (domain layer contract)
///
/// Defines the contract for authentication operations.
/// Uses Supabase anonymous authentication.
abstract class AuthRepository {
  /// Sign out the current user
  ///
  /// Returns [Unit] on success or [Failure] on error.
  Future<Either<Failure, Unit>> signOut();

  /// Get the currently authenticated user
  ///
  /// Returns [UserEntity] if authenticated, null otherwise.
  Future<UserEntity?> getCurrentUser();

  /// Stream of auth state changes
  ///
  /// Emits [UserEntity] when user signs in/out.
  Stream<UserEntity?> get authStateChanges;

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Sign in anonymously
  ///
  /// Returns [Unit] on success or [Failure] on error.
  Future<Either<Failure, Unit>> signInAnonymously();
}
