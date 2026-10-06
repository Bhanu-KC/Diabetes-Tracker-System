// Middle layer between the database and the screens for insulin data.

import 'dart:async';
import '../daos/insulin_dao.dart';
import '../database.dart';
import '../entities/insulin_entity.dart';
import '../../services/data_sync_service.dart';

// Singleton with insulin CRUD methods for screens.
class InsulinRepository {
  // Private, use getInstance instead.
  InsulinRepository._(this._dao);

  final InsulinDao _dao;

  static InsulinRepository? _instance;

  // Returns the shared instance, opening the database only once.
  static Future<InsulinRepository> getInstance() async {
    _instance ??= InsulinRepository._(
      (await AppDatabase.getInstance()).insulinDao,
    );
    return _instance!;
  }

  // Live stream of all insulin records, newest first.
  Stream<List<InsulinEntity>> watchAll() => _dao.watchAllRecords();

  // One-time list of all insulin records.
  Future<List<InsulinEntity>> getAll() => _dao.getAllRecords();

  // Gets one insulin record by id, or null if not found.
  Future<InsulinEntity?> getById(int id) => _dao.getRecordById(id);

  // Adds a new insulin record, returns the new id.
  Future<int> add(InsulinEntity record) async {
    final id = await _dao.insertRecord(record);
    // Sync to Firestore with the local id.
    DataSyncService.syncInsulin(record.copyWith(id: id));
    return id;
  }

  // Updates an insulin record, returns rows changed.
  Future<int> update(InsulinEntity record) async {
    final rows = await _dao.updateRecord(record);
    DataSyncService.syncInsulin(record);
    return rows;
  }

  // Deletes an insulin record, returns rows removed.
  Future<int> delete(InsulinEntity record) async {
    final rows = await _dao.deleteRecord(record);
    DataSyncService.syncInsulin(record, delete: true);
    return rows;
  }
}
