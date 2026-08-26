import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_setup_draft.dart';

class UserMetadata {
  const UserMetadata({
    required this.uid,
    this.email,
    this.onboardingCompleted,
    this.profileCompleted,
    this.emailVerified,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? email;
  final bool? onboardingCompleted;
  final bool? profileCompleted;
  final bool? emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toFirestore() => {
        'uid': uid,
        if (email != null) 'email': email,
        if (onboardingCompleted != null)
          'onboardingCompleted': onboardingCompleted,
        if (profileCompleted != null) 'profileCompleted': profileCompleted,
        if (emailVerified != null) 'emailVerified': emailVerified,
      };

  factory UserMetadata.fromFirestore(Map<String, dynamic> data) => UserMetadata(
        uid: data['uid'] as String,
        email: data['email'] as String?,
        onboardingCompleted: data['onboardingCompleted'] as bool?,
        profileCompleted: data['profileCompleted'] as bool?,
        emailVerified: data['emailVerified'] as bool?,
        createdAt: _date(data['createdAt']),
        updatedAt: _date(data['updatedAt']),
      );
}

class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.bio,
    this.birthDate,
    this.age,
    this.city,
    this.photoUrls,
    this.personalityTraits,
    this.freeTimePreferences,
    this.attractionPreferences,
    this.datePreferences,
    this.conversationStyles,
    this.lifeGoals,
    this.weekendStyles,
    this.musicPreferences,
    this.travelStyles,
    this.connectionValues,
    this.personalAnswer,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? displayName, bio, city, personalAnswer;
  final DateTime? birthDate, createdAt, updatedAt;
  final int? age;
  final List<String>? photoUrls,
      personalityTraits,
      freeTimePreferences,
      attractionPreferences,
      datePreferences,
      conversationStyles,
      lifeGoals,
      weekendStyles,
      musicPreferences,
      travelStyles,
      connectionValues;

  factory UserProfile.fromSetupDraft(String uid, ProfileSetupDraft draft) =>
      UserProfile(
        uid: uid,
        personalityTraits: _choices(draft, ProfileQuestion.personality),
        freeTimePreferences: _choices(draft, ProfileQuestion.freeEvening),
        attractionPreferences: _choices(draft, ProfileQuestion.attraction),
        datePreferences: _choices(draft, ProfileQuestion.firstDate),
        conversationStyles: _choices(draft, ProfileQuestion.conversation),
        lifeGoals: _choices(draft, ProfileQuestion.lifeGoals),
        weekendStyles: _choices(draft, ProfileQuestion.weekend),
        musicPreferences: _choices(draft, ProfileQuestion.music),
        travelStyles: _choices(draft, ProfileQuestion.travel),
        connectionValues: _choices(draft, ProfileQuestion.connection),
        personalAnswer: draft.personalAnswer.trim().isEmpty
            ? null
            : draft.personalAnswer.trim(),
      );

  Map<String, Object?> toFirestore() => {
        'uid': uid,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
        if (age != null) 'age': age,
        if (city != null) 'city': city,
        if (photoUrls != null) 'photoUrls': photoUrls,
        if (personalityTraits != null) 'personalityTraits': personalityTraits,
        if (freeTimePreferences != null)
          'freeTimePreferences': freeTimePreferences,
        if (attractionPreferences != null)
          'attractionPreferences': attractionPreferences,
        if (datePreferences != null) 'datePreferences': datePreferences,
        if (conversationStyles != null)
          'conversationStyles': conversationStyles,
        if (lifeGoals != null) 'lifeGoals': lifeGoals,
        if (weekendStyles != null) 'weekendStyles': weekendStyles,
        if (musicPreferences != null) 'musicPreferences': musicPreferences,
        if (travelStyles != null) 'travelStyles': travelStyles,
        if (connectionValues != null) 'connectionValues': connectionValues,
        if (personalAnswer != null) 'personalAnswer': personalAnswer,
      };

  factory UserProfile.fromFirestore(Map<String, dynamic> data) => UserProfile(
        uid: data['uid'] as String,
        displayName: data['displayName'] as String?,
        bio: data['bio'] as String?,
        birthDate: _date(data['birthDate']),
        age: data['age'] as int?,
        city: data['city'] as String?,
        photoUrls: _strings(data['photoUrls']),
        personalityTraits: _strings(data['personalityTraits']),
        freeTimePreferences: _strings(data['freeTimePreferences']),
        attractionPreferences: _strings(data['attractionPreferences']),
        datePreferences: _strings(data['datePreferences']),
        conversationStyles: _strings(data['conversationStyles']),
        lifeGoals: _strings(data['lifeGoals']),
        weekendStyles: _strings(data['weekendStyles']),
        musicPreferences: _strings(data['musicPreferences']),
        travelStyles: _strings(data['travelStyles']),
        connectionValues: _strings(data['connectionValues']),
        personalAnswer: data['personalAnswer'] as String?,
        createdAt: _date(data['createdAt']),
        updatedAt: _date(data['updatedAt']),
      );
}

class UserPreferences {
  const UserPreferences(
      {required this.uid,
      this.preferredAgeRange,
      this.preferredDistanceKm,
      this.preferredGender,
      this.relationshipIntent,
      this.discoveryEnabled});
  final String uid;
  final List<int>? preferredAgeRange;
  final int? preferredDistanceKm;
  final String? preferredGender, relationshipIntent;
  final bool? discoveryEnabled;
  Map<String, Object?> toFirestore() => {
        'uid': uid,
        if (preferredAgeRange != null) 'preferredAgeRange': preferredAgeRange,
        if (preferredDistanceKm != null)
          'preferredDistanceKm': preferredDistanceKm,
        if (preferredGender != null) 'preferredGender': preferredGender,
        if (relationshipIntent != null)
          'relationshipIntent': relationshipIntent,
        if (discoveryEnabled != null) 'discoveryEnabled': discoveryEnabled
      };
  factory UserPreferences.fromFirestore(Map<String, dynamic> data) =>
      UserPreferences(
          uid: data['uid'] as String,
          preferredAgeRange:
              (data['preferredAgeRange'] as List?)?.whereType<int>().toList(),
          preferredDistanceKm: data['preferredDistanceKm'] as int?,
          preferredGender: data['preferredGender'] as String?,
          relationshipIntent: data['relationshipIntent'] as String?,
          discoveryEnabled: data['discoveryEnabled'] as bool?);
}

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;
List<String>? _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : null;
List<String>? _choices(ProfileSetupDraft draft, ProfileQuestion question) {
  final choices = draft.choicesFor(question);
  if (choices.isEmpty) return null;
  return choices.toList()..sort();
}
