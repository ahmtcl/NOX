import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/firestore_discovery_repository.dart';
import '../domain/discovery_repository.dart';
import '../domain/public_profile.dart';

final discoveryRepositoryProvider =
    Provider<DiscoveryRepository>((ref) => FirestoreDiscoveryRepository());
final discoveryControllerProvider =
    AsyncNotifierProvider<DiscoveryController, List<PublicProfile>>(
        DiscoveryController.new);

class DiscoveryController extends AsyncNotifier<List<PublicProfile>> {
  Object? _cursor;
  var _loadingMore = false;
  @override
  Future<List<PublicProfile>> build() => _load();
  Future<List<PublicProfile>> _load() async {
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return [];
    final page = await ref
        .read(discoveryRepositoryProvider)
        .getDiscoveryProfiles(currentUid: uid);
    _cursor = page.cursor;
    return page.profiles;
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> loadMore() async {
    if (_loadingMore || _cursor == null) return;
    final uid = ref.read(authControllerProvider).user?.id;
    if (uid == null) return;
    _loadingMore = true;
    try {
      final page = await ref
          .read(discoveryRepositoryProvider)
          .getDiscoveryProfiles(currentUid: uid, cursor: _cursor);
      _cursor = page.cursor;
      state = AsyncData([...state.valueOrNull ?? [], ...page.profiles]);
    } finally {
      _loadingMore = false;
    }
  }
}
