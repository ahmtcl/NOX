import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/core/localization/app_localizations.dart';
import 'package:nox/features/auth/domain/auth_failure.dart';
import 'package:nox/features/auth/domain/auth_user.dart';

void main() {
  group('Firebase auth error mapping', () {
    const mappings = {
      'invalid-credential': 'invalidCredentials',
      'user-not-found': 'invalidCredentials',
      'wrong-password': 'invalidCredentials',
      'email-already-in-use': 'emailAlreadyInUse',
      'weak-password': 'weakPassword',
      'invalid-email': 'invalidEmail',
      'too-many-requests': 'tooManyRequests',
      'network-request-failed': 'networkError',
      'user-disabled': 'userDisabled',
      'unknown': 'genericError',
    };
    mappings.forEach((firebaseCode, appCode) {
      test('$firebaseCode maps safely', () {
        expect(mapFirebaseAuthErrorCode(firebaseCode), appCode);
      });
    });
  });

  test('auth states model loading and unauthenticated users', () {
    expect(const AuthState.loading().status, AuthStatus.loading);
    expect(
        const AuthState.unauthenticated().status, AuthStatus.unauthenticated);
  });

  test('auth states model authenticated and verification users', () {
    const user = AuthUser(
        id: 'fake-user', email: 'user@example.test', emailVerified: true);
    expect(
        const AuthState.authenticated(user).status, AuthStatus.authenticated);
    expect(const AuthState.verificationRequired(user).status,
        AuthStatus.verificationRequired);
  });

  test('auth error state does not expose Firebase exception text', () {
    expect(const AuthState.error('networkError').errorCode, 'networkError');
  });

  test('Turkish and English auth localization render safe error copy', () {
    expect(AppLocalizations(const Locale('tr')).authError('invalidCredentials'),
        contains('E-posta'));
    expect(AppLocalizations(const Locale('en')).authError('networkError'),
        contains('connection'));
  });
}
