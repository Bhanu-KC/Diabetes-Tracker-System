// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  GlucoseDao? _glucoseDaoInstance;

  MealDao? _mealDaoInstance;

  MedicationDao? _medicationDaoInstance;

  InsulinDao? _insulinDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 5,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `glucose_records` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `level` REAL NOT NULL, `mealContext` TEXT NOT NULL, `notes` TEXT NOT NULL, `timestamp` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `meal_records` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `mealType` TEXT NOT NULL, `carbs` REAL, `calories` REAL, `timestamp` INTEGER NOT NULL, `notes` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `medication_records` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `dosage` TEXT NOT NULL, `frequency` TEXT NOT NULL, `reminderTime` TEXT NOT NULL, `reminderEnabled` INTEGER NOT NULL, `repeatDaily` INTEGER NOT NULL, `startDate` INTEGER NOT NULL, `endDate` INTEGER NOT NULL, `notes` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `insulin_records` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT NOT NULL, `dose` REAL NOT NULL, `site` TEXT NOT NULL, `time` TEXT NOT NULL, `reminderEnabled` INTEGER NOT NULL, `repeatDaily` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, `notes` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  GlucoseDao get glucoseDao {
    return _glucoseDaoInstance ??= _$GlucoseDao(database, changeListener);
  }

  @override
  MealDao get mealDao {
    return _mealDaoInstance ??= _$MealDao(database, changeListener);
  }

  @override
  MedicationDao get medicationDao {
    return _medicationDaoInstance ??= _$MedicationDao(database, changeListener);
  }

  @override
  InsulinDao get insulinDao {
    return _insulinDaoInstance ??= _$InsulinDao(database, changeListener);
  }
}

