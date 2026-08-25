import 'package:cloud_firestore/cloud_firestore.dart';

/// Only public profiles are read from a client. Private data stays private.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get publicProfiles =>
      _firestore.collection('public_profiles');
  Future<DocumentSnapshot<Map<String, dynamic>>> getPublicProfile(String uid) =>
      publicProfiles.doc(uid).get();
}
