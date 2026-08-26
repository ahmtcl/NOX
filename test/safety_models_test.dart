import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/safety/domain/safety_models.dart';

void main() {
  test('blocked user has deterministic id and safe serialization', () {
    const block = BlockedUser(blockerUid: 'a', blockedUid: 'b');
    expect(block.id, 'a_b');
    expect(block.toFirestore(), {'blockerUid': 'a', 'blockedUid': 'b'});
  });
  test('reports serialize stable reason and reject self reports', () {
    const report = UserReport(
        reporterUid: 'a', reportedUid: 'b', reason: ReportReason.harassment);
    expect(report.toFirestore()['reason'], 'harassment');
    expect(report.isValid, isTrue);
    expect(
        const UserReport(
                reporterUid: 'a', reportedUid: 'a', reason: ReportReason.other)
            .isValid,
        isFalse);
  });
}
