import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/auth_user.dart';
import '../../discovery/domain/public_profile.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_setup_draft.dart';
import '../domain/user_profile.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<void> createOrUpdateProfile(
      AuthUser user, ProfileSetupDraft draft) async {
    final userRef = _firestore.collection('users').doc(user.id);
    final profileRef = _firestore.collection('profiles').doc(user.id);
    final publicProfileRef =
        _firestore.collection('publicProfiles').doc(user.id);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshots = await Future.wait(
            [transaction.get(userRef), transaction.get(profileRef)]);
        final metadata = UserMetadata(
                uid: user.id,
                email: user.email,
                emailVerified: user.emailVerified,
                profileCompleted: true)
            .toFirestore();
        final privateProfile = UserProfile.fromSetupDraft(user.id, draft);
        final profile = privateProfile.toFirestore();
        final publicProfile =
            PublicProfile.fromPrivateProfile(privateProfile).toFirestore();
        final now = FieldValue.serverTimestamp();
        metadata['updatedAt'] = now;
        profile['updatedAt'] = now;
        publicProfile['updatedAt'] = now;
        if (!snapshots[0].exists) metadata['createdAt'] = now;
        if (!snapshots[1].exists) profile['createdAt'] = now;
        transaction.set(userRef, metadata, SetOptions(merge: true));
        transaction.set(profileRef, profile, SetOptions(merge: true));
        transaction.set(
            publicProfileRef, publicProfile, SetOptions(merge: true));
      });
    } on FirebaseException catch (error) {
      throw ProfileFailure(
          error.code == 'unavailable' ? 'networkError' : 'saveFailed');
    } on Exception {
      throw const ProfileFailure('saveFailed');
    }
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final snapshot = await _firestore.collection('profiles').doc(uid).get();
      return snapshot.exists
          ? UserProfile.fromFirestore(snapshot.data()!)
          : null;
    } on FirebaseException catch (error) {
      throw ProfileFailure(
          error.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _firestore.collection('profiles').doc(profile.uid).set(
          {...profile.toFirestore(), 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw ProfileFailure(
          error.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }

  @override
  Future<UserPreferences?> getPreferences(String uid) async {
    try {
      final snapshot =
          await _firestore.collection('preferences').doc(uid).get();
      return snapshot.exists
          ? UserPreferences.fromFirestore(snapshot.data()!)
          : null;
    } on FirebaseException catch (error) {
      throw ProfileFailure(
          error.code == 'unavailable' ? 'networkError' : 'loadFailed');
    }
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    try {
      await _firestore.collection('preferences').doc(preferences.uid).set({
        ...preferences.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw ProfileFailure(
          error.code == 'unavailable' ? 'networkError' : 'saveFailed');
    }
  }
}
