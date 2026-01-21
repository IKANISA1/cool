import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Execute the use case
  Future<Either<Failure, Unit>> call() async {
    return _repository.signOut();
  }
}
