/// The user's profile as stored in Cloud Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// One user profile, matching the Firestore document fields.
class UserProfile {
  /// The user's unique Firebase UID.
  final String uid;

  /// User's full name, shown in the dashboard greeting.
  final String fullName;

  /// User's age in years (optional).
  final int? age;

  /// User's gender (optional).
  final String? gender;

  /// User's height in cm (optional).
  final double? height;

  /// User's weight in kg (optional).
  final double? weight;

  /// Diabetes type, e.g. Type 1 (optional).
  final String? diabetesType;

  /// User's email from their auth account.
  final String email;

  /// Emergency contact name (for the SOS sheet).
  final String? emergencyContactName;

  /// Emergency contact phone number (for the SOS sheet).
  final String? emergencyContactNumber;

  /// When the profile was created (optional).
  final DateTime? createdAt;

  /// When the profile was last updated (optional).
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

  /// Turns the profile into a map for saving in Firestore.
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

  /// Builds a UserProfile from a Firestore map.
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
