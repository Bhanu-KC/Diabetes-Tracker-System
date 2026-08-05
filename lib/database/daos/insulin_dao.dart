/// Data Access Object for the `insulin_records` table.
///
/// This class contains every SQL query the app needs for insulin data.
/// DAOs are written as abstract classes with Floor annotations; the Floor
/// code generator turns them into real SQLite queries at build time. The
/// Insulin Repository uses this DAO and the insulin screen uses the
/// repository.

library;

import 'package:floor/floor.dart';
import '../entities/insulin_entity.dart';

/// DAO for insulin dose entries.
@dao
abstract class InsulinDao {
  /// Returns all insulin records once, newest first, as a one-off list.
  /// Used for one-time loads such as the reports screen.
  @Query('SELECT * FROM insulin_records ORDER BY timestamp DESC')
  Future<List<InsulinEntity>> getAllRecords();

  /// Emits the full list of insulin records every time the table changes.
  /// The insulin screen subscribes to this stream so the list updates
  /// automatically after a save or delete.
  @Query('SELECT * FROM insulin_records ORDER BY timestamp DESC')
  Stream<List<InsulinEntity>> watchAllRecords();

  /// Returns a single insulin record by its [id], or null if it does not
  /// exist. Used by the edit flow to load the record being edited.
  @Query('SELECT * FROM insulin_records WHERE id = :id')
  Future<InsulinEntity?> getRecordById(int id);

  /// Inserts a new insulin record and returns the newly generated id.
  /// Existing rows are replaced on a conflict (upsert behaviour).
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(InsulinEntity record);

  /// Updates an existing insulin record (matched by its id) and returns
  /// the number of rows changed.
  @Update()
  Future<int> updateRecord(InsulinEntity record);

  /// Deletes an insulin record and returns the number of rows removed.
  @delete
  Future<int> deleteRecord(InsulinEntity record);
}
