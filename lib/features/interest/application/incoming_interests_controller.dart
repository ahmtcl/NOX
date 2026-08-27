import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../discovery/application/discovery_controller.dart';
import '../../discovery/domain/public_profile.dart';
import '../domain/interaction.dart';
import 'interest_controller.dart';

class IncomingInterest {
  const IncomingInterest({required this.interaction, required this.profile});
  final Interaction interaction;
  final PublicProfile profile;
}

class IncomingInterestsState {
  const IncomingInterestsState(
      {this.items = const [], this.loadingMore = false, this.hasMore = false});
  final List<IncomingInterest> items;
  final bool loadingMore, hasMore;
}

final incomingInterestsControllerProvider =
    AsyncNotifierProvider<IncomingInterestsController, IncomingInterestsState>(
        IncomingInterestsController.new);

class IncomingInterestsController
    extends AsyncNotifier<IncomingInterestsState> {
  Object? _cursor;
  @override
  Future<IncomingInterestsState> build() => _load();
  Future<IncomingInterestsState> _load({bool more = false}) async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return const IncomingInterestsState();
    final page = await ref
        .read(interestRepositoryProvider)
        .getIncomingInteractions(uid, cursor: more ? _cursor : null);
    final profiles = await ref
        .read(discoveryRepositoryProvider)
        .getPublicProfilesByIds(page.items.map((item) => item.fromUid).toSet());
    _cursor = page.cursor;
    final items = page.items
        .where((item) => profiles.containsKey(item.fromUid))
        .map((item) => IncomingInterest(
            interaction: item, profile: profiles[item.fromUid]!))
        .toList();
    return IncomingInterestsState(items: items, hasMore: page.hasMore);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> loadMore() async {
    if (_cursor == null || state.valueOrNull?.loadingMore == true) return;
    state = AsyncData(IncomingInterestsState(
        items: state.valueOrNull?.items ?? [],
        loadingMore: true,
        hasMore: true));
    try {
      final next = await _load(more: true);
      state = AsyncData(IncomingInterestsState(
          items: [...(state.valueOrNull?.items ?? []), ...next.items],
          hasMore: next.hasMore));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }
}
