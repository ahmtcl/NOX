import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../safety/application/safety_controller.dart';
import '../data/firestore_match_repository.dart';
import '../domain/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) =>
    FirestoreMatchRepository(safety: ref.read(safetyRepositoryProvider)));