class _$GlucoseDao extends GlucoseDao {
  _$GlucoseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _glucoseEntityInsertionAdapter = InsertionAdapter(
            database,
            'glucose_records',
            (GlucoseEntity item) => <String, Object?>{
                  'id': item.id,
                  'level': item.level,
                  'mealContext': item.mealContext,
                  'notes': item.notes,
                  'timestamp': item.timestamp
                },
            changeListener),
        _glucoseEntityUpdateAdapter = UpdateAdapter(
            database,
            'glucose_records',
            ['id'],
            (GlucoseEntity item) => <String, Object?>{
                  'id': item.id,
                  'level': item.level,
                  'mealContext': item.mealContext,
                  'notes': item.notes,
                  'timestamp': item.timestamp
                },
            changeListener),
        _glucoseEntityDeletionAdapter = DeletionAdapter(
            database,
            'glucose_records',
            ['id'],
            (GlucoseEntity item) => <String, Object?>{
                  'id': item.id,
                  'level': item.level,
                  'mealContext': item.mealContext,
                  'notes': item.notes,
                  'timestamp': item.timestamp
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<GlucoseEntity> _glucoseEntityInsertionAdapter;

  final UpdateAdapter<GlucoseEntity> _glucoseEntityUpdateAdapter;

  final DeletionAdapter<GlucoseEntity> _glucoseEntityDeletionAdapter;

  @override
  Future<List<GlucoseEntity>> getAllRecords() async {
    return _queryAdapter.queryList(
        'SELECT * FROM glucose_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => GlucoseEntity(
            id: row['id'] as int?,
            level: row['level'] as double,
            mealContext: row['mealContext'] as String,
            notes: row['notes'] as String,
            timestamp: row['timestamp'] as int));
  }

  @override
  Stream<List<GlucoseEntity>> watchAllRecords() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM glucose_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => GlucoseEntity(
            id: row['id'] as int?,
            level: row['level'] as double,
            mealContext: row['mealContext'] as String,
            notes: row['notes'] as String,
            timestamp: row['timestamp'] as int),
        queryableName: 'glucose_records',
        isView: false);
  }

  @override
  Future<GlucoseEntity?> getRecordById(int id) async {
    return _queryAdapter.query('SELECT * FROM glucose_records WHERE id = ?1',
        mapper: (Map<String, Object?> row) => GlucoseEntity(
            id: row['id'] as int?,
            level: row['level'] as double,
            mealContext: row['mealContext'] as String,
            notes: row['notes'] as String,
            timestamp: row['timestamp'] as int),
        arguments: [id]);
  }

  @override
  Future<GlucoseEntity?> getLatestRecord() async {
    return _queryAdapter.query(
        'SELECT * FROM glucose_records ORDER BY timestamp DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => GlucoseEntity(
            id: row['id'] as int?,
            level: row['level'] as double,
            mealContext: row['mealContext'] as String,
            notes: row['notes'] as String,
            timestamp: row['timestamp'] as int));
  }

  @override
  Future<int> insertRecord(GlucoseEntity record) {
    return _glucoseEntityInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<int> updateRecord(GlucoseEntity record) {
    return _glucoseEntityUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(GlucoseEntity record) {
    return _glucoseEntityDeletionAdapter.deleteAndReturnChangedRows(record);
  }
}

class _$MealDao extends MealDao {
  _$MealDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _mealEntityInsertionAdapter = InsertionAdapter(
            database,
            'meal_records',
            (MealEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'mealType': item.mealType,
                  'carbs': item.carbs,
                  'calories': item.calories,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener),
        _mealEntityUpdateAdapter = UpdateAdapter(
            database,
            'meal_records',
            ['id'],
            (MealEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'mealType': item.mealType,
                  'carbs': item.carbs,
                  'calories': item.calories,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener),
        _mealEntityDeletionAdapter = DeletionAdapter(
            database,
            'meal_records',
            ['id'],
            (MealEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'mealType': item.mealType,
                  'carbs': item.carbs,
                  'calories': item.calories,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MealEntity> _mealEntityInsertionAdapter;

  final UpdateAdapter<MealEntity> _mealEntityUpdateAdapter;

  final DeletionAdapter<MealEntity> _mealEntityDeletionAdapter;

  @override
  Future<List<MealEntity>> getAllRecords() async {
    return _queryAdapter.queryList(
        'SELECT * FROM meal_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => MealEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            mealType: row['mealType'] as String,
            carbs: row['carbs'] as double?,
            calories: row['calories'] as double?,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String));
  }

  @override
  Stream<List<MealEntity>> watchAllRecords() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM meal_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => MealEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            mealType: row['mealType'] as String,
            carbs: row['carbs'] as double?,
            calories: row['calories'] as double?,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String),
        queryableName: 'meal_records',
        isView: false);
  }

  @override
  Future<MealEntity?> getRecordById(int id) async {
    return _queryAdapter.query('SELECT * FROM meal_records WHERE id = ?1',
        mapper: (Map<String, Object?> row) => MealEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            mealType: row['mealType'] as String,
            carbs: row['carbs'] as double?,
            calories: row['calories'] as double?,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String),
        arguments: [id]);
  }

  @override
  Future<int> insertRecord(MealEntity record) {
    return _mealEntityInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<int> updateRecord(MealEntity record) {
    return _mealEntityUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(MealEntity record) {
    return _mealEntityDeletionAdapter.deleteAndReturnChangedRows(record);
  }
}

class _$MedicationDao extends MedicationDao {
  _$MedicationDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _medicationEntityInsertionAdapter = InsertionAdapter(
            database,
            'medication_records',
            (MedicationEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dosage': item.dosage,
                  'frequency': item.frequency,
                  'reminderTime': item.reminderTime,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes
                },
            changeListener),
        _medicationEntityUpdateAdapter = UpdateAdapter(
            database,
            'medication_records',
            ['id'],
            (MedicationEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dosage': item.dosage,
                  'frequency': item.frequency,
                  'reminderTime': item.reminderTime,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes
                },
            changeListener),
        _medicationEntityDeletionAdapter = DeletionAdapter(
            database,
            'medication_records',
            ['id'],
            (MedicationEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dosage': item.dosage,
                  'frequency': item.frequency,
                  'reminderTime': item.reminderTime,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MedicationEntity> _medicationEntityInsertionAdapter;

  final UpdateAdapter<MedicationEntity> _medicationEntityUpdateAdapter;

  final DeletionAdapter<MedicationEntity> _medicationEntityDeletionAdapter;

  @override
  Future<List<MedicationEntity>> getAllRecords() async {
    return _queryAdapter.queryList(
        'SELECT * FROM medication_records ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => MedicationEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dosage: row['dosage'] as String,
            frequency: row['frequency'] as String,
            reminderTime: row['reminderTime'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            notes: row['notes'] as String));
  }

  @override
  Stream<List<MedicationEntity>> watchAllRecords() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM medication_records ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => MedicationEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dosage: row['dosage'] as String,
            frequency: row['frequency'] as String,
            reminderTime: row['reminderTime'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            notes: row['notes'] as String),
        queryableName: 'medication_records',
        isView: false);
  }

  @override
  Future<MedicationEntity?> getRecordById(int id) async {
    return _queryAdapter.query('SELECT * FROM medication_records WHERE id = ?1',
        mapper: (Map<String, Object?> row) => MedicationEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dosage: row['dosage'] as String,
            frequency: row['frequency'] as String,
            reminderTime: row['reminderTime'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            notes: row['notes'] as String),
        arguments: [id]);
  }

  @override
  Future<int> insertRecord(MedicationEntity record) {
    return _medicationEntityInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<int> updateRecord(MedicationEntity record) {
    return _medicationEntityUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(MedicationEntity record) {
    return _medicationEntityDeletionAdapter.deleteAndReturnChangedRows(record);
  }
}

class _$InsulinDao extends InsulinDao {
  _$InsulinDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _insulinEntityInsertionAdapter = InsertionAdapter(
            database,
            'insulin_records',
            (InsulinEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dose': item.dose,
                  'site': item.site,
                  'time': item.time,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener),
        _insulinEntityUpdateAdapter = UpdateAdapter(
            database,
            'insulin_records',
            ['id'],
            (InsulinEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dose': item.dose,
                  'site': item.site,
                  'time': item.time,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener),
        _insulinEntityDeletionAdapter = DeletionAdapter(
            database,
            'insulin_records',
            ['id'],
            (InsulinEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'dose': item.dose,
                  'site': item.site,
                  'time': item.time,
                  'reminderEnabled': item.reminderEnabled ? 1 : 0,
                  'repeatDaily': item.repeatDaily ? 1 : 0,
                  'timestamp': item.timestamp,
                  'notes': item.notes
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<InsulinEntity> _insulinEntityInsertionAdapter;

  final UpdateAdapter<InsulinEntity> _insulinEntityUpdateAdapter;

  final DeletionAdapter<InsulinEntity> _insulinEntityDeletionAdapter;

  @override
  Future<List<InsulinEntity>> getAllRecords() async {
    return _queryAdapter.queryList(
        'SELECT * FROM insulin_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => InsulinEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dose: row['dose'] as double,
            site: row['site'] as String,
            time: row['time'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String));
  }

  @override
  Stream<List<InsulinEntity>> watchAllRecords() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM insulin_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => InsulinEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dose: row['dose'] as double,
            site: row['site'] as String,
            time: row['time'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String),
        queryableName: 'insulin_records',
        isView: false);
  }

  @override
  Future<InsulinEntity?> getRecordById(int id) async {
    return _queryAdapter.query('SELECT * FROM insulin_records WHERE id = ?1',
        mapper: (Map<String, Object?> row) => InsulinEntity(
            id: row['id'] as int?,
            name: row['name'] as String,
            dose: row['dose'] as double,
            site: row['site'] as String,
            time: row['time'] as String,
            reminderEnabled: (row['reminderEnabled'] as int) != 0,
            repeatDaily: (row['repeatDaily'] as int) != 0,
            timestamp: row['timestamp'] as int,
            notes: row['notes'] as String),
        arguments: [id]);
  }

  @override
  Future<int> insertRecord(InsulinEntity record) {
    return _insulinEntityInsertionAdapter.insertAndReturnId(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<int> updateRecord(InsulinEntity record) {
    return _insulinEntityUpdateAdapter.updateAndReturnChangedRows(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRecord(InsulinEntity record) {
    return _insulinEntityDeletionAdapter.deleteAndReturnChangedRows(record);
  }
}
