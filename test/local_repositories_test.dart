import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas/config/app_environment.dart';
import 'package:finanzas/data/local/app_database.dart';
import 'package:finanzas/data/repositories/catalogos_repository.dart';
import 'package:finanzas/data/repositories/movimientos_repository.dart';
import 'package:finanzas/data/sync/supabase_sync_service.dart';
import 'package:finanzas/data/sync/sync_coordinator.dart';
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
}

SyncCoordinator _buildSyncCoordinator(AppDatabase database) {
  const environment = AppEnvironment(
    enableRemoteSync: false,
    supabaseUrl: '',
    supabaseAnonKey: '',
  );

  return SyncCoordinator(
    database: database,
    environment: environment,
    remoteService: const SupabaseSyncService(environment: environment),
  );
}
