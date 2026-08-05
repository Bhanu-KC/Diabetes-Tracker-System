/// Firestore (cloud database) service for the user profile.
///
/// This service handles everything stored in Cloud Firestore, currently
/// the user's profile document inside the `users` collection. Health data
/// (blood sugar, meals, medication, insulin) lives in the local FloorDB
/// database instead of the cloud. The profile is written during
/// registration and read/updated from the Profile and Edit Profile
/// screens; the dashboard also reads it for the greeting, and the SOS
/// emergency sheet reads the emergency contact.

library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Service that reads and writes user profiles in Cloud Firestore.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convenience reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Creates a new profile document for a user.
  ///
  /// Called right after registration. The document is stored under the
  /// user's UID so each account owns exactly one profile. Timestamps are
  /// set by the Firestore server.
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
  ///
  /// Called when the user saves the Edit Profile form. Only profile
  /// fields are updated; the UID and email remain unchanged.
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

  /// Fetches the profile of a user by their [uid].
  ///
  /// Returns null if the profile does not exist yet. Called by the
  /// Profile/Edit Profile screens and by the emergency SOS sheet.
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
