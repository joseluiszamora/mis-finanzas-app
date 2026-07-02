import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas/config/app_environment.dart';
import 'package:finanzas/data/local/app_database.dart';
import 'package:finanzas/data/repositories/catalogos_repository.dart';
import 'package:finanzas/data/repositories/movimientos_repository.dart';
import 'package:finanzas/data/sync/supabase_sync_service.dart';
import 'package:finanzas/data/sync/sync_coordinator.dart';
import 'package:finanzas/main.dart';
import 'package:finanzas/providers/movimientos_provider.dart';

void main() {
  testWidgets('arranca en modo local y muestra el estado vacio', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.seedDefaults();
    final syncCoordinator = _buildSyncCoordinator(database);
    final provider = MovimientosProvider(
      movimientosRepository: LocalMovimientosRepository(
        database: database,
        syncCoordinator: syncCoordinator,
      ),
      catalogosRepository: LocalCatalogosRepository(
        database: database,
        syncCoordinator: syncCoordinator,
      ),
      syncCoordinator: syncCoordinator,
    );
    await provider.init();

    await tester.pumpWidget(MyApp(provider: provider));
    await tester.pumpAndSettle();

    expect(
      find.text('Modo local activo. Todo se guarda en SQLite del dispositivo.'),
      findsOneWidget,
    );
    expect(find.text('No hay movimientos registrados'), findsOneWidget);
    expect(find.text('Google Sheets'), findsNothing);
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
