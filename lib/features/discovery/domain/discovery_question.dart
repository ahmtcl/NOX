enum DiscoveryQuestionCategory { character, lifestyle, connection }

class DiscoveryQuestion {
  factory DiscoveryQuestion({
    required String id,
    required String text,
    required DiscoveryQuestionCategory category,
  }) {
    final normalizedText = text.trim();
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (normalizedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    return DiscoveryQuestion._(id: id, text: normalizedText, category: category);
  }

  const DiscoveryQuestion._({
    required this.id,
    required this.text,
    required this.category,
  });

  final String id;
  final String text;
  final DiscoveryQuestionCategory category;
}
