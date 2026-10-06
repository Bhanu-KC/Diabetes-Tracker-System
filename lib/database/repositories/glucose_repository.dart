// Middle layer between the database and the screens for glucose data.

import 'dart:async';
import '../daos/glucose_dao.dart';
import '../database.dart';
import '../entities/glucose_entity.dart';
import '../../services/data_sync_service.dart';

// Singleton with glucose CRUD methods for screens.
class GlucoseRepository {
  // Private, use getInstance instead.
  GlucoseRepository._(this._dao);

  final GlucoseDao _dao;

  static GlucoseRepository? _instance;

  // Returns the shared instance, opening the database only once.
  static Future<GlucoseRepository> getInstance() async {
    _instance ??= GlucoseRepository._(
      (await AppDatabase.getInstance()).glucoseDao,
    );
    return _instance!;
  }

  // Live stream of all readings, newest first.
  Stream<List<GlucoseEntity>> watchAll() => _dao.watchAllRecords();

  // One-time list of all readings.
  Future<List<GlucoseEntity>> getAll() => _dao.getAllRecords();

  // Gets one reading by id, or null if not found.
  Future<GlucoseEntity?> getById(int id) => _dao.getRecordById(id);

  // Gets the latest reading, or null if empty.
  Future<GlucoseEntity?> getLatest() => _dao.getLatestRecord();

  // Adds a new reading, returns the new id.
  Future<int> add(GlucoseEntity record) async {
    final id = await _dao.insertRecord(record);
    // Sync to Firestore with the local id.
    DataSyncService.syncGlucose(record.copyWith(id: id));
    return id;
  }

  // Updates a reading, returns rows changed.
  Future<int> update(GlucoseEntity record) async {
    final rows = await _dao.updateRecord(record);
    DataSyncService.syncGlucose(record);
    return rows;
  }

  // Deletes a reading, returns rows removed.
  Future<int> delete(GlucoseEntity record) async {
    final rows = await _dao.deleteRecord(record);
    DataSyncService.syncGlucose(record, delete: true);
    return rows;
  }
}
