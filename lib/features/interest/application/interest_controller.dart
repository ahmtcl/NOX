import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../safety/application/safety_controller.dart';
import '../../match/application/match_controller.dart';
import '../../match/domain/match.dart';
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
    return (await sendWithMatch(item)).sent;
  }

  Future<InteractionSendResult> sendWithMatch(Interaction item) async {
    if (_busy) return const InteractionSendResult();
    if (item.type == InteractionType.specialInterest &&
        !ref.read(premiumStateProvider)) {
      state = const AsyncError(
          InterestFailure('premiumRequired'), StackTrace.empty);
      return const InteractionSendResult();
    }
    var canDetectMatch = item.type == InteractionType.like ||
        item.type == InteractionType.specialInterest;
    var existingMatch = false;
    if (canDetectMatch) {
      try {
        existingMatch = await ref
                .read(matchRepositoryProvider)
                .getMatch(item.fromUid, item.toUid) !=
            null;
      } catch (_) {
        canDetectMatch = false;
      }
    }
    _busy = true;
    state = const AsyncLoading();
    try {
      await ref.read(interestRepositoryProvider).submit(item);
      state = const AsyncData(null);
      if (!canDetectMatch || existingMatch) {
        return const InteractionSendResult(sent: true);
      }
      try {
        final match = await ref
            .read(matchRepositoryProvider)
            .createMatchIfNeeded(item.fromUid, item.toUid);
        return InteractionSendResult(sent: true, createdMatch: match);
      } catch (_) {
        return const InteractionSendResult(sent: true);
      }
    } on InterestFailure catch (e) {
      state = AsyncError(e, StackTrace.empty);
      return const InteractionSendResult();
    } finally {
      _busy = false;
    }
  }
}

class InteractionSendResult {
  const InteractionSendResult({this.sent = false, this.createdMatch});
  final bool sent;
  final NoxMatch? createdMatch;
}
