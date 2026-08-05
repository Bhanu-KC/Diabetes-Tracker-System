/// Repository for medication data.
///
/// The repository is a middle layer between the database and the screens:
/// it creates the Floor database once, exposes simple CRUD methods, and
/// hides the DAO details from the UI. It communicates with the local
/// FloorDB (SQLite) only - there is no network call. Used by the
/// medication dashboard, medication details, Add Medication and the home
/// dashboard (medication reminder card).

library;

import 'dart:async';
import '../daos/medication_dao.dart';
import '../database.dart';
import '../entities/medication_entity.dart';

/// Singleton repository providing medication CRUD methods to screens.
class MedicationRepository {
  /// Private constructor: screens must use [getInstance] instead.
  MedicationRepository._(this._dao);

  final MedicationDao _dao;

  static MedicationRepository? _instance;

  /// Returns the shared repository instance, opening the database once.
  ///
  /// The first call builds the FloorDB database; later calls reuse the
  /// same instance so the database is not reopened on every screen.
  static Future<MedicationRepository> getInstance() async {
    _instance ??= MedicationRepository._(
      (await AppDatabase.getInstance()).medicationDao,
    );
    return _instance!;
  }

  /// Live stream of all medications (newest first).
  /// Screens subscribe to this to update automatically on changes.
  Stream<List<MedicationEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all medications (newest first).
  Future<List<MedicationEntity>> getAll() => _dao.getAllRecords();

  /// Returns a single medication by [id], or null if not found.
  Future<MedicationEntity?> getById(int id) => _dao.getRecordById(id);

  /// Saves a new medication (returns the new id).
  Future<int> add(MedicationEntity record) => _dao.insertRecord(record);

  /// Updates an existing medication (returns rows changed).
  Future<int> update(MedicationEntity record) => _dao.updateRecord(record);

  /// Deletes a medication (returns rows removed).
  Future<int> delete(MedicationEntity record) => _dao.deleteRecord(record);
}
