import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  harassment,
  inappropriateMessages,
  fakeProfile,
  sexualContent,
  threat,
  scam,
  inappropriatePhoto,
  spam,
  other
}

class BlockedUser {
  const BlockedUser(
      {required this.blockerUid, required this.blockedUid, this.createdAt});
  final String blockerUid, blockedUid;
  final DateTime? createdAt;
  String get id => '${blockerUid}_$blockedUid';
  Map<String, Object?> toFirestore() =>
      {'blockerUid': blockerUid, 'blockedUid': blockedUid};
  factory BlockedUser.fromFirestore(Map<String, dynamic> data) => BlockedUser(
      blockerUid: data['blockerUid'] as String,
      blockedUid: data['blockedUid'] as String,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null);
}

class UserReport {
  const UserReport(
      {required this.reporterUid,
      required this.reportedUid,
      required this.reason,
      this.details});
  final String reporterUid, reportedUid;
  final ReportReason reason;
  final String? details;
  bool get isValid =>
      reporterUid.isNotEmpty &&
      reportedUid.isNotEmpty &&
      reporterUid != reportedUid;
  Map<String, Object?> toFirestore() => {
        'reporterUid': reporterUid,
        'reportedUid': reportedUid,
        'reason': reason.name,
        'status': 'pending',
        if (details?.trim().isNotEmpty ?? false) 'details': details!.trim()
      };
}
