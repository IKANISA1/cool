import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/core/usecases/usecase.dart';
import 'package:ridelink/features/auth/domain/entities/user_entity.dart';
import 'package:ridelink/features/auth/domain/repositories/auth_repository.dart';
import 'package:ridelink/features/auth/domain/usecases/get_current_user.dart';
import 'package:ridelink/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:ridelink/features/auth/domain/usecases/sign_out.dart';
import 'package:ridelink/features/auth/presentation/bloc/auth_bloc.dart';

// Mock classes
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockSignInAnonymouslyUseCase extends Mock implements SignInAnonymouslyUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockSignOutUseCase mockSignOut;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockSignInAnonymouslyUseCase mockSignInAnonymously;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockSignOut = MockSignOutUseCase();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockSignInAnonymously = MockSignInAnonymouslyUseCase();
    mockAuthRepository = MockAuthRepository();

    // Stub the auth state stream
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream<UserEntity?>.empty());

    authBloc = AuthBloc(
      signOut: mockSignOut,
      getCurrentUser: mockGetCurrentUser,
      signInAnonymously: mockSignInAnonymously,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthState.initial()', () {
      expect(authBloc.state, equals(AuthState.initial()));
      expect(authBloc.state.isAuthenticated, false);
      expect(authBloc.state.isLoading, false);
    });

    group('AuthCheckRequested', () {
      final testUser = UserEntity(
        id: 'test-user-id',
        phone: '+250788000001',
        name: 'Test User',
        createdAt: DateTime(2026, 1, 1),
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when user exists',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.step, 'step', AuthFlowStep.authenticated)
              .having((s) => s.user, 'user', testUser)
              .having((s) => s.isLoading, 'isLoading', false),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'triggers anonymous sign-in when no user exists',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => null);
          when(() => mockSignInAnonymously(const NoParams()))
              .thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          // Loading state from sign-in
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUser()).called(1);
          verify(() => mockSignInAnonymously(const NoParams())).called(1);
        },
      );
    });

    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, initial] when sign out succeeds',
        build: () {
          when(() => mockSignOut())
              .thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          AuthState.initial(),
        ],
        verify: (_) {
          verify(() => mockSignOut()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when sign out fails',
        build: () {
          when(() => mockSignOut()).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Sign out failed')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.error, 'error', 'Sign out failed'),
        ],
      );
    });

    group('AuthSignInAnonymouslyRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading] when sign in starts (state update comes from stream)',
        build: () {
          when(() => mockSignInAnonymously(const NoParams()))
              .thenAnswer((_) async => const Right(unit));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInAnonymouslyRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
        ],
        verify: (_) {
          verify(() => mockSignInAnonymously(const NoParams())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when sign in fails',
        build: () {
          when(() => mockSignInAnonymously(const NoParams())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Network error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSignInAnonymouslyRequested()),
        expect: () => [
          isA<AuthState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AuthState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.error, 'error', 'Network error'),
        ],
      );
    });
  });

  group('AuthState', () {
    test('isAuthenticated returns true when user is not empty', () {
      final user = UserEntity(
        id: 'test-id',
        phone: '+250788000001',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
      );
      final state = AuthState(user: user);
      expect(state.isAuthenticated, true);
    });

    test('isAuthenticated returns false when user is null', () {
      const state = AuthState();
      expect(state.isAuthenticated, false);
    });

    test('needsProfileSetup returns true when profile incomplete', () {
      final user = UserEntity(
        id: 'test-id',
        phone: '+250788000001',
        // name is null, so hasCompletedProfile = false
        createdAt: DateTime(2026, 1, 1),
      );
      final state = AuthState(user: user);
      expect(state.needsProfileSetup, true);
    });

    test('copyWithLoading sets loading true and clears error', () {
      const state = AuthState(error: 'some error');
      final loading = state.copyWithLoading();
      expect(loading.isLoading, true);
      expect(loading.error, isNull);
    });

    test('copyWithError sets loading false and adds error', () {
      const state = AuthState(isLoading: true);
      final error = state.copyWithError('test error');
      expect(error.isLoading, false);
      expect(error.error, 'test error');
    });
  });
}
