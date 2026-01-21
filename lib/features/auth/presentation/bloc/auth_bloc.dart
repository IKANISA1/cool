import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:ridelink/core/usecases/usecase.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Authentication bloc
///
/// Manages the authentication state using anonymous Supabase auth.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static final _log = Logger('AuthBloc');

  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  final SignInAnonymouslyUseCase _signInAnonymously;
  final AuthRepository _authRepository;

  StreamSubscription<UserEntity?>? _authStateSubscription;

  AuthBloc({
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
    required SignInAnonymouslyUseCase signInAnonymously,
    required AuthRepository authRepository,
  })  : _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _signInAnonymously = signInAnonymously,
        _authRepository = authRepository,
        super(AuthState.initial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthSignInAnonymouslyRequested>(_onSignInAnonymouslyRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthStateChanged(user)),
    );
  }

  /// Handle auth check request
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.fine('Checking auth status');
    emit(state.copyWithLoading());

    final user = await _getCurrentUser();

    if (user != null && user.isNotEmpty) {
      emit(state.copyWith(
        step: AuthFlowStep.authenticated,
        user: user,
        isLoading: false,
      ));
    } else {
      // Auto-login anonymously if no user found
      add(const AuthSignInAnonymouslyRequested());
    }
  }

  /// Handle sign out request
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('Signing out');
    emit(state.copyWithLoading());

    final result = await _signOut();

    result.fold(
      (failure) => emit(state.copyWithError(failure.message)),
      (_) {
        emit(AuthState.initial());
      },
    );
  }

  /// Handle request to sign in anonymously
  Future<void> _onSignInAnonymouslyRequested(
    AuthSignInAnonymouslyRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log.info('Signing in anonymously');
    emit(state.copyWithLoading());

    final result = await _signInAnonymously(const NoParams());

    result.fold(
      (failure) {
        _log.warning('Anonymous sign-in failed: ${failure.message}');
        emit(state.copyWithError(failure.message));
      },
      (_) {
        _log.info('Anonymous sign-in successful');
        // Auth state stream will trigger update
      },
    );
  }

  /// Handle auth state change from stream
  void _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null && event.user!.isNotEmpty) {
      emit(state.copyWith(
        step: AuthFlowStep.authenticated,
        user: event.user,
        isLoading: false,
      ));
    } else if (state.step == AuthFlowStep.authenticated) {
      // User signed out elsewhere
      emit(AuthState.initial());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
