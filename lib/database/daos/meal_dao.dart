/// Data Access Object for the `meal_records` table.
///
/// This class contains every SQL query the app needs for meal data.
/// DAOs are written as abstract classes with Floor annotations; the Floor
/// code generator turns them into real SQLite queries at build time. The
/// Meal Repository uses this DAO and the meal tracker screen uses the
/// repository.

library;

import 'package:floor/floor.dart';
import '../entities/meal_entity.dart';

/// DAO for meal entries.
@dao
abstract class MealDao {
  /// Returns all meals once, newest first, as a one-off list.
  /// Used for one-time loads such as the reports screen.
  @Query('SELECT * FROM meal_records ORDER BY timestamp DESC')
  Future<List<MealEntity>> getAllRecords();

  /// Emits the full list of meals, newest first, every time the table
  /// changes. The meal tracker subscribes to this stream so the list
  /// updates automatically after a save or delete.
  @Query('SELECT * FROM meal_records ORDER BY timestamp DESC')
  Stream<List<MealEntity>> watchAllRecords();

  /// Returns a single meal by its [id], or null if it does not exist.
  /// Used by the edit flow to load the meal being edited.
  @Query('SELECT * FROM meal_records WHERE id = :id')
  Future<MealEntity?> getRecordById(int id);

  /// Inserts a new meal and returns the newly generated id.
  /// Existing rows are replaced on a conflict (upsert behaviour).
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<int> insertRecord(MealEntity record);

  /// Updates an existing meal (matched by its id) and returns the
  /// number of rows changed.
  @Update()
  Future<int> updateRecord(MealEntity record);

  /// Deletes a meal and returns the number of rows removed.
  @delete
  Future<int> deleteRecord(MealEntity record);
}
