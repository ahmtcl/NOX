sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});
  final String message;
  final Object? cause;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([Object? cause])
      : super('Bir sorun oluştu. Lütfen tekrar deneyin.', cause: cause);
}
