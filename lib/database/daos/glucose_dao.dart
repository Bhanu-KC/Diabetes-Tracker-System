/// All SQL queries for the glucose_records table.
library;

import 'package:floor/floor.dart';
import '../entities/glucose_entity.dart';

/// DAO for blood sugar (glucose) readings.
@dao
abstract class GlucoseDao {
  /// Gets all readings, newest first.
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC')
  Future<List<GlucoseEntity>> getAllRecords();

  /// Streams all readings, updating automatically on changes.
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC')
  Stream<List<GlucoseEntity>> watchAllRecords();

  /// Gets one reading by id, or null if not found.
  @Query('SELECT * FROM glucose_records WHERE id = :id')
  Future<GlucoseEntity?> getRecordById(int id);

  /// Gets the most recent reading, or null if none exist.
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC LIMIT 1')
  Future<GlucoseEntity?> getLatestRecord();

  /// Inserts a new reading, returns the new id.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(GlucoseEntity record);

  /// Updates a reading, returns rows changed.
  @Update()
  Future<int> updateRecord(GlucoseEntity record);

  /// Deletes a reading, returns rows removed.
  @delete
  Future<int> deleteRecord(GlucoseEntity record);
}
