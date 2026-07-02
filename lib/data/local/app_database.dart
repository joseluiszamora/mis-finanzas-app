import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MovementGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Movements extends Table {
  TextColumn get id => text()();
  TextColumn get tipo => text().withLength(min: 1, max: 20)();
  TextColumn get categoriaId => text().references(Categories, #id)();
  TextColumn get grupoId => text().nullable().references(MovementGroups, #id)();
  TextColumn get concepto => text().withLength(min: 1, max: 255)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  TextColumn get entityId => text().withLength(min: 1, max: 100)();
  TextColumn get operation => text().withLength(min: 1, max: 20)();
  TextColumn get payloadJson => text()();
  IntColumn get payloadVersion => integer().withDefault(const Constant(1))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Categories,
    MovementGroups,
    Movements,
    SyncQueueEntries,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> seedDefaults() async {
    final alreadySeeded = await _settingValue('seeded_defaults_v1');
    if (alreadySeeded == 'true') {
      return;
    }

    final now = DateTime.now();
    final defaultCategories = [
      'Salario',
      'Freelance',
      'Inversiones',
      'Alimentación',
      'Transporte',
      'Vivienda',
      'Servicios',
      'Salud',
      'Educación',
      'Entretenimiento',
      'Ropa',
      'Tecnología',
      'Deudas',
      'Ahorro',
      'Otro',
    ];
    final defaultGroups = ['Personal', 'Familia', 'Trabajo', 'Proyecto'];

    await batch((batch) {
      for (final category in defaultCategories) {
        batch.insert(
          categories,
          CategoriesCompanion.insert(
            id: 'seed-category-${_slugify(category)}',
            name: category,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final group in defaultGroups) {
        batch.insert(
          movementGroups,
          MovementGroupsCompanion.insert(
            id: 'seed-group-${_slugify(group)}',
            name: group,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });

    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: 'seeded_defaults_v1',
        value: const Value('true'),
        updatedAt: now,
      ),
    );
  }

  Future<String?> _settingValue(String settingKey) async {
    final row =
        await (select(appSettings)
          ..where((tbl) => tbl.key.equals(settingKey))).getSingleOrNull();
    return row?.value;
  }

  static String _slugify(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'mis_finanzas.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
