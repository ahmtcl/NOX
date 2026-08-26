import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/interest/domain/interaction.dart';

void main() {
  test('interaction serializes stable types', () {
    const item = Interaction(
        fromUid: 'a',
        toUid: 'b',
        type: InteractionType.specialInterest,
        reason: SpecialInterestReason.music);
    expect(item.id, 'a_b');
    expect(item.toFirestore()['type'], 'specialInterest');
    expect(item.toFirestore()['specialInterestReason'], 'music');
  });
  test('self and missing special reason are invalid', () {
    expect(
        const Interaction(fromUid: 'a', toUid: 'a', type: InteractionType.like)
            .isValid,
        isFalse);
    expect(
        const Interaction(
                fromUid: 'a', toUid: 'b', type: InteractionType.specialInterest)
            .isValid,
        isFalse);
  });
}
