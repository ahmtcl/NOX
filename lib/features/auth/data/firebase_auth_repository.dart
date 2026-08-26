import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(
        () => _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> registerWithEmail(String email, String password) async {
    await _guard(
      () => _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    await sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(
        () => _firebaseAuth.sendPasswordResetEmail(email: email.trim()),
      );

  @override
  Future<void> sendEmailVerification() => _guard(
        () async {
          final user = _firebaseAuth.currentUser;
          if (user == null) throw const AuthFailure('genericError');
          await user.sendEmailVerification();
        },
      );

  @override
  Future<AuthUser?> reloadCurrentUser() => _guard(
        () async {
          final user = _firebaseAuth.currentUser;
          await user?.reload();
          return _mapUser(_firebaseAuth.currentUser);
        },
      );

  @override
  Future<void> signOut() => _guard(() => _firebaseAuth.signOut());

  @override
  Future<void> signInWithGoogle() => _guard(() async {
        final account = await _googleSignIn.signIn();
        if (account == null) throw const AuthFailure('signInCancelled');
        final authentication = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: authentication.accessToken,
          idToken: authentication.idToken,
        );
        await _firebaseAuth.signInWithCredential(credential);
      });

  @override
  Future<void> signInWithApple() => _guard(() async {
        final rawNonce = _nonce();
        final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        final idToken = appleCredential.identityToken;
        if (idToken == null) throw const AuthFailure('genericError');
        final credential = OAuthProvider('apple.com').credential(
          idToken: idToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );
        await _firebaseAuth.signInWithCredential(credential);
      });

  AuthUser? _mapUser(User? user) => user == null
      ? null
      : AuthUser(
          id: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(mapFirebaseAuthErrorCode(error.code));
    } on Exception {
      throw const AuthFailure('genericError');
    }
  }

  String _nonce() {
    const characters =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        32, (_) => characters[random.nextInt(characters.length)]).join();
  }
}
