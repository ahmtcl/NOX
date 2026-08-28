import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../safety/application/safety_controller.dart';
import '../data/firestore_match_repository.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) =>
    FirestoreMatchRepository(safety: ref.read(safetyRepositoryProvider)));

final matchControllerProvider =
    AsyncNotifierProvider<MatchController, List<NoxMatch>>(MatchController.new);

class MatchController extends AsyncNotifier<List<NoxMatch>> {
  @override
  Future<List<NoxMatch>> build() => _load();

  Future<List<NoxMatch>> _load() {
    final uid = ref.read(authControllerProvider).user?.id;
    return uid == null
        ? Future.value([])
        : ref.read(matchRepositoryProvider).getMatches(uid);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
