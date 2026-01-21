import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> initializeTransaction({
    required String email,
    required double amount,
  }) async {
    try {
      final accessCode = await remoteDataSource.initializeTransaction(email: email, amount: amount);
      return Right(accessCode);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentTransaction>> processPayment({
    required BuildContext context,
    required double amount,
    required String email,
    required String accessCode,
    required String reference,
  }) async {
    try {
      final transaction = await remoteDataSource.chargeCard(
        context: context,
        accessCode: accessCode,
        reference: reference,
        email: email,
        amount: amount,
      );
      return Right(transaction);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
