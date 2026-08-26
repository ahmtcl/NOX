enum InteractionType { pass, like, specialInterest }

enum SpecialInterestReason {
  personality,
  humor,
  music,
  lifestyle,
  profileEnergy,
  overall
}

class Interaction {
  const Interaction(
      {required this.fromUid,
      required this.toUid,
      required this.type,
      this.reason});
  final String fromUid, toUid;
  final InteractionType type;
  final SpecialInterestReason? reason;
  String get id => '${fromUid}_$toUid';
  bool get isValid =>
      fromUid.isNotEmpty &&
      toUid.isNotEmpty &&
      fromUid != toUid &&
      (type == InteractionType.specialInterest
          ? reason != null
          : reason == null);
  Map<String, Object?> toFirestore() => {
        'fromUid': fromUid,
        'toUid': toUid,
        'type': type.name,
        if (reason != null) 'specialInterestReason': reason!.name
      };
}
