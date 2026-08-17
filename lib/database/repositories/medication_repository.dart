// Middle layer between the database and the screens for medication data.

import 'dart:async';
import '../daos/medication_dao.dart';
import '../database.dart';
import '../entities/medication_entity.dart';

/// Singleton with medication CRUD methods for screens.
class MedicationRepository {
  /// Private, use [getInstance] instead.
  MedicationRepository._(this._dao);

  final MedicationDao _dao;

  static MedicationRepository? _instance;

  /// Returns the shared instance, opening the database only once.
  static Future<MedicationRepository> getInstance() async {
    _instance ??= MedicationRepository._(
      (await AppDatabase.getInstance()).medicationDao,
    );
    return _instance!;
  }

  /// Live stream of all medications, newest first.
  Stream<List<MedicationEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all medications.
  Future<List<MedicationEntity>> getAll() => _dao.getAllRecords();

  /// Gets one medication by id, or null if not found.
  Future<MedicationEntity?> getById(int id) => _dao.getRecordById(id);

  /// Adds a new medication, returns the new id.
  Future<int> add(MedicationEntity record) => _dao.insertRecord(record);

  /// Updates a medication, returns rows changed.
  Future<int> update(MedicationEntity record) => _dao.updateRecord(record);

  /// Deletes a medication, returns rows removed.
  Future<int> delete(MedicationEntity record) => _dao.deleteRecord(record);
}
