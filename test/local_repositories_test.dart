import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas/config/app_environment.dart';
import 'package:finanzas/data/local/app_database.dart';
import 'package:finanzas/data/repositories/catalogos_repository.dart';
import 'package:finanzas/data/repositories/movimientos_repository.dart';
import 'package:finanzas/data/sync/supabase_sync_service.dart';
import 'package:finanzas/data/sync/sync_coordinator.dart';
import 'package:finanzas/data/sync/sync_types.dart';
import 'package:finanzas/models/tipo_movimiento.dart';

void main() {
  late AppDatabase database;
  late SyncCoordinator syncCoordinator;
  late LocalCatalogosRepository catalogosRepository;
  late LocalMovimientosRepository movimientosRepository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.seedDefaults();
    syncCoordinator = _buildSyncCoordinator(database);
    catalogosRepository = LocalCatalogosRepository(
      database: database,
      syncCoordinator: syncCoordinator,
    );
    movimientosRepository = LocalMovimientosRepository(
      database: database,
      syncCoordinator: syncCoordinator,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('crea, actualiza y elimina catalogos locales', () async {
    final categoria = await catalogosRepository.crearCategoria('Mascotas');
    final grupo = await catalogosRepository.crearGrupo('Casa');

    await catalogosRepository.actualizarCategoria(categoria.id, 'Mascotas 2');
    await catalogosRepository.actualizarGrupo(grupo.id, 'Casa 2');

    final categorias = await catalogosRepository.obtenerCategorias();
    final grupos = await catalogosRepository.obtenerGrupos();

    expect(categorias.any((item) => item.nombre == 'Mascotas 2'), isTrue);
    expect(grupos.any((item) => item.nombre == 'Casa 2'), isTrue);

    await catalogosRepository.eliminarCategoria(categoria.id);
    await catalogosRepository.eliminarGrupo(grupo.id);

    final categoriasRestantes = await catalogosRepository.obtenerCategorias();
    final gruposRestantes = await catalogosRepository.obtenerGrupos();

    expect(categoriasRestantes.any((item) => item.id == categoria.id), isFalse);
    expect(gruposRestantes.any((item) => item.id == grupo.id), isFalse);
  });

  test(
    'elimina una categoria usada sin perder movimientos historicos',
    () async {
      final categoria = await catalogosRepository.crearCategoria('Mascotas');
      final movimiento = await movimientosRepository.crearMovimiento(
        MovimientoDraft(
          tipo: TipoMovimiento.egreso,
          categoriaId: categoria.id,
          grupoId: null,
          concepto: 'Vacunas',
          amountCents: 20000,
          occurredAt: DateTime(2026, 6, 5),
        ),
      );

      await catalogosRepository.eliminarCategoria(categoria.id);

      final categorias = await catalogosRepository.obtenerCategorias();
      final movimientos = await movimientosRepository.obtenerMovimientos();

      expect(categorias.any((item) => item.id == categoria.id), isFalse);
      expect(movimientos.single.id, movimiento.id);
      expect(movimientos.single.categoriaNombre, 'Mascotas');

      await expectLater(
        movimientosRepository.crearMovimiento(
          MovimientoDraft(
            tipo: TipoMovimiento.egreso,
            categoriaId: categoria.id,
            grupoId: null,
            concepto: 'Alimento',
            amountCents: 15000,
            occurredAt: DateTime(2026, 6, 6),
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('crea, edita y elimina movimientos por id estable', () async {
    final categorias = await catalogosRepository.obtenerCategorias();
    final categoriaId = categorias.first.id;

    final primero = await movimientosRepository.crearMovimiento(
      MovimientoDraft(
        tipo: TipoMovimiento.egreso,
        categoriaId: categoriaId,
        grupoId: null,
        concepto: 'Compra 1',
        amountCents: 1200,
        occurredAt: DateTime(2026, 6, 1),
      ),
    );
    final segundo = await movimientosRepository.crearMovimiento(
      MovimientoDraft(
        tipo: TipoMovimiento.ingreso,
        categoriaId: categoriaId,
        grupoId: null,
        concepto: 'Ingreso 2',
        amountCents: 5000,
        occurredAt: DateTime(2026, 6, 3),
      ),
    );

    final ordered = await movimientosRepository.obtenerMovimientos();
    expect(ordered.first.id, segundo.id);
    expect(ordered.last.id, primero.id);

    await movimientosRepository.actualizarMovimiento(
      primero.id,
      MovimientoDraft(
        tipo: TipoMovimiento.egreso,
        categoriaId: categoriaId,
        grupoId: null,
        concepto: 'Compra 1 editada',
        amountCents: 1500,
        occurredAt: DateTime(2026, 6, 1),
      ),
    );

    final updated = await movimientosRepository.obtenerMovimientos();
    expect(
      updated.any(
        (item) => item.id == primero.id && item.concepto == 'Compra 1 editada',
      ),
      isTrue,
    );

    await movimientosRepository.eliminarMovimiento(segundo.id);
    final remaining = await movimientosRepository.obtenerMovimientos();

    expect(remaining.length, 1);
    expect(remaining.single.id, primero.id);
  });

  test('calcula resumen y encola sync local en create update delete', () async {
    final categorias = await catalogosRepository.obtenerCategorias();
    final categoriaId = categorias.first.id;

    final movimiento = await movimientosRepository.crearMovimiento(
      MovimientoDraft(
        tipo: TipoMovimiento.ingreso,
        categoriaId: categoriaId,
        grupoId: null,
        concepto: 'Salario',
        amountCents: 100000,
        occurredAt: DateTime(2026, 6, 10),
      ),
    );

    await movimientosRepository.actualizarMovimiento(
      movimiento.id,
      MovimientoDraft(
        tipo: TipoMovimiento.egreso,
        categoriaId: categoriaId,
        grupoId: null,
        concepto: 'Alquiler',
        amountCents: 35000,
        occurredAt: DateTime(2026, 6, 11),
      ),
    );
    await movimientosRepository.eliminarMovimiento(movimiento.id);

    final resumen = await movimientosRepository.obtenerResumen();
    final queueEntries = await database.select(database.syncQueueEntries).get();

    expect(resumen.totalIngresosCents, 0);
    expect(resumen.totalEgresosCents, 0);
    expect(queueEntries.length, 3);
    expect(queueEntries.map((entry) => entry.operation), [
      'create',
      'update',
      'delete',
    ]);
  });

  test('prepara primer sync y vacia la cola al subir datos locales', () async {
    final remote = _FakeRemoteSyncService();
    syncCoordinator = _buildSyncCoordinator(
      database,
      environment: const AppEnvironment(
        enableRemoteSync: true,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
        googleClientId: '',
        googleServerClientId: '',
      ),
      remoteService: remote,
    );

    await syncCoordinator.setCurrentUserId('user-1');
    await syncCoordinator.prepareInitialSyncForSignedInUser();

    final queuedBefore = await database.select(database.syncQueueEntries).get();
    expect(queuedBefore, isNotEmpty);

    await syncCoordinator.synchronizeNow();

    final queuedAfter = await database.select(database.syncQueueEntries).get();
    final categorias = await database.select(database.categories).get();
    final grupos = await database.select(database.movementGroups).get();

    expect(queuedAfter, isEmpty);
    expect(categorias.every((item) => item.syncStatus == 'synced'), isTrue);
    expect(grupos.every((item) => item.syncStatus == 'synced'), isTrue);
    expect(remote.operations.first.startsWith('category:'), isTrue);
    expect(remote.operations.last.startsWith('group:'), isTrue);
  });

  test('pull incremental inserta cambios remotos nuevos', () async {
    final remote = _FakeRemoteSyncService(
      changes: RemoteChanges(
        categories: [
          RemoteCategoryRow(
            id: 'remote-category-1',
            name: 'Remota',
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 1, 1),
            deletedAt: null,
          ),
        ],
        groups: const [],
        movements: const [],
      ),
    );
    syncCoordinator = _buildSyncCoordinator(
      database,
      environment: const AppEnvironment(
        enableRemoteSync: true,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
        googleClientId: '',
        googleServerClientId: '',
      ),
      remoteService: remote,
    );

    await syncCoordinator.setCurrentUserId('user-1');
    await syncCoordinator.pullRemoteChanges();

    final categorias = await database.select(database.categories).get();
    expect(
      categorias.any(
        (item) =>
            item.id == 'remote-category-1' &&
            item.name == 'Remota' &&
            item.syncStatus == 'synced',
      ),
      isTrue,
    );
  });

  test(
    'pull no sobrescribe entidades con mutaciones locales pendientes',
    () async {
      final categoria = await catalogosRepository.crearCategoria('Local');
      final remote = _FakeRemoteSyncService(
        changes: RemoteChanges(
          categories: [
            RemoteCategoryRow(
              id: categoria.id,
              name: 'Remota',
              createdAt: categoria.createdAt,
              updatedAt: categoria.updatedAt.add(const Duration(hours: 1)),
              deletedAt: null,
            ),
          ],
          groups: const [],
          movements: const [],
        ),
      );
      syncCoordinator = _buildSyncCoordinator(
        database,
        environment: const AppEnvironment(
          enableRemoteSync: true,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon',
          googleClientId: '',
          googleServerClientId: '',
        ),
        remoteService: remote,
      );

      await syncCoordinator.setCurrentUserId('user-1');
      await syncCoordinator.pullRemoteChanges();

      final local =
          await (database.select(database.categories)
            ..where((tbl) => tbl.id.equals(categoria.id))).getSingle();
      final cursor =
          await (database.select(database.appSettings)..where(
            (tbl) => tbl.key.equals('last_sync_categories_at'),
          )).getSingleOrNull();

      expect(local.name, 'Local');
      expect(cursor, isNull);
    },
  );
}

SyncCoordinator _buildSyncCoordinator(
  AppDatabase database, {
  AppEnvironment environment = const AppEnvironment(
    enableRemoteSync: false,
    supabaseUrl: '',
    supabaseAnonKey: '',
    googleClientId: '',
    googleServerClientId: '',
  ),
  RemoteSyncService? remoteService,
}) {
  return SyncCoordinator(
    database: database,
    environment: environment,
    remoteService:
        remoteService ?? SupabaseSyncService(environment: environment),
  );
}

class _FakeRemoteSyncService implements RemoteSyncService {
  _FakeRemoteSyncService({
    this.changes = const RemoteChanges(
      categories: [],
      groups: [],
      movements: [],
    ),
  });

  final RemoteChanges changes;
  final List<String> operations = [];

  @override
  Future<RemoteChanges> pullChanges({
    required String ownerId,
    required DateTime? lastCategoriesSyncAt,
    required DateTime? lastGroupsSyncAt,
    required DateTime? lastMovementsSyncAt,
  }) async {
    return changes;
  }

  @override
  Future<void> upsertCategory({
    required String ownerId,
    required Category category,
  }) async {
    operations.add('category:upsert:${category.id}');
  }

  @override
  Future<void> upsertGroup({
    required String ownerId,
    required MovementGroup group,
  }) async {
    operations.add('group:upsert:${group.id}');
  }

  @override
  Future<void> upsertMovement({
    required String ownerId,
    required Movement movement,
  }) async {
    operations.add('movement:upsert:${movement.id}');
  }

  @override
  Future<void> deleteCategory({
    required String ownerId,
    required Category category,
  }) async {
    operations.add('category:delete:${category.id}');
  }

  @override
  Future<void> deleteGroup({
    required String ownerId,
    required MovementGroup group,
  }) async {
    operations.add('group:delete:${group.id}');
  }

  @override
  Future<void> deleteMovement({
    required String ownerId,
    required Movement movement,
  }) async {
    operations.add('movement:delete:${movement.id}');
  }
}
