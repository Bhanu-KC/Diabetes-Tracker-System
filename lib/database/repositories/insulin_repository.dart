/// Repository for insulin dose data.
///
/// The repository is a middle layer between the database and the screens:
/// it creates the Floor database once, exposes simple CRUD methods, and
/// hides the DAO details from the UI. It communicates with the local
/// FloorDB (SQLite) only - there is no network call. Used by the insulin
/// screen, Add Insulin, history, reports and home dashboard (insulin
/// reminder card).

library;

import 'dart:async';
import '../daos/insulin_dao.dart';
import '../database.dart';
import '../entities/insulin_entity.dart';

/// Singleton repository providing insulin CRUD methods to screens.
class InsulinRepository {
  /// Private constructor: screens must use [getInstance] instead.
  InsulinRepository._(this._dao);

  final InsulinDao _dao;

  static InsulinRepository? _instance;

  /// Returns the shared repository instance, opening the database once.
  ///
  /// The first call builds the FloorDB database; later calls reuse the
  /// same instance so the database is not reopened on every screen.
  static Future<InsulinRepository> getInstance() async {
    _instance ??= InsulinRepository._(
      (await AppDatabase.getInstance()).insulinDao,
    );
    return _instance!;
  }

  /// Live stream of all insulin records (newest first).
  /// Screens subscribe to this to update automatically on changes.
  Stream<List<InsulinEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all insulin records (newest first).
  Future<List<InsulinEntity>> getAll() => _dao.getAllRecords();

  /// Returns a single insulin record by [id], or null if not found.
  Future<InsulinEntity?> getById(int id) => _dao.getRecordById(id);

  /// Saves a new insulin record (returns the new id).
  Future<int> add(InsulinEntity record) => _dao.insertRecord(record);

  /// Updates an existing insulin record (returns rows changed).
  Future<int> update(InsulinEntity record) => _dao.updateRecord(record);

  /// Deletes an insulin record (returns rows removed).
  Future<int> delete(InsulinEntity record) => _dao.deleteRecord(record);
}
