part of 'auth_bloc.dart';

/// Base class for auth events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current authentication status
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User requested to sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User requested to sign in anonymously
class AuthSignInAnonymouslyRequested extends AuthEvent {
  const AuthSignInAnonymouslyRequested();
}

/// Auth state changed (from stream)
class _AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  const _AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
