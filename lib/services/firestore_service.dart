// Cloud Firestore service for the user's profile.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Reads and writes user profiles in Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Shortcut to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Creates the user's profile document (stored under their UID).
  Future<void> createUserProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set({
      'uid': profile.uid,
      'fullName': profile.fullName,
      'age': profile.age,
      'gender': profile.gender,
      'height': profile.height,
      'weight': profile.weight,
      'diabetesType': profile.diabetesType,
      'email': profile.email,
      'emergencyContactName': profile.emergencyContactName,
      'emergencyContactNumber': profile.emergencyContactNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates an existing profile document.
  Future<void> updateUserProfile(UserProfile profile) async {
    await _users.doc(profile.uid).update({
      'fullName': profile.fullName,
      'age': profile.age,
      'gender': profile.gender,
      'height': profile.height,
      'weight': profile.weight,
      'diabetesType': profile.diabetesType,
      'emergencyContactName': profile.emergencyContactName,
      'emergencyContactNumber': profile.emergencyContactNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches a user's profile, or null if it doesn't exist yet.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
