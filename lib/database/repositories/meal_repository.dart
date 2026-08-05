/// Repository for meal data.
///
/// The repository is a middle layer between the database and the screens:
/// it creates the Floor database once, exposes simple CRUD methods, and
/// hides the DAO details from the UI. It communicates with the local
/// FloorDB (SQLite) only - there is no network call. Used by the meal
/// tracker, Add Meal, dashboard (calorie summary) and reports screens.

library;

import 'dart:async';
import '../daos/meal_dao.dart';
import '../database.dart';
import '../entities/meal_entity.dart';

/// Singleton repository providing meal CRUD methods to screens.
class MealRepository {
  /// Private constructor: screens must use [getInstance] instead.
  MealRepository._(this._dao);

  final MealDao _dao;

  static MealRepository? _instance;

  /// Returns the shared repository instance, opening the database once.
  ///
  /// The first call builds the FloorDB database; later calls reuse the
  /// same instance so the database is not reopened on every screen.
  static Future<MealRepository> getInstance() async {
    _instance ??= MealRepository._((await AppDatabase.getInstance()).mealDao);
    return _instance!;
  }

  /// Live stream of all meals (newest first).
  /// Screens subscribe to this to update automatically on changes.
  Stream<List<MealEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all meals (newest first).
  Future<List<MealEntity>> getAll() => _dao.getAllRecords();

  /// Returns a single meal by [id], or null if not found.
  Future<MealEntity?> getById(int id) => _dao.getRecordById(id);

  /// Saves a new meal (returns the new id).
  Future<int> add(MealEntity record) => _dao.insertRecord(record);

  /// Updates an existing meal (returns rows changed).
  Future<int> update(MealEntity record) => _dao.updateRecord(record);

  /// Deletes a meal (returns rows removed).
  Future<int> delete(MealEntity record) => _dao.deleteRecord(record);
}
