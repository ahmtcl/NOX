import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/discovery_repository.dart';
import '../domain/public_profile.dart';

class FirestoreDiscoveryRepository implements DiscoveryRepository {
  FirestoreDiscoveryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<PublicProfile?> getPublicProfile(String uid) async {
    try {
      final doc = await _firestore.collection('publicProfiles').doc(uid).get();
      return doc.exists ? PublicProfile.fromFirestore(doc.data()!) : null;
    } on FirebaseException catch (e) {
      throw DiscoveryFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<Map<String, PublicProfile>> getPublicProfilesByIds(
      Set<String> uids) async {
    if (uids.isEmpty) return {};
    try {
      final docs = await _firestore
          .collection('publicProfiles')
          .where(FieldPath.documentId, whereIn: uids.take(10).toList())
          .get();
      return {
        for (final doc in docs.docs)
          doc.id: PublicProfile.fromFirestore(doc.data())
      };
    } on FirebaseException catch (e) {
      throw DiscoveryFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<DiscoveryPage> getDiscoveryProfiles(
      {required String currentUid, Object? cursor, int pageSize = 10}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('publicProfiles')
          .where('discoveryEnabled', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(pageSize);
      if (cursor is DocumentSnapshot<Map<String, dynamic>>)
        query = query.startAfterDocument(cursor);
      final result = await query.get();
      final profiles = result.docs
          .map((doc) => PublicProfile.fromFirestore(doc.data()))
          .where((profile) => profile.uid != currentUid)
          .toList();
      return DiscoveryPage(
          profiles: profiles,
          cursor: result.docs.length == pageSize ? result.docs.last : null);
    } on FirebaseException catch (e) {
      throw DiscoveryFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<void> createOrUpdatePublicProfile(PublicProfile profile) async {
    try {
      await _firestore.collection('publicProfiles').doc(profile.uid).set(
          {...profile.toFirestore(), 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DiscoveryFailure(
          e.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }
}
