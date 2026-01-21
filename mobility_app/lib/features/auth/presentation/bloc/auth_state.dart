part of 'auth_bloc.dart';

/// Enum representing the current auth flow step
enum AuthFlowStep {
  initial,
  authenticated,
}

/// Auth state
class AuthState extends Equatable {
  final AuthFlowStep step;
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.step = AuthFlowStep.initial,
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// Check if user is authenticated
  bool get isAuthenticated => user != null && user!.isNotEmpty;

  /// Check if user needs to complete profile
  bool get needsProfileSetup => isAuthenticated && !user!.hasCompletedProfile;

  /// Create initial state
  factory AuthState.initial() => const AuthState();

  /// Create loading state
  AuthState copyWithLoading() => copyWith(
        isLoading: true,
        error: null,
      );

  /// Create error state
  AuthState copyWithError(String message) => copyWith(
        isLoading: false,
        error: message,
      );

  /// Copy with new values
  AuthState copyWith({
    AuthFlowStep? step,
    UserEntity? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      step: step ?? this.step,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        step,
        user,
        isLoading,
        error,
      ];
}
