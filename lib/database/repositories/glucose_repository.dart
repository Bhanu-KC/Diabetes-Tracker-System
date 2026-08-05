/// Repository for blood sugar (glucose) data.
///
/// The repository is a middle layer between the database and the screens:
/// it creates the Floor database once, exposes simple CRUD methods, and
/// hides the DAO details from the UI. It communicates with the local
/// FloorDB (SQLite) only - there is no network call. Used by the home
/// dashboard, history, reports and Add Blood Sugar screens.

library;

import 'dart:async';
import '../daos/glucose_dao.dart';
import '../database.dart';
import '../entities/glucose_entity.dart';

/// Singleton repository providing glucose CRUD methods to screens.
class GlucoseRepository {
  /// Private constructor: screens must use [getInstance] instead.
  GlucoseRepository._(this._dao);

  final GlucoseDao _dao;

  static GlucoseRepository? _instance;

  /// Returns the shared repository instance, opening the database once.
  ///
  /// The first call builds the FloorDB database; later calls reuse the
  /// same instance so the database is not reopened on every screen.
  static Future<GlucoseRepository> getInstance() async {
    _instance ??= GlucoseRepository._(
      (await AppDatabase.getInstance()).glucoseDao,
    );
    return _instance!;
  }

  /// Live stream of all readings (newest first).
  /// Screens subscribe to this to update automatically on changes.
  Stream<List<GlucoseEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all readings (newest first).
  Future<List<GlucoseEntity>> getAll() => _dao.getAllRecords();

  /// Returns a single reading by [id], or null if not found.
  Future<GlucoseEntity?> getById(int id) => _dao.getRecordById(id);

  /// Returns the most recent reading, or null when the table is empty.
  Future<GlucoseEntity?> getLatest() => _dao.getLatestRecord();

  /// Saves a new reading (returns the new id).
  Future<int> add(GlucoseEntity record) => _dao.insertRecord(record);

  /// Updates an existing reading (returns rows changed).
  Future<int> update(GlucoseEntity record) => _dao.updateRecord(record);

  /// Deletes a reading (returns rows removed).
  Future<int> delete(GlucoseEntity record) => _dao.deleteRecord(record);
}
