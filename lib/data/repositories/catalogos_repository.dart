import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/categoria.dart';
import '../../models/grupo.dart';
import '../../models/sync_status.dart';
import '../local/app_database.dart';
import '../sync/sync_coordinator.dart';

abstract class CatalogosRepository {
  Future<List<Categoria>> obtenerCategorias();
  Future<List<Grupo>> obtenerGrupos();
  Future<Categoria> crearCategoria(String nombre);
  Future<Grupo> crearGrupo(String nombre);
  Future<void> actualizarCategoria(String id, String nombre);
  Future<void> actualizarGrupo(String id, String nombre);
  Future<void> eliminarCategoria(String id);
  Future<void> eliminarGrupo(String id);
}

class LocalCatalogosRepository implements CatalogosRepository {
  LocalCatalogosRepository({
    required AppDatabase database,
    required SyncCoordinator syncCoordinator,
    Uuid? uuid,
  }) : _database = database,
       _syncCoordinator = syncCoordinator,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final SyncCoordinator _syncCoordinator;
  final Uuid _uuid;

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    final rows =
        await (_database.select(_database.categories)
              ..where((tbl) => tbl.deletedAt.isNull())
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();

    return rows
        .map(
          (row) => Categoria(
            id: row.id,
            nombre: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
            syncStatus: SyncStatus.fromStorage(row.syncStatus),
          ),
        )
        .toList();
  }

  @override
  Future<List<Grupo>> obtenerGrupos() async {
    final rows =
        await (_database.select(_database.movementGroups)
              ..where((tbl) => tbl.deletedAt.isNull())
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
            .get();

    return rows
        .map(
          (row) => Grupo(
            id: row.id,
            nombre: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
            syncStatus: SyncStatus.fromStorage(row.syncStatus),
          ),
        )
        .toList();
  }

  @override
  Future<Categoria> crearCategoria(String nombre) async {
    final normalizedName = _normalizeName(nombre);
    await _ensureUniqueCategoryName(normalizedName);

    final now = DateTime.now();
    final category = CategoriesCompanion.insert(
      id: _uuid.v4(),
      name: normalizedName,
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pendingCreate'),
    );

    await _database.into(_database.categories).insert(category);
    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.category,
      entityId: category.id.value,
      operation: SyncOperation.create,
      payload: {'id': category.id.value, 'name': normalizedName},
    );

    return Categoria(
      id: category.id.value,
      nombre: normalizedName,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      syncStatus: SyncStatus.pendingCreate,
    );
  }

  @override
  Future<Grupo> crearGrupo(String nombre) async {
    final normalizedName = _normalizeName(nombre);
    await _ensureUniqueGroupName(normalizedName);

    final now = DateTime.now();
    final group = MovementGroupsCompanion.insert(
      id: _uuid.v4(),
      name: normalizedName,
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pendingCreate'),
    );

    await _database.into(_database.movementGroups).insert(group);
    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.group,
      entityId: group.id.value,
      operation: SyncOperation.create,
      payload: {'id': group.id.value, 'name': normalizedName},
    );

