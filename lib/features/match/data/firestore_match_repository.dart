import 'package:cloud_firestore/cloud_firestore.dart';
import '../../interest/domain/interaction.dart';
import '../../safety/domain/safety_repository.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';

class FirestoreMatchRepository implements MatchRepository {
  FirestoreMatchRepository(
      {FirebaseFirestore? firestore, SafetyRepository? safety})
      : _db = firestore ?? FirebaseFirestore.instance,
        _safety = safety;
  final FirebaseFirestore _db;
  final SafetyRepository? _safety;
  @override
  Future<NoxMatch?> getMatch(String a, String b) async {
    try {
      final d = await _db.collection('matches').doc(NoxMatch.idFor(a, b)).get();
      return d.exists ? NoxMatch.fromFirestore(d.data()!) : null;
    } on FirebaseException catch (e) {
      throw MatchFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<NoxMatch?> createMatchIfNeeded(String a, String b) async {
    if (a.isEmpty || b.isEmpty || a == b) return null;
    if (_safety != null &&
        ((await _safety.isBlocked(a, b)) || (await _safety.isBlocked(b, a))))
      return null;
    final id = NoxMatch.idFor(a, b);
    try {
      return await _db.runTransaction((tx) async {
        final ref = _db.collection('matches').doc(id);
        final existing = await tx.get(ref);
        if (existing.exists) return NoxMatch.fromFirestore(existing.data()!);
        final ab = await tx.get(_db.collection('interactions').doc('${a}_$b'));
        final ba = await tx.get(_db.collection('interactions').doc('${b}_$a'));
        bool valid(DocumentSnapshot<Map<String, dynamic>> d) =>
            d.exists &&
            [InteractionType.like.name, InteractionType.specialInterest.name]
                .contains(d.data()?['type']);
        if (!valid(ab) || !valid(ba)) return null;
        final users = [a, b]..sort();
        final match = NoxMatch(userAUid: users[0], userBUid: users[1]);
        tx.set(ref, {
          ...match.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp()
        });
        return match;
      });
    } on FirebaseException catch (e) {
      throw MatchFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }

  @override
  Future<List<NoxMatch>> getMatches(String uid) async {
    try {
      final results = await Future.wait([
        _db.collection('matches').where('userAUid', isEqualTo: uid).get(),
        _db.collection('matches').where('userBUid', isEqualTo: uid).get()
      ]);
      return results
          .expand((q) => q.docs)
          .map((d) => NoxMatch.fromFirestore(d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw MatchFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }
}
