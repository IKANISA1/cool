import 'package:dartz/dartz.dart';
import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/core/usecases/usecase.dart';
import 'package:ridelink/features/auth/domain/repositories/auth_repository.dart';

class SignInAnonymouslyUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository repository;

  SignInAnonymouslyUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.signInAnonymously();
  }
}
