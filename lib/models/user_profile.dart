/// Model representing a user's profile document in Cloud Firestore.
///
/// This model holds all personal details of the logged-in user (name, age,
/// diabetes type, emergency contact, etc.). It exists so screens can work
/// with a typed object instead of raw Firestore maps. The profile is used
/// by the Profile and Edit Profile screens, and to greet the user on the
/// dashboard. It also stores emergency contact details shown in the SOS
/// emergency sheet.

library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one user profile as stored in the `users` Firestore
/// collection. Fields match the keys used in Firestore documents.
class UserProfile {
  /// Firebase Authentication UID - unique identifier of the user.
  final String uid;

  /// Full name of the user, shown in the dashboard greeting.
  final String fullName;

  /// Age of the user in years (optional).
  final int? age;

  /// Gender of the user - one of Male, Female or Other (optional).
  final String? gender;

  /// Height of the user in centimetres (optional).
  final double? height;

  /// Weight of the user in kilograms (optional).
  final double? weight;

  /// Diabetes type - e.g. Type 1, Type 2, Prediabetes (optional).
  final String? diabetesType;

  /// Email address of the user, copied from the auth account.
  final String email;

  /// Name of the person to call in an emergency (used by the SOS sheet).
  final String? emergencyContactName;

  /// Phone number of the emergency contact (used by the SOS sheet).
  final String? emergencyContactNumber;

  /// Timestamp of when the profile was first created (optional).
  final DateTime? createdAt;

  /// Timestamp of the last time the profile was updated (optional).
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.diabetesType,
    required this.email,
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.createdAt,
    this.updatedAt,
  });

  /// Converts this profile into a map so it can be saved in Firestore.
  ///
  /// Firestore only accepts maps, so [toMap] is called when writing the
  /// profile with `set()` or `update()`.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'diabetesType': diabetesType,
      'email': email,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Creates a [UserProfile] from a Firestore document map.
  ///
  /// This factory is used when reading a profile from Firestore.
  /// Firestore timestamps are converted to normal [DateTime] values.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      age: (map['age'] as num?)?.toInt(),
      gender: map['gender'] as String?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      diabetesType: map['diabetesType'] as String?,
      email: map['email'] ?? '',
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactNumber: map['emergencyContactNumber'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
