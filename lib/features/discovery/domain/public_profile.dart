import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/user_profile.dart';

class PublicProfile {
  const PublicProfile(
      {required this.uid,
      this.displayName,
      this.age,
      this.city,
      this.bio,
      this.photoUrls,
      this.personalityTraits,
      this.freeTimePreferences,
      this.datePreferences,
      this.conversationStyles,
      this.lifeGoals,
      this.musicPreferences,
      this.travelStyles,
      this.connectionValues,
      this.discoveryEnabled = true,
      this.updatedAt});
  final String uid;
  final String? displayName, city, bio;
  final int? age;
  final List<String>? photoUrls,
      personalityTraits,
      freeTimePreferences,
      datePreferences,
      conversationStyles,
      lifeGoals,
      musicPreferences,
      travelStyles,
      connectionValues;
  final bool discoveryEnabled;
  final DateTime? updatedAt;
  factory PublicProfile.fromPrivateProfile(UserProfile profile,
          {bool discoveryEnabled = true}) =>
      PublicProfile(
          uid: profile.uid,
          displayName: profile.displayName,
          age: profile.birthDate == null
              ? profile.age
              : _age(profile.birthDate!),
          city: profile.city,
          bio: profile.bio ?? profile.personalAnswer,
          photoUrls: profile.photoUrls,
          personalityTraits: profile.personalityTraits,
          freeTimePreferences: profile.freeTimePreferences,
          datePreferences: profile.datePreferences,
          conversationStyles: profile.conversationStyles,
          lifeGoals: profile.lifeGoals,
          musicPreferences: profile.musicPreferences,
          travelStyles: profile.travelStyles,
          connectionValues: profile.connectionValues,
          discoveryEnabled: discoveryEnabled);
  Map<String, Object?> toFirestore() => {
        'uid': uid,
        if (displayName != null) 'displayName': displayName,
        if (age != null) 'age': age,
        if (city != null) 'city': city,
        if (bio != null) 'bio': bio,
        if (photoUrls != null) 'photoUrls': photoUrls,
        if (personalityTraits != null) 'personalityTraits': personalityTraits,
        if (freeTimePreferences != null)
          'freeTimePreferences': freeTimePreferences,
        if (datePreferences != null) 'datePreferences': datePreferences,
        if (conversationStyles != null)
          'conversationStyles': conversationStyles,
        if (lifeGoals != null) 'lifeGoals': lifeGoals,
        if (musicPreferences != null) 'musicPreferences': musicPreferences,
        if (travelStyles != null) 'travelStyles': travelStyles,
        if (connectionValues != null) 'connectionValues': connectionValues,
        'discoveryEnabled': discoveryEnabled
      };
  factory PublicProfile.fromFirestore(Map<String, dynamic> data) =>
      PublicProfile(
          uid: data['uid'] as String,
          displayName: data['displayName'] as String?,
          age: data['age'] as int?,
          city: data['city'] as String?,
          bio: data['bio'] as String?,
          photoUrls: _strings(data['photoUrls']),
          personalityTraits: _strings(data['personalityTraits']),
          freeTimePreferences: _strings(data['freeTimePreferences']),
          datePreferences: _strings(data['datePreferences']),
          conversationStyles: _strings(data['conversationStyles']),
          lifeGoals: _strings(data['lifeGoals']),
          musicPreferences: _strings(data['musicPreferences']),
          travelStyles: _strings(data['travelStyles']),
          connectionValues: _strings(data['connectionValues']),
          discoveryEnabled: data['discoveryEnabled'] as bool? ?? false,
          updatedAt: data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : null);
}

int _age(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) age--;
  return age;
}

List<String>? _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : null;
