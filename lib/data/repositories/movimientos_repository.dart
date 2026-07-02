import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/movimiento.dart';
import '../../models/resumen_financiero.dart';
import '../../models/sync_status.dart';
import '../../models/tipo_movimiento.dart';
import '../local/app_database.dart';
import '../sync/sync_coordinator.dart';

abstract class MovimientosRepository {
  Future<List<Movimiento>> obtenerMovimientos();
  Future<Movimiento> crearMovimiento(MovimientoDraft draft);
  Future<void> actualizarMovimiento(String id, MovimientoDraft draft);
  Future<void> eliminarMovimiento(String id);
  Future<ResumenFinanciero> obtenerResumen();
}

class MovimientoDraft {
  const MovimientoDraft({
    required this.tipo,
    required this.categoriaId,
    required this.grupoId,
    required this.concepto,
    required this.amountCents,
    required this.occurredAt,
  });

  final TipoMovimiento tipo;
  final String categoriaId;
  final String? grupoId;
  final String concepto;
  final int amountCents;
  final DateTime occurredAt;
}

class LocalMovimientosRepository implements MovimientosRepository {
  LocalMovimientosRepository({
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
  Future<List<Movimiento>> obtenerMovimientos() async {
    final query =
        _database.select(_database.movements).join([
            innerJoin(
              _database.categories,
              _database.categories.id.equalsExp(
                _database.movements.categoriaId,
              ),
            ),
            leftOuterJoin(
              _database.movementGroups,
              _database.movementGroups.id.equalsExp(
                _database.movements.grupoId,
              ),
            ),
          ])
          ..where(_database.movements.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.desc(_database.movements.occurredAt),
            OrderingTerm.desc(_database.movements.createdAt),
          ]);

    final rows = await query.get();
    return rows.map(_mapJoinedRow).toList();
  }

  @override
  Future<Movimiento> crearMovimiento(MovimientoDraft draft) async {
    await _assertCategoryExists(draft.categoriaId);
    if (draft.grupoId != null) {
      await _assertGroupExists(draft.grupoId!);
    }

    final now = DateTime.now();
    final id = _uuid.v4();
    final companion = MovementsCompanion.insert(
      id: id,
      tipo: draft.tipo.storageValue,
      categoriaId: draft.categoriaId,
      grupoId: Value(draft.grupoId),
      concepto: draft.concepto.trim(),
      amountCents: draft.amountCents,
      occurredAt: draft.occurredAt,
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pendingCreate'),
    );

    await _database.into(_database.movements).insert(companion);
    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.movement,
      entityId: id,
      operation: SyncOperation.create,
      payload: _movementPayload(
        id: id,
        draft: draft,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        syncStatus: SyncStatus.pendingCreate,
      ),
    );

    return (await obtenerMovimientos()).firstWhere((row) => row.id == id);
  }

  @override
  Future<void> actualizarMovimiento(String id, MovimientoDraft draft) async {
    await _assertCategoryExists(draft.categoriaId);
    if (draft.grupoId != null) {
      await _assertGroupExists(draft.grupoId!);
    }

    final current =
        await (_database.select(_database.movements)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAt != null) {
      throw StateError('El movimiento no existe.');
    }

    final now = DateTime.now();
    final nextStatus =
        current.syncStatus == 'pendingCreate'
            ? 'pendingCreate'
            : 'pendingUpdate';

    await (_database.update(_database.movements)
      ..where((tbl) => tbl.id.equals(id))).write(
      MovementsCompanion(
        tipo: Value(draft.tipo.storageValue),
        categoriaId: Value(draft.categoriaId),
        grupoId: Value(draft.grupoId),
        concepto: Value(draft.concepto.trim()),
        amountCents: Value(draft.amountCents),
        occurredAt: Value(draft.occurredAt),
        updatedAt: Value(now),
        syncStatus: Value(nextStatus),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.movement,
      entityId: id,
      operation: SyncOperation.update,
      payload: _movementPayload(
        id: id,
        draft: draft,
        createdAt: current.createdAt,
        updatedAt: now,
        deletedAt: current.deletedAt,
        syncStatus: SyncStatus.fromStorage(nextStatus),
      ),
    );
  }

  @override
  Future<void> eliminarMovimiento(String id) async {
    final current =
        await (_database.select(_database.movements)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAt != null) {
      throw StateError('El movimiento no existe.');
    }

    final now = DateTime.now();
    await (_database.update(_database.movements)
      ..where((tbl) => tbl.id.equals(id))).write(
      MovementsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pendingDelete'),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      entityType: SyncEntityType.movement,
      entityId: id,
      operation: SyncOperation.delete,
      payload: {'id': id, 'deletedAt': now.toIso8601String()},
    );
  }

  @override
  Future<ResumenFinanciero> obtenerResumen() async {
    final movimientos = await obtenerMovimientos();
    var ingresos = 0;
    var egresos = 0;
    for (final movimiento in movimientos) {
      if (movimiento.tipo == TipoMovimiento.ingreso) {
        ingresos += movimiento.amountCents;
      } else {
        egresos += movimiento.amountCents;
      }
    }
    return ResumenFinanciero(
      totalIngresosCents: ingresos,
      totalEgresosCents: egresos,
    );
  }

  Movimiento _mapJoinedRow(TypedResult row) {
    final movement = row.readTable(_database.movements);
    final category = row.readTable(_database.categories);
    final group = row.readTableOrNull(_database.movementGroups);

    return Movimiento(
      id: movement.id,
      tipo: TipoMovimiento.fromStorage(movement.tipo),
      categoriaId: movement.categoriaId,
      grupoId: movement.grupoId,
      concepto: movement.concepto,
      amountCents: movement.amountCents,
      occurredAt: movement.occurredAt,
      createdAt: movement.createdAt,
      updatedAt: movement.updatedAt,
      deletedAt: movement.deletedAt,
      syncStatus: SyncStatus.fromStorage(movement.syncStatus),
      categoriaNombre: category.name,
      grupoNombre: group?.name,
    );
  }

  Map<String, dynamic> _movementPayload({
    required String id,
    required MovimientoDraft draft,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) {
    return {
      'id': id,
      'tipo': draft.tipo.storageValue,
      'categoriaId': draft.categoriaId,
      'grupoId': draft.grupoId,
      'concepto': draft.concepto.trim(),
      'amountCents': draft.amountCents,
      'occurredAt': draft.occurredAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus.storageValue,
    };
  }

  Future<void> _assertCategoryExists(String id) async {
    final row =
        await (_database.select(_database.categories)..where(
          (tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull(),
        )).getSingleOrNull();
    if (row == null) {
      throw StateError('La categoría seleccionada no existe.');
    }
  }

  Future<void> _assertGroupExists(String id) async {
    final row =
        await (_database.select(_database.movementGroups)..where(
          (tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull(),
        )).getSingleOrNull();
    if (row == null) {
      throw StateError('El grupo seleccionado no existe.');
    }
  }
}
