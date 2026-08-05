/// Data Access Object for the `medication_records` table.
///
/// This class contains every SQL query the app needs for medication data.
/// DAOs are written as abstract classes with Floor annotations; the Floor
/// code generator turns them into real SQLite queries at build time. The
/// Medication Repository uses this DAO and the medication dashboard uses
/// the repository.

library;

import 'package:floor/floor.dart';
import '../entities/medication_entity.dart';

/// DAO for medication entries.
@dao
abstract class MedicationDao {
  /// Returns all medications once, newest first, as a one-off list.
  @Query('SELECT * FROM medication_records ORDER BY id DESC')
  Future<List<MedicationEntity>> getAllRecords();

  /// Emits the full list of medications every time the table changes.
  /// The medication dashboard subscribes to this stream so new or edited
  /// medications appear automatically.
  @Query('SELECT * FROM medication_records ORDER BY id DESC')
  Stream<List<MedicationEntity>> watchAllRecords();

  /// Returns a single medication by its [id], or null if it does not exist.
  /// Used by the details screen to load the medication being shown/edited.
  @Query('SELECT * FROM medication_records WHERE id = :id')
  Future<MedicationEntity?> getRecordById(int id);

  /// Inserts a new medication and returns the newly generated id.
  /// Existing rows are replaced on a conflict (upsert behaviour).
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(MedicationEntity record);

  /// Updates an existing medication (matched by its id) and returns the
  /// number of rows changed.
  @Update()
  Future<int> updateRecord(MedicationEntity record);

  /// Deletes a medication and returns the number of rows removed.
  @delete
  Future<int> deleteRecord(MedicationEntity record);
}
