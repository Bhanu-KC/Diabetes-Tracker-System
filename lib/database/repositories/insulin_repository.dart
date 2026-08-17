/// Middle layer between the database and the screens for insulin data.
library;

import 'dart:async';
import '../daos/insulin_dao.dart';
import '../database.dart';
import '../entities/insulin_entity.dart';

/// Singleton with insulin CRUD methods for screens.
class InsulinRepository {
  /// Private, use [getInstance] instead.
  InsulinRepository._(this._dao);

  final InsulinDao _dao;

  static InsulinRepository? _instance;

  /// Returns the shared instance, opening the database only once.
  static Future<InsulinRepository> getInstance() async {
    _instance ??= InsulinRepository._(
      (await AppDatabase.getInstance()).insulinDao,
    );
    return _instance!;
  }

  /// Live stream of all insulin records, newest first.
  Stream<List<InsulinEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all insulin records.
  Future<List<InsulinEntity>> getAll() => _dao.getAllRecords();

  /// Gets one insulin record by id, or null if not found.
  Future<InsulinEntity?> getById(int id) => _dao.getRecordById(id);

  /// Adds a new insulin record, returns the new id.
  Future<int> add(InsulinEntity record) => _dao.insertRecord(record);

  /// Updates an insulin record, returns rows changed.
  Future<int> update(InsulinEntity record) => _dao.updateRecord(record);

  /// Deletes an insulin record, returns rows removed.
  Future<int> delete(InsulinEntity record) => _dao.deleteRecord(record);
}
