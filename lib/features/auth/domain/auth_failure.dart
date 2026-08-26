class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final String code;
}

String mapFirebaseAuthErrorCode(String code) => switch (code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' =>
        'invalidCredentials',
      'email-already-in-use' => 'emailAlreadyInUse',
      'weak-password' => 'weakPassword',
      'invalid-email' => 'invalidEmail',
      'too-many-requests' => 'tooManyRequests',
      'network-request-failed' => 'networkError',
      'user-disabled' => 'userDisabled',
      'sign_in_canceled' => 'signInCancelled',
      _ => 'genericError',
    };
