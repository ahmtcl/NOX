enum ProfileQuestion {
  personality,
  freeEvening,
  attraction,
  firstDate,
  conversation,
  lifeGoals,
  weekend,
  music,
  travel,
  connection,
}

class ProfileChoice {
  const ProfileChoice({required this.id, required this.emoji});

  final String id;
  final String emoji;
}

class ProfileSetupDraft {
  const ProfileSetupDraft({
    this.selections = const {},
    this.personalAnswer = '',
  });

  final Map<ProfileQuestion, Set<String>> selections;
  final String personalAnswer;

  Set<String> choicesFor(ProfileQuestion question) =>
      selections[question] ?? const <String>{};

  ProfileSetupDraft copyWith({
    Map<ProfileQuestion, Set<String>>? selections,
    String? personalAnswer,
  }) =>
      ProfileSetupDraft(
        selections: selections ?? this.selections,
        personalAnswer: personalAnswer ?? this.personalAnswer,
      );

  Map<String, dynamic> toJson() => {
        'selections': {
          for (final entry in selections.entries)
            entry.key.name: entry.value.toList(),
        },
        'personalAnswer': personalAnswer,
      };

  factory ProfileSetupDraft.fromJson(Map<String, dynamic> json) {
    final rawSelections = json['selections'];
    final selections = <ProfileQuestion, Set<String>>{};
    if (rawSelections is Map) {
      for (final entry in rawSelections.entries) {
        final question = ProfileQuestion.values
            .where((item) => item.name == entry.key)
            .firstOrNull;
        if (question != null && entry.value is List) {
          selections[question] = entry.value.whereType<String>().toSet();
        }
      }
    }
    return ProfileSetupDraft(
      selections: selections,
      personalAnswer: json['personalAnswer'] as String? ?? '',
    );
  }
}

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
