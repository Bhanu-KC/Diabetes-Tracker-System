/// All SQL queries for the insulin_records table.
library;

import 'package:floor/floor.dart';
import '../entities/insulin_entity.dart';

/// DAO for insulin dose entries.
@dao
abstract class InsulinDao {
  /// Gets all insulin records, newest first.
  @Query('SELECT * FROM insulin_records ORDER BY timestamp DESC')
  Future<List<InsulinEntity>> getAllRecords();

  /// Streams all insulin records, updating automatically on changes.
  @Query('SELECT * FROM insulin_records ORDER BY timestamp DESC')
  Stream<List<InsulinEntity>> watchAllRecords();

  /// Gets one insulin record by id, or null if not found.
  @Query('SELECT * FROM insulin_records WHERE id = :id')
  Future<InsulinEntity?> getRecordById(int id);

  /// Inserts a new insulin record, returns the new id.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(InsulinEntity record);

  /// Updates an insulin record, returns rows changed.
  @Update()
  Future<int> updateRecord(InsulinEntity record);

  /// Deletes an insulin record, returns rows removed.
  @delete
  Future<int> deleteRecord(InsulinEntity record);
}
