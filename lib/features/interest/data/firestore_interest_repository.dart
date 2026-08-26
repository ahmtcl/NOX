import 'package:cloud_firestore/cloud_firestore.dart';
import '../../safety/domain/safety_repository.dart';
import '../domain/interaction.dart';
import '../domain/interest_repository.dart';

class FirestoreInterestRepository implements InterestRepository {
  FirestoreInterestRepository(
      {FirebaseFirestore? firestore, SafetyRepository? safety})
      : _db = firestore ?? FirebaseFirestore.instance,
        _safety = safety;
  final FirebaseFirestore _db;
  final SafetyRepository? _safety;
  @override
  Future<void> submit(Interaction interaction) async {
    if (!interaction.isValid) throw const InterestFailure('invalid');
    if (_safety != null &&
        await _safety.isBlocked(interaction.fromUid, interaction.toUid))
      throw const InterestFailure('blocked');
    try {
      await _db.collection('interactions').doc(interaction.id).set({
        ...interaction.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw InterestFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }

  @override
  Future<Set<String>> getOutgoingIds(String uid) async => (await _db
          .collection('interactions')
          .where('fromUid', isEqualTo: uid)
          .get())
      .docs
      .map((d) => d.data()['toUid'] as String)
      .toSet();
  @override
  Future<int> incomingCount(String uid, InteractionType type) async =>
      (await _db
              .collection('interactions')
              .where('toUid', isEqualTo: uid)
              .where('type', isEqualTo: type.name)
              .count()
              .get())
          .count ??
      0;
}
