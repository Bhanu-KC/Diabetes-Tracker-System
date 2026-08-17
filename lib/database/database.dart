/// The app's local FloorDB (SQLite) database and its migrations.
library;

import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'daos/glucose_dao.dart';
import 'daos/insulin_dao.dart';
import 'daos/meal_dao.dart';
import 'daos/medication_dao.dart';
import 'entities/glucose_entity.dart';
import 'entities/insulin_entity.dart';
import 'entities/meal_entity.dart';
import 'entities/medication_entity.dart';

// Generated SQL code, produced by build_runner.
part 'database.g.dart';

/// Migration 1 to 2: adds the medication_records table.
final _migration1To2 = Migration(1, 2, (sqflite.Database db) async {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS `medication_records`'
    ' (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL,'
    ' `dosage` TEXT NOT NULL, `frequency` TEXT NOT NULL,'
    ' `reminderTime` TEXT NOT NULL, `startDate` INTEGER NOT NULL,'
    ' `endDate` INTEGER NOT NULL, `notes` TEXT NOT NULL)',
  );
});

/// Migration 2 to 3: adds the insulin_records table.
final _migration2To3 = Migration(2, 3, (sqflite.Database db) async {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS `insulin_records`'
    ' (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL,'
    ' `dose` REAL NOT NULL, `site` TEXT NOT NULL,'
    ' `time` TEXT NOT NULL, `timestamp` INTEGER NOT NULL,'
    ' `notes` TEXT NOT NULL)',
  );
});

/// Migration 3 to 4: adds mealType and notes to meal_records.
final _migration3To4 = Migration(3, 4, (sqflite.Database db) async {
  await db.execute(
    "ALTER TABLE `meal_records`"
    " ADD COLUMN `mealType` TEXT NOT NULL DEFAULT 'Breakfast'",
  );
  await db.execute(
    "ALTER TABLE `meal_records`"
    " ADD COLUMN `notes` TEXT NOT NULL DEFAULT ''",
  );
});

/// Migration 4 to 5: adds reminder settings to medication and insulin.
final _migration4To5 = Migration(4, 5, (sqflite.Database db) async {
  await db.execute(
    "ALTER TABLE `medication_records`"
    " ADD COLUMN `reminderEnabled` INTEGER NOT NULL DEFAULT 1",
  );
  await db.execute(
    "ALTER TABLE `medication_records`"
    " ADD COLUMN `repeatDaily` INTEGER NOT NULL DEFAULT 1",
  );
  await db.execute(
    "ALTER TABLE `insulin_records`"
    " ADD COLUMN `reminderEnabled` INTEGER NOT NULL DEFAULT 1",
  );
  await db.execute(
    "ALTER TABLE `insulin_records`"
    " ADD COLUMN `repeatDaily` INTEGER NOT NULL DEFAULT 1",
  );
});

/// The app's database. Declares the four tables and their DAOs.
@Database(
  version: 5,
  entities: [GlucoseEntity, MealEntity, MedicationEntity, InsulinEntity],
)
abstract class AppDatabase extends FloorDatabase {
  /// DAO for the glucose_records table.
  GlucoseDao get glucoseDao;

  /// DAO for the meal_records table.
  MealDao get mealDao;

  /// DAO for the medication_records table.
  MedicationDao get medicationDao;

  /// DAO for the insulin_records table.
  InsulinDao get insulinDao;

  /// Opens the database and runs any pending migrations.
  static Future<AppDatabase> getInstance() async {
    return $FloorAppDatabase
        .databaseBuilder('diabetes_tracker.db')
        .addMigrations([
          _migration1To2,
          _migration2To3,
          _migration3To4,
          _migration4To5,
        ])
        .build();
  }
}
