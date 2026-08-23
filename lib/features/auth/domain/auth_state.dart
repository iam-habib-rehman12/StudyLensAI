import 'app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.checking() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
