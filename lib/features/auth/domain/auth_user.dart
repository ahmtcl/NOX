class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.emailVerified,
  });

  final String id;
  final String? email;
  final bool emailVerified;
}

enum AuthStatus {
  loading,
  unauthenticated,
  verificationRequired,
  authenticated,
  error
}

class AuthState {
  const AuthState({required this.status, this.user, this.errorCode});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(AuthUser user)
      : this(status: AuthStatus.authenticated, user: user);
  const AuthState.verificationRequired(AuthUser user)
      : this(status: AuthStatus.verificationRequired, user: user);
  const AuthState.error(String errorCode)
      : this(status: AuthStatus.error, errorCode: errorCode);

  final AuthStatus status;
  final AuthUser? user;
  final String? errorCode;

  bool get isLoading => status == AuthStatus.loading;
}
