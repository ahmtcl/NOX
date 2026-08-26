import 'package:flutter_test/flutter_test.dart';
import 'package:nox/features/discovery/domain/public_profile.dart';
import 'package:nox/features/profile/domain/user_profile.dart';

void main() {
  test('private profile maps only approved discovery fields', () {
    final privateProfile = UserProfile(
      uid: 'u1',
      birthDate: DateTime(1999, 8, 26),
      city: 'Ankara',
      personalityTraits: const ['curious'],
      personalAnswer: 'A private answer',
    );
    final data = PublicProfile.fromPrivateProfile(privateProfile).toFirestore();
    expect(data['uid'], 'u1');
    expect(data['city'], 'Ankara');
    expect(data.containsKey('birthDate'), isFalse);
    expect(data.containsKey('email'), isFalse);
    expect(data.containsKey('personalAnswer'), isFalse);
  });

  test('missing optional public fields remain absent after serialization', () {
    final data = const PublicProfile(uid: 'u1').toFirestore();
    expect(data, {'uid': 'u1', 'discoveryEnabled': true});
  });
}
