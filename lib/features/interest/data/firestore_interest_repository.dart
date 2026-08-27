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

  @override
  Future<IncomingInterestSummary> incomingSummary(String uid) async {
    try {
      final blocked =
          _safety == null ? <String>{} : await _safety.getBlockedUserIds(uid);
      final counts = await Future.wait([
        _incomingCountExcludingBlocked(uid, InteractionType.like, blocked),
        _incomingCountExcludingBlocked(
            uid, InteractionType.specialInterest, blocked)
      ]);
      return IncomingInterestSummary(
          likes: counts[0], specialInterests: counts[1]);
    } on FirebaseException catch (e) {
      throw InterestFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  Future<int> _incomingCountExcludingBlocked(
      String uid, InteractionType type, Set<String> blocked) async {
    final query = _db
        .collection('interactions')
        .where('toUid', isEqualTo: uid)
        .where('type', isEqualTo: type.name);
    final total = (await query.count().get()).count ?? 0;
    if (blocked.isEmpty || total == 0) return total;
    var excluded = 0;
    final ids = blocked.toList();
    for (var index = 0; index < ids.length; index += 10) {
      final batch = ids.sublist(index, (index + 10).clamp(0, ids.length));
      excluded +=
          (await query.where('fromUid', whereIn: batch).count().get()).count ??
              0;
    }
    return (total - excluded).clamp(0, total).toInt();
  }

  @override
  Future<IncomingInteractionPage> getIncomingInteractions(String uid,
      {Object? cursor, int pageSize = 10}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('interactions')
          .where('toUid', isEqualTo: uid)
          .where('type', whereIn: [
            InteractionType.like.name,
            InteractionType.specialInterest.name
          ])
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
        query = query.startAfterDocument(cursor);
      }
      final blocked =
          _safety == null ? <String>{} : await _safety.getBlockedUserIds(uid);
      final result = await query.get();
      final items = <Interaction>[];
      for (final doc in result.docs) {
        final data = doc.data();
        final fromUid = data['fromUid'];
        if (fromUid is! String || fromUid == uid || blocked.contains(fromUid))
          continue;
        final type = data['type'] == InteractionType.specialInterest.name
            ? InteractionType.specialInterest
            : InteractionType.like;
        final reason = SpecialInterestReason.values
            .cast<SpecialInterestReason?>()
            .firstWhere((value) => value?.name == data['specialInterestReason'],
                orElse: () => null);
        items.add(Interaction(
            fromUid: fromUid,
            toUid: uid,
            type: type,
            reason: type == InteractionType.specialInterest ? reason : null));
      }
      return IncomingInteractionPage(
          items: items,
          cursor: result.docs.length == pageSize ? result.docs.last : null);
    } on FirebaseException catch (e) {
      throw InterestFailure(
          e.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }
}
