/// All SQL queries for the medication_records table.
library;

import 'package:floor/floor.dart';
import '../entities/medication_entity.dart';

/// DAO for medication entries.
@dao
abstract class MedicationDao {
  /// Gets all medications, newest first.
  @Query('SELECT * FROM medication_records ORDER BY id DESC')
  Future<List<MedicationEntity>> getAllRecords();

  /// Streams all medications, updating automatically on changes.
  @Query('SELECT * FROM medication_records ORDER BY id DESC')
  Stream<List<MedicationEntity>> watchAllRecords();

  /// Gets one medication by id, or null if not found.
  @Query('SELECT * FROM medication_records WHERE id = :id')
  Future<MedicationEntity?> getRecordById(int id);

  /// Inserts a medication, returns the new id.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(MedicationEntity record);

  /// Updates a medication, returns rows changed.
  @Update()
  Future<int> updateRecord(MedicationEntity record);

  /// Deletes a medication, returns rows removed.
  @delete
  Future<int> deleteRecord(MedicationEntity record);
}
