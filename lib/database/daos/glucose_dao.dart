/// Data Access Object for the `glucose_records` table.
///
/// This class contains every SQL query the app needs for blood sugar data.
/// DAOs are written as abstract classes with Floor annotations; the Floor
/// code generator turns them into real SQLite queries at build time. The
/// Glucose Repository uses this DAO and the blood sugar screens use the
/// repository.

library;

import 'package:floor/floor.dart';
import '../entities/glucose_entity.dart';

/// DAO for blood sugar (glucose) readings.
@dao
abstract class GlucoseDao {
  /// Returns all readings once, newest first, as a one-off list.
  /// Used for one-time loads such as the reports screen.
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC')
  Future<List<GlucoseEntity>> getAllRecords();

  /// Emits the full list of readings, newest first, every time the table
  /// changes. Screens subscribe to this stream to stay live (for example
  /// the dashboard and history screens refresh automatically after a save).
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC')
  Stream<List<GlucoseEntity>> watchAllRecords();

  /// Returns a single reading by its [id], or null if it does not exist.
  ///  Used by the edit screen to load the reading being edited.
  @Query('SELECT * FROM glucose_records WHERE id = :id')
  Future<GlucoseEntity?> getRecordById(int id);

  /// Returns the most recent reading, or null if the table is empty.
  /// Used by the dashboard to show the latest blood sugar value.
  @Query('SELECT * FROM glucose_records ORDER BY timestamp DESC LIMIT 1')
  Future<GlucoseEntity?> getLatestRecord();

  /// Inserts a new reading and returns the newly generated id.
  /// Existing rows are replaced on a conflict (upsert behaviour).
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(GlucoseEntity record);

  /// Updates an existing reading (matched by its id) and returns the
  /// number of rows changed.
  @Update()
  Future<int> updateRecord(GlucoseEntity record);

  /// Deletes a reading and returns the number of rows removed.
  @delete
  Future<int> deleteRecord(GlucoseEntity record);
}
