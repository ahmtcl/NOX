import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/firestore_safety_repository.dart';
import '../domain/safety_models.dart';
import '../domain/safety_repository.dart';

final safetyRepositoryProvider =
    Provider<SafetyRepository>((ref) => FirestoreSafetyRepository());
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) => ref
    .read(safetyRepositoryProvider)
    .getBlockedUserIds(ref.watch(_safetyUidProvider) ?? ''));
final _safetyUidProvider = Provider<String?>((ref) => null);
final safetyControllerProvider =
    NotifierProvider<SafetyController, AsyncValue<void>>(SafetyController.new);

class SafetyController extends Notifier<AsyncValue<void>> {
  var _busy = false;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> block(BlockedUser value) async {
    if (_busy) return false;
    _busy = true;
    state = const AsyncLoading();
    try {
      await ref.read(safetyRepositoryProvider).blockUser(value);
      state = const AsyncData(null);
      ref.invalidate(blockedUserIdsProvider);
      return true;
    } on SafetyFailure {
      state = const AsyncError(SafetyFailure('saveFailed'), StackTrace.empty);
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<bool> report(UserReport value, {bool alsoBlock = false}) async {
    if (_busy) return false;
    _busy = true;
    state = const AsyncLoading();
    try {
      await ref
          .read(safetyRepositoryProvider)
          .reportUser(value, alsoBlock: alsoBlock);
      state = const AsyncData(null);
      return true;
    } on SafetyFailure {
      state = const AsyncError(SafetyFailure('saveFailed'), StackTrace.empty);
      return false;
    } finally {
      _busy = false;
    }
  }
}
