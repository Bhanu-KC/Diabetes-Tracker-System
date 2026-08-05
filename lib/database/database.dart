/// FloorDB database definition for the Diabetes Tracking System.
///
/// This file tells the Floor ORM which tables (entities) exist and how to
/// upgrade the local SQLite database between versions using migrations.
/// All health data (blood sugar, meals, medications and insulin) is stored
/// offline on the device in a single SQLite file called `diabetes_tracker.db`.

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

// The generated part below contains the actual SQL implementations
// produced by `flutter pub run build_runner build`.
part 'database.g.dart';

/// Migration from database version 1 to 2.
///
/// Version 2 added the `medication_records` table, so this migration
/// simply creates that table for users upgrading from an older build.
final _migration1To2 = Migration(1, 2, (sqflite.Database db) async {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS `medication_records`'
    ' (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL,'
    ' `dosage` TEXT NOT NULL, `frequency` TEXT NOT NULL,'
    ' `reminderTime` TEXT NOT NULL, `startDate` INTEGER NOT NULL,'
    ' `endDate` INTEGER NOT NULL, `notes` TEXT NOT NULL)',
  );
});

/// Migration from database version 2 to 3.
///
/// Version 3 added the `insulin_records` table for tracking insulin doses.
final _migration2To3 = Migration(2, 3, (sqflite.Database db) async {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS `insulin_records`'
    ' (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL,'
    ' `dose` REAL NOT NULL, `site` TEXT NOT NULL,'
    ' `time` TEXT NOT NULL, `timestamp` INTEGER NOT NULL,'
    ' `notes` TEXT NOT NULL)',
  );
});

/// Migration from database version 3 to 4.
///
/// Version 4 extended the existing `meal_records` table with a `mealType`
/// (Breakfast/Lunch/Dinner/Snacks) and an optional `notes` column. Because
/// ALTER TABLE cannot set NOT NULL without a default, both columns use a
/// default value so existing meal rows are kept.
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

/// Migration from database version 4 to 5.
///
/// Version 5 added reminder controls to the medication and insulin
/// tables: `reminderEnabled` (whether a reminder notification is
/// scheduled) and `repeatDaily` (whether the reminder repeats every day).
/// Both default to 1 (on) so reminders that existed before this update
/// keep working exactly as before.
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

/// The main Floor database of the application.
///
/// Declares the four database tables (entities) and exposes one DAO per
/// table. The `version` number must be increased whenever the schema
/// changes, and a matching migration must be added to [getInstance].
@Database(
  version: 5,
  entities: [GlucoseEntity, MealEntity, MedicationEntity, InsulinEntity],
)
abstract class AppDatabase extends FloorDatabase {
  /// Data access object for the `glucose_records` table.
  GlucoseDao get glucoseDao;

  /// Data access object for the `meal_records` table.
  MealDao get mealDao;

  /// Data access object for the `medication_records` table.
  MedicationDao get medicationDao;

  /// Data access object for the `insulin_records` table.
  InsulinDao get insulinDao;

  /// Creates (or opens) the app database and applies pending migrations.
  ///
  /// Uses the Floor builder to open `diabetes_tracker.db`, passing the
  /// list of all migrations so older databases are upgraded safely.
  /// Returns a ready to use [AppDatabase] instance.
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
