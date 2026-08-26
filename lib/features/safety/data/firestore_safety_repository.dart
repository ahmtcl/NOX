import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/safety_models.dart';
import '../domain/safety_repository.dart';

class FirestoreSafetyRepository implements SafetyRepository {
  FirestoreSafetyRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  @override
  Future<void> blockUser(BlockedUser block) =>
      _guard(() => _db.collection('blocks').doc(block.id).set(
          {...block.toFirestore(), 'createdAt': FieldValue.serverTimestamp()}));
  @override
  Future<void> unblockUser(BlockedUser block) =>
      _guard(() => _db.collection('blocks').doc(block.id).delete());
  @override
  Future<Set<String>> getBlockedUserIds(String uid) async {
    try {
      final docs = await _db
          .collection('blocks')
          .where('blockerUid', isEqualTo: uid)
          .get();
      return docs.docs.map((d) => d.data()['blockedUid'] as String).toSet();
    } on FirebaseException catch (e) {
      throw SafetyFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<bool> isBlocked(String a, String b) async =>
      (await _db.collection('blocks').doc('${a}_$b').get()).exists;
  @override
  Future<void> reportUser(UserReport report, {bool alsoBlock = false}) async {
    if (!report.isValid) throw const SafetyFailure('invalidReport');
    await _guard(() async {
      final batch = _db.batch();
      batch.set(_db.collection('reports').doc(),
          {...report.toFirestore(), 'createdAt': FieldValue.serverTimestamp()});
      if (alsoBlock) {
        final block = BlockedUser(
            blockerUid: report.reporterUid, blockedUid: report.reportedUid);
        batch.set(_db.collection('blocks').doc(block.id), {
          ...block.toFirestore(),
          'createdAt': FieldValue.serverTimestamp()
        });
      }
      await batch.commit();
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw SafetyFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }
}
