import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { active }

class NoxMatch {
  const NoxMatch(
      {required this.userAUid,
      required this.userBUid,
      this.status = MatchStatus.active,
      this.createdAt,
      this.updatedAt})
      : assert(userAUid != userBUid && userAUid != '' && userBUid != '');
  final String userAUid, userBUid;
  final MatchStatus status;
  final DateTime? createdAt, updatedAt;
  String get matchId => idFor(userAUid, userBUid);
  static String idFor(String a, String b) {
    if (a.isEmpty || b.isEmpty || a == b)
      throw ArgumentError('invalid match users');
    final users = [a, b]..sort();
    return '${users[0]}_${users[1]}';
  }

  Map<String, Object?> toFirestore() =>
      {'userAUid': userAUid, 'userBUid': userBUid, 'status': status.name};
  factory NoxMatch.fromFirestore(Map<String, dynamic> data) => NoxMatch(
      userAUid: data['userAUid'] as String,
      userBUid: data['userBUid'] as String,
      status: MatchStatus.values.byName(data['status'] as String),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null);
}
