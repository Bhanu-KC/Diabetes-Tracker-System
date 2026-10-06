// Saves records to Firestore as a cloud backup alongside the local database.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../database/repositories/glucose_repository.dart';
import '../database/repositories/medication_repository.dart';
import '../database/repositories/insulin_repository.dart';
import '../database/repositories/meal_repository.dart';
import '../database/entities/glucose_entity.dart';
import '../database/entities/medication_entity.dart';
import '../database/entities/insulin_entity.dart';
import '../database/entities/meal_entity.dart';

// Handles writing all four record types to Firestore.
// Each write is fire-and-forget so the UI stays fast.
class DataSyncService {
  // Gets the Firestore path for the current user's sub-collection.
  static CollectionReference<Map<String, dynamic>> _col(String name) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return FirebaseFirestore.instance.collection('_noop');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(name);
  }

  // ---- Glucose ----

  static void syncGlucose(GlucoseEntity record, {bool delete = false}) {
    final doc = _col('glucose_records').doc('${record.id}');
    if (delete) {
      doc.delete();
      return;
    }
    doc.set({
      'level': record.level,
      'mealContext': record.mealContext,
      'notes': record.notes,
      'timestamp': record.timestamp,
    });
  }

  // ---- Medication ----

  static void syncMedication(MedicationEntity record, {bool delete = false}) {
    final doc = _col('medication_records').doc('${record.id}');
    if (delete) {
      doc.delete();
      return;
    }
    doc.set({
      'name': record.name,
      'dosage': record.dosage,
      'frequency': record.frequency,
      'reminderTime': record.reminderTime,
      'reminderEnabled': record.reminderEnabled,
      'repeatDaily': record.repeatDaily,
      'taken': record.taken,
      'startDate': record.startDate,
      'endDate': record.endDate,
      'notes': record.notes,
    });
  }

  // ---- Insulin ----

  static void syncInsulin(InsulinEntity record, {bool delete = false}) {
    final doc = _col('insulin_records').doc('${record.id}');
    if (delete) {
      doc.delete();
      return;
    }
    doc.set({
      'name': record.name,
      'dose': record.dose,
      'site': record.site,
      'time': record.time,
      'reminderEnabled': record.reminderEnabled,
      'repeatDaily': record.repeatDaily,
      'taken': record.taken,
      'timestamp': record.timestamp,
      'notes': record.notes,
    });
  }

  // ---- Meal ----

  static void syncMeal(MealEntity record, {bool delete = false}) {
    final doc = _col('meal_records').doc('${record.id}');
    if (delete) {
      doc.delete();
      return;
    }
    doc.set({
      'name': record.name,
      'mealType': record.mealType,
      'carbs': record.carbs,
      'calories': record.calories,
      'timestamp': record.timestamp,
      'notes': record.notes,
    });
  }

  // ---- Restore from cloud ----
  //
  // Pulls every record of the user from Firestore back into the local
  // database. Only records that aren't already on the phone get added, so
  // this is safe to run after login or on first launch.

  // Adds any cloud glucose reading not already on the phone.
  static Future<void> restoreGlucose() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('glucose_records')
        .get();
    final repo = await GlucoseRepository.getInstance();
    final local = await repo.getAll();
    final localIds = local.map((r) => r.id).toSet();
    for (final doc in snap.docs) {
      final id = int.tryParse(doc.id);
      if (id != null && localIds.contains(id)) continue; // already here
      final data = doc.data();
      await repo.add(
        GlucoseEntity(
          level: (data['level'] as num).toDouble(),
          mealContext: data['mealContext'] as String,
          notes: (data['notes'] as String?) ?? '',
          timestamp: data['timestamp'] as int,
        ),
      );
    }
  }

  // Adds any cloud medication not already on the phone.
  static Future<void> restoreMedication() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medication_records')
        .get();
    final repo = await MedicationRepository.getInstance();
    final local = await repo.getAll();
    final localIds = local.map((r) => r.id).toSet();
    for (final doc in snap.docs) {
      final id = int.tryParse(doc.id);
      if (id != null && localIds.contains(id)) continue; // already here
      final data = doc.data();
      await repo.add(
        MedicationEntity(
          name: data['name'] as String,
          dosage: data['dosage'] as String,
          frequency: (data['frequency'] as String?) ?? 'Once daily',
          reminderTime: (data['reminderTime'] as String?) ?? '08:00',
          reminderEnabled: (data['reminderEnabled'] as bool?) ?? true,
          repeatDaily: (data['repeatDaily'] as bool?) ?? true,
          taken: (data['taken'] as bool?) ?? false,
          startDate: data['startDate'] as int,
          endDate: data['endDate'] as int,
          notes: (data['notes'] as String?) ?? '',
        ),
      );
    }
  }

  // Adds any cloud insulin record not already on the phone.
  static Future<void> restoreInsulin() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('insulin_records')
        .get();
    final repo = await InsulinRepository.getInstance();
    final local = await repo.getAll();
    final localIds = local.map((r) => r.id).toSet();
    for (final doc in snap.docs) {
      final id = int.tryParse(doc.id);
      if (id != null && localIds.contains(id)) continue; // already here
      final data = doc.data();
      await repo.add(
        InsulinEntity(
          name: data['name'] as String,
          dose: (data['dose'] as num).toDouble(),
          site: (data['site'] as String?) ?? 'Abdomen',
          time: (data['time'] as String?) ?? '08:00',
          reminderEnabled: (data['reminderEnabled'] as bool?) ?? true,
          repeatDaily: (data['repeatDaily'] as bool?) ?? true,
          taken: (data['taken'] as bool?) ?? false,
          timestamp: data['timestamp'] as int,
          notes: (data['notes'] as String?) ?? '',
        ),
      );
    }
  }

  // Adds any cloud meal not already on the phone.
  static Future<void> restoreMeal() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meal_records')
        .get();
    final repo = await MealRepository.getInstance();
    final local = await repo.getAll();
    final localIds = local.map((r) => r.id).toSet();
    for (final doc in snap.docs) {
      final id = int.tryParse(doc.id);
      if (id != null && localIds.contains(id)) continue; // already here
      final data = doc.data();
      await repo.add(
        MealEntity(
          name: data['name'] as String,
          mealType: (data['mealType'] as String?) ?? 'Breakfast',
          carbs: (data['carbs'] as num?)?.toDouble(),
          calories: (data['calories'] as num?)?.toDouble(),
          timestamp: data['timestamp'] as int,
          notes: (data['notes'] as String?) ?? '',
        ),
      );
    }
  }

  // Restores all four record types from the cloud. Fire-and-forget overall.
  static Future<void> restoreAll() async {
    try {
      await Future.wait([
        restoreGlucose(),
        restoreMedication(),
        restoreInsulin(),
        restoreMeal(),
      ]);
    } catch (e) {
      // Just log it - the user still has their local data.
      // ignore: avoid_print
      debugPrint('Cloud restore failed: $e');
    }
  }
}
