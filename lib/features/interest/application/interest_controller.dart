import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../safety/application/safety_controller.dart';
import '../data/firestore_interest_repository.dart';
import '../domain/interaction.dart';
import '../domain/interest_repository.dart';

final premiumStateProvider = Provider<bool>((ref) => false);
final interestRepositoryProvider = Provider<InterestRepository>((ref) =>
    FirestoreInterestRepository(safety: ref.read(safetyRepositoryProvider)));
final interestControllerProvider =
    NotifierProvider<InterestController, AsyncValue<void>>(
        InterestController.new);
final incomingInterestSummaryProvider =
    FutureProvider.family<IncomingInterestSummary, String>((ref, uid) =>
        ref.read(interestRepositoryProvider).incomingSummary(uid));

class InterestController extends Notifier<AsyncValue<void>> {
  var _busy = false;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<bool> send(Interaction item) async {
    if (_busy) return false;
    if (item.type == InteractionType.specialInterest &&
        !ref.read(premiumStateProvider)) {
      state = const AsyncError(
          InterestFailure('premiumRequired'), StackTrace.empty);
      return false;
    }
    _busy = true;
    state = const AsyncLoading();
    try {
      await ref.read(interestRepositoryProvider).submit(item);
      state = const AsyncData(null);
      return true;
    } on InterestFailure catch (e) {
      state = AsyncError(e, StackTrace.empty);
      return false;
    } finally {
      _busy = false;
    }
  }
}
