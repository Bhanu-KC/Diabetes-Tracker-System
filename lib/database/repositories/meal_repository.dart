// Middle layer between the database and the screens for meal data.

import 'dart:async';
import '../daos/meal_dao.dart';
import '../database.dart';
import '../entities/meal_entity.dart';

/// Singleton with meal CRUD methods for screens.
class MealRepository {
  /// Private, use [getInstance] instead.
  MealRepository._(this._dao);

  final MealDao _dao;

  static MealRepository? _instance;

  /// Returns the shared instance, opening the database only once.
  static Future<MealRepository> getInstance() async {
    _instance ??= MealRepository._((await AppDatabase.getInstance()).mealDao);
    return _instance!;
  }

  /// Live stream of all meals, newest first.
  Stream<List<MealEntity>> watchAll() => _dao.watchAllRecords();

  /// One-time list of all meals.
  Future<List<MealEntity>> getAll() => _dao.getAllRecords();

  /// Gets one meal by id, or null if not found.
  Future<MealEntity?> getById(int id) => _dao.getRecordById(id);

  /// Adds a new meal, returns the new id.
  Future<int> add(MealEntity record) => _dao.insertRecord(record);

  /// Updates a meal, returns rows changed.
  Future<int> update(MealEntity record) => _dao.updateRecord(record);

  /// Deletes a meal, returns rows removed.
  Future<int> delete(MealEntity record) => _dao.deleteRecord(record);
}