    return Grupo(
      id: group.id.value,
      nombre: normalizedName,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      syncStatus: SyncStatus.pendingCreate,
    );
  }

  @override
  Future<void> actualizarCategoria(String id, String nombre) async {
    final normalizedName = _normalizeName(nombre);
    await _ensureUniqueCategoryName(normalizedName, excludingId: id);
    final current = await _findCategory(id);
    final now = DateTime.now();
    final nextStatus =
        current.syncStatus == 'pendingCreate'
            ? 'pendingCreate'
            : 'pendingUpdate';

    await (_database.update(_database.categories)
      ..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(normalizedName),
        updatedAt: Value(now),
        syncStatus: Value(nextStatus),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.category,
      entityId: id,
      operation: SyncOperation.update,
      payload: {'id': id, 'name': normalizedName},
    );
  }

  @override
  Future<void> actualizarGrupo(String id, String nombre) async {
    final normalizedName = _normalizeName(nombre);
    await _ensureUniqueGroupName(normalizedName, excludingId: id);
    final current = await _findGroup(id);
    final now = DateTime.now();
    final nextStatus =
        current.syncStatus == 'pendingCreate'
            ? 'pendingCreate'
            : 'pendingUpdate';

    await (_database.update(_database.movementGroups)
      ..where((tbl) => tbl.id.equals(id))).write(
      MovementGroupsCompanion(
        name: Value(normalizedName),
        updatedAt: Value(now),
        syncStatus: Value(nextStatus),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.group,
      entityId: id,
      operation: SyncOperation.update,
      payload: {'id': id, 'name': normalizedName},
    );
  }

  @override
  Future<void> eliminarCategoria(String id) async {
    final usageCount = await _countMovementsUsingCategory(id);
    if (usageCount > 0) {
      throw StateError(
        'No puedes eliminar una categoría que ya está asociada a movimientos.',
      );
    }

    final current = await _findCategory(id);
    final now = DateTime.now();
    final nextStatus =
        current.syncStatus == 'pendingCreate'
            ? 'pendingDelete'
            : 'pendingDelete';

    await (_database.update(_database.categories)
      ..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: Value(nextStatus),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.category,
      entityId: id,
      operation: SyncOperation.delete,
      payload: {'id': id},
    );
  }

  @override
  Future<void> eliminarGrupo(String id) async {
    final usageCount = await _countMovementsUsingGroup(id);
    if (usageCount > 0) {
      throw StateError(
        'No puedes eliminar un grupo que ya está asociado a movimientos.',
      );
    }

    final current = await _findGroup(id);
    final now = DateTime.now();
    final nextStatus =
        current.syncStatus == 'pendingCreate'
            ? 'pendingDelete'
            : 'pendingDelete';

    await (_database.update(_database.movementGroups)
      ..where((tbl) => tbl.id.equals(id))).write(
      MovementGroupsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: Value(nextStatus),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.group,
      entityId: id,
      operation: SyncOperation.delete,
      payload: {'id': id},
    );
  }

  Future<void> _ensureUniqueCategoryName(
    String name, {
    String? excludingId,
  }) async {
    final matches =
        await (_database.select(_database.categories)
          ..where((tbl) => tbl.deletedAt.isNull())).get();
    final alreadyExists = matches.any(
      (row) =>
          row.name.toLowerCase() == name.toLowerCase() && row.id != excludingId,
    );

    if (alreadyExists) {
      throw StateError('Ya existe una categoría con ese nombre.');
    }
  }

  Future<void> _ensureUniqueGroupName(
    String name, {
    String? excludingId,
  }) async {
    final matches =
        await (_database.select(_database.movementGroups)
          ..where((tbl) => tbl.deletedAt.isNull())).get();
    final alreadyExists = matches.any(
      (row) =>
          row.name.toLowerCase() == name.toLowerCase() && row.id != excludingId,
    );

    if (alreadyExists) {
      throw StateError('Ya existe un grupo con ese nombre.');
    }
  }

  Future<Category> _findCategory(String id) async {
    final row =
        await (_database.select(_database.categories)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('La categoría no existe.');
    }
    return row;
  }

  Future<MovementGroup> _findGroup(String id) async {
    final row =
        await (_database.select(_database.movementGroups)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('El grupo no existe.');
    }
    return row;
  }

  Future<int> _countMovementsUsingCategory(String categoryId) async {
    final query =
        _database.selectOnly(_database.movements)
          ..addColumns([_database.movements.id.count()])
          ..where(
            _database.movements.categoriaId.equals(categoryId) &
                _database.movements.deletedAt.isNull(),
          );
    final row = await query.getSingle();
    return row.read(_database.movements.id.count()) ?? 0;
  }

  Future<int> _countMovementsUsingGroup(String groupId) async {
    final query =
        _database.selectOnly(_database.movements)
          ..addColumns([_database.movements.id.count()])
          ..where(
            _database.movements.grupoId.equals(groupId) &
                _database.movements.deletedAt.isNull(),
          );
    final row = await query.getSingle();
    return row.read(_database.movements.id.count()) ?? 0;
  }

  String _normalizeName(String rawName) {
    final value = rawName.trim();
    if (value.isEmpty) {
      throw StateError('El nombre no puede estar vacío.');
    }
    return value;
  }
}
