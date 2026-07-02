import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_environment.dart';
import '../local/app_database.dart';
import 'supabase_sync_service.dart';

enum SyncEntityType {
  movement('movement'),
  category('category'),
  group('group');

  const SyncEntityType(this.value);
  final String value;
}

enum SyncOperation {
  create('create'),
  update('update'),
  delete('delete');

  const SyncOperation(this.value);
  final String value;
}

class SyncCoordinator {
  SyncCoordinator({
    required AppDatabase database,
    required AppEnvironment environment,
    required SupabaseSyncService remoteService,
    Uuid? uuid,
  }) : _database = database,
       _environment = environment,
       _remoteService = remoteService,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final AppEnvironment _environment;
  final SupabaseSyncService _remoteService;
  final Uuid _uuid;

  bool get isRemoteSyncEnabled => _environment.enableRemoteSync;

  String get syncModeLabel =>
      isRemoteSyncEnabled ? 'Sync remoto preparado' : 'Modo local activo';

  Future<void> enqueueMutation({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await _database
        .into(_database.syncQueueEntries)
        .insert(
          SyncQueueEntriesCompanion.insert(
            id: _uuid.v4(),
            entityType: entityType.value,
            entityId: entityId,
            operation: operation.value,
            payloadJson: jsonEncode(payload),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> attemptSync() async {
    if (!_environment.enableRemoteSync) {
      return;
    }

    final entries =
        await (_database.select(_database.syncQueueEntries)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])).get();

    for (final entry in entries) {
      try {
        await _remoteService.pushMutation(jsonDecode(entry.payloadJson));
      } catch (_) {
        await (_database.update(_database.syncQueueEntries)
          ..where((tbl) => tbl.id.equals(entry.id))).write(
          SyncQueueEntriesCompanion(
            attemptCount: Value(entry.attemptCount + 1),
            lastError: const Value(
              'La sincronización remota no está activa en esta fase.',
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }
}
