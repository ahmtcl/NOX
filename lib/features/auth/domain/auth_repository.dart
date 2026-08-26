import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<AuthUser?> reloadCurrentUser();
  Future<void> signOut();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
}
