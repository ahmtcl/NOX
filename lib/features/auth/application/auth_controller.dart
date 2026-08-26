import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AuthUser?>? _subscription;

  @override
  AuthState build() {
    _subscription = ref.read(authRepositoryProvider).authStateChanges().listen(
          _setUser,
          onError: (_, __) => state = const AuthState.error('genericError'),
        );
    ref.onDispose(() => _subscription?.cancel());
    return const AuthState.loading();
  }

  void _setUser(AuthUser? user) {
    state = user == null
        ? const AuthState.unauthenticated()
        : user.emailVerified
            ? AuthState.authenticated(user)
            : AuthState.verificationRequired(user);
  }

  Future<void> signIn(String email, String password) => _perform(
        () => ref.read(authRepositoryProvider).signInWithEmail(email, password),
      );
  Future<void> register(String email, String password) => _perform(
        () =>
            ref.read(authRepositoryProvider).registerWithEmail(email, password),
      );
  Future<void> resetPassword(String email) => _perform(
        () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
      );
  Future<void> resendVerification() => _perform(
        () => ref.read(authRepositoryProvider).sendEmailVerification(),
      );
  Future<void> signInWithGoogle() =>
      _perform(() => ref.read(authRepositoryProvider).signInWithGoogle());
  Future<void> signInWithApple() =>
      _perform(() => ref.read(authRepositoryProvider).signInWithApple());
  Future<void> signOut() =>
      _perform(() => ref.read(authRepositoryProvider).signOut());

  Future<void> checkVerification() async {
    state = const AuthState.loading();
    try {
      _setUser(await ref.read(authRepositoryProvider).reloadCurrentUser());
    } on AuthFailure catch (error) {
      state = AuthState.error(error.code);
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AuthState.loading();
    try {
      await action();
    } on AuthFailure catch (error) {
      state = AuthState.error(error.code);
    }
  }
}
