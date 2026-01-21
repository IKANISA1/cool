import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<ResultType, Params> {
  Future<Either<Failure, ResultType>> call(Params params);
}

class NoParams {
  const NoParams();
  
  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}
