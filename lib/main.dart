import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_environment.dart';
import 'data/local/app_database.dart';
import 'data/repositories/catalogos_repository.dart';
import 'data/repositories/movimientos_repository.dart';
import 'data/sync/supabase_sync_service.dart';
import 'data/sync/sync_coordinator.dart';
import 'providers/movimientos_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  final environment = AppEnvironment.fromEnvironment();
  if (environment.canInitializeSupabase) {
    await Supabase.initialize(
      url: environment.supabaseUrl,
      publishableKey: environment.supabaseAnonKey,
    );
  }

  final database = AppDatabase();
  await database.seedDefaults();
  final syncService = SupabaseSyncService(environment: environment);
  final syncCoordinator = SyncCoordinator(
    database: database,
    environment: environment,
    remoteService: syncService,
  );
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

  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.provider});

  final MovimientosProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MovimientosProvider>.value(
      value: provider,
      child: MaterialApp(
        title: 'Mis Finanzas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            primary: Colors.teal,
          ),
          useMaterial3: true,
        ),
        locale: const Locale('es', 'ES'),
        home: const HomeScreen(),
      ),
    );
  }
}
