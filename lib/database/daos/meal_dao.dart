// All SQL queries for the meal_records table.

import 'package:floor/floor.dart';
import '../entities/meal_entity.dart';

/// DAO for meal entries.
@dao
abstract class MealDao {
  /// Gets all meals, newest first.
  @Query('SELECT * FROM meal_records ORDER BY timestamp DESC')
  Future<List<MealEntity>> getAllRecords();

  /// Streams all meals, updating automatically on changes.
  @Query('SELECT * FROM meal_records ORDER BY timestamp DESC')
  Stream<List<MealEntity>> watchAllRecords();

  /// Gets one meal by id, or null if not found.
  @Query('SELECT * FROM meal_records WHERE id = :id')
  Future<MealEntity?> getRecordById(int id);

  /// Inserts a new meal, returns the new id.
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(MealEntity record);

  /// Updates a meal, returns rows changed.
  @Update()
  Future<int> updateRecord(MealEntity record);

  /// Deletes a meal, returns rows removed.
  @delete
  Future<int> deleteRecord(MealEntity record);
}
