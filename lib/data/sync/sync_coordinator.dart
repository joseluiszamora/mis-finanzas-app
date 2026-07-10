import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../../config/app_environment.dart';
import '../local/app_database.dart';
import 'supabase_sync_service.dart';
import 'sync_state.dart';
import 'sync_types.dart';

class SyncCoordinator extends ChangeNotifier {
  SyncCoordinator({
    required AppDatabase database,
    required AppEnvironment environment,
    required RemoteSyncService remoteService,
    Uuid? uuid,
  }) : _database = database,
       _environment = environment,
       _remoteService = remoteService,
       _uuid = uuid ?? const Uuid();

  static const _lastSyncAllAtKey = 'last_sync_all_at';
  static const _lastSyncCategoriesAtKey = 'last_sync_categories_at';
  static const _lastSyncGroupsAtKey = 'last_sync_groups_at';
  static const _lastSyncMovementsAtKey = 'last_sync_transactions_at';

  final AppDatabase _database;
  final AppEnvironment _environment;
  final RemoteSyncService _remoteService;
  final Uuid _uuid;

  String? _currentUserId;
  SyncSnapshot _snapshot = const SyncSnapshot.localOnly();

  SyncSnapshot get snapshot => _snapshot;
  String? get currentUserId => _currentUserId;
  bool get isRemoteSyncEnabled =>
      _environment.canInitializeSupabase && _currentUserId != null;
  String get syncModeLabel => _snapshot.label;

  Future<void> setCurrentUserId(String? userId) async {
    _currentUserId = userId;
    await refreshSnapshot();
  }

  Future<void> enqueueMutation({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final existing =
        await (_database.select(_database.syncQueueEntries)..where(
          (tbl) =>
              tbl.entityType.equals(entityType.value) &
              tbl.entityId.equals(entityId) &
              tbl.operation.equals(operation.value),
        )).getSingleOrNull();
    if (existing != null) {
      return;
    }

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
    await refreshSnapshot();
  }

  Future<void> prepareInitialSyncForSignedInUser() async {
    if (!isRemoteSyncEnabled) {
      await refreshSnapshot();
      return;
    }

    final categories = await _database.select(_database.categories).get();
    for (final category in categories) {
      await _prepareEntity(
        entityType: SyncEntityType.category,
        entityId: category.id,
        syncStatus: category.syncStatus,
        deletedAt: category.deletedAt,
        setPendingCreate:
            () => (_database.update(_database.categories)
              ..where((tbl) => tbl.id.equals(category.id))).write(
              const CategoriesCompanion(syncStatus: Value('pendingCreate')),
            ),
      );
    }

    final groups = await _database.select(_database.movementGroups).get();
    for (final group in groups) {
      await _prepareEntity(
        entityType: SyncEntityType.group,
        entityId: group.id,
        syncStatus: group.syncStatus,
        deletedAt: group.deletedAt,
        setPendingCreate:
            () => (_database.update(_database.movementGroups)
              ..where((tbl) => tbl.id.equals(group.id))).write(
              const MovementGroupsCompanion(syncStatus: Value('pendingCreate')),
            ),
      );
    }

    final movements = await _database.select(_database.movements).get();
    for (final movement in movements) {
      await _prepareEntity(
        entityType: SyncEntityType.movement,
        entityId: movement.id,
        syncStatus: movement.syncStatus,
        deletedAt: movement.deletedAt,
        setPendingCreate:
            () => (_database.update(_database.movements)
              ..where((tbl) => tbl.id.equals(movement.id))).write(
              const MovementsCompanion(syncStatus: Value('pendingCreate')),
            ),
      );
    }

    await refreshSnapshot();
  }

  Future<void> pushPendingEntries() async {
    final ownerId = _currentUserId;
    if (!_environment.canInitializeSupabase || ownerId == null) {
      await refreshSnapshot();
      return;
    }

    final now = DateTime.now();
    final entries = await _database.select(_database.syncQueueEntries).get();
    final dueEntries =
        entries
            .where(
              (entry) =>
                  entry.nextRetryAt == null || !entry.nextRetryAt!.isAfter(now),
            )
            .toList()
          ..sort(_compareQueueEntries);

    String? lastError;
    for (final entry in dueEntries) {
      try {
        await _pushEntry(ownerId, entry);
        await (_database.delete(_database.syncQueueEntries)
          ..where((tbl) => tbl.id.equals(entry.id))).go();
        await _markEntitySyncedIfQueueEmpty(
          SyncEntityType.fromStorage(entry.entityType),
          entry.entityId,
        );
      } catch (e) {
        lastError = e.toString();
        await _markEntryFailed(entry, lastError);
      }
    }

    if (lastError != null) {
      await refreshSnapshot(
        phaseOverride: SyncPhase.error,
        lastError: lastError,
      );
      throw StateError(lastError);
    } else {
      await refreshSnapshot();
    }
  }

  Future<void> pullRemoteChanges() async {
    final ownerId = _currentUserId;
    if (!_environment.canInitializeSupabase || ownerId == null) {
      await refreshSnapshot();
      return;
    }

    final changes = await _remoteService.pullChanges(
      ownerId: ownerId,
      lastCategoriesSyncAt: await _readDateSetting(_lastSyncCategoriesAtKey),
      lastGroupsSyncAt: await _readDateSetting(_lastSyncGroupsAtKey),
      lastMovementsSyncAt: await _readDateSetting(_lastSyncMovementsAtKey),
    );

    final lastCategoryAt = await _applyRemoteCategories(changes.categories);
    final lastGroupAt = await _applyRemoteGroups(changes.groups);
    final lastMovementAt = await _applyRemoteMovements(changes.movements);

    if (lastCategoryAt != null) {
      await _writeDateSetting(_lastSyncCategoriesAtKey, lastCategoryAt);
    }
    if (lastGroupAt != null) {
      await _writeDateSetting(_lastSyncGroupsAtKey, lastGroupAt);
    }
    if (lastMovementAt != null) {
      await _writeDateSetting(_lastSyncMovementsAtKey, lastMovementAt);
    }
  }

  Future<void> synchronizeNow() async {
    if (!_environment.canInitializeSupabase || _currentUserId == null) {
      await refreshSnapshot();
      return;
    }

    await refreshSnapshot(phaseOverride: SyncPhase.syncing);
    try {
      await pushPendingEntries();
      await pullRemoteChanges();
      await _writeDateSetting(_lastSyncAllAtKey, DateTime.now());
      await refreshSnapshot();
    } catch (e) {
      await refreshSnapshot(phaseOverride: SyncPhase.error, lastError: '$e');
    }
  }

  Future<void> attemptSync() => synchronizeNow();

  Future<void> refreshSnapshot({
    SyncPhase? phaseOverride,
    String? lastError,
  }) async {
    final pendingCount = await _pendingQueueCount();
    final lastSyncedAt = await _readDateSetting(_lastSyncAllAtKey);
    final phase =
        phaseOverride ??
        (!_environment.canInitializeSupabase || _currentUserId == null
            ? SyncPhase.unauthenticated
            : pendingCount > 0
            ? SyncPhase.pending
            : SyncPhase.synced);

    _snapshot = SyncSnapshot(
      phase: phase,
      pendingCount: pendingCount,
      lastSyncedAt: lastSyncedAt,
      lastError: lastError,
    );
    notifyListeners();
  }

  Future<void> _prepareEntity({
    required SyncEntityType entityType,
    required String entityId,
    required String syncStatus,
    required DateTime? deletedAt,
    required Future<void> Function() setPendingCreate,
  }) async {
    if (syncStatus == 'synced') {
      return;
    }

    var operation = _operationForSyncStatus(syncStatus, deletedAt);
    if (syncStatus == 'localOnly') {
      await setPendingCreate();
      operation = SyncOperation.create;
    }

    await _ensureQueueEntry(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
    );
  }

  SyncOperation _operationForSyncStatus(
    String syncStatus,
    DateTime? deletedAt,
  ) {
    if (syncStatus == 'pendingDelete' || deletedAt != null) {
      return SyncOperation.delete;
    }
    if (syncStatus == 'pendingUpdate') {
      return SyncOperation.update;
    }
    return SyncOperation.create;
  }

  Future<void> _ensureQueueEntry({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
  }) async {
    final existing =
        await (_database.select(_database.syncQueueEntries)..where(
          (tbl) =>
              tbl.entityType.equals(entityType.value) &
              tbl.entityId.equals(entityId) &
              tbl.operation.equals(operation.value),
        )).getSingleOrNull();
    if (existing != null) {
      return;
    }

    await enqueueMutation(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: {'id': entityId},
    );
  }

  Future<void> _pushEntry(String ownerId, SyncQueueEntry entry) async {
    final entityType = SyncEntityType.fromStorage(entry.entityType);
    final operation = SyncOperation.fromStorage(entry.operation);
    switch (entityType) {
      case SyncEntityType.category:
        final category = await _findCategory(entry.entityId);
        if (operation == SyncOperation.delete) {
          await _remoteService.deleteCategory(
            ownerId: ownerId,
            category: category,
          );
        } else {
          await _remoteService.upsertCategory(
            ownerId: ownerId,
            category: category,
          );
        }
      case SyncEntityType.group:
        final group = await _findGroup(entry.entityId);
        if (operation == SyncOperation.delete) {
          await _remoteService.deleteGroup(ownerId: ownerId, group: group);
        } else {
          await _remoteService.upsertGroup(ownerId: ownerId, group: group);
        }
      case SyncEntityType.movement:
        final movement = await _findMovement(entry.entityId);
        if (operation == SyncOperation.delete) {
          await _remoteService.deleteMovement(
            ownerId: ownerId,
            movement: movement,
          );
        } else {
          await _remoteService.upsertMovement(
            ownerId: ownerId,
            movement: movement,
          );
        }
    }
  }

  Future<Category> _findCategory(String id) async {
    final row =
        await (_database.select(_database.categories)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('La categoría pendiente de sync no existe.');
    }
    return row;
  }

  Future<MovementGroup> _findGroup(String id) async {
    final row =
        await (_database.select(_database.movementGroups)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('El grupo pendiente de sync no existe.');
    }
    return row;
  }

  Future<Movement> _findMovement(String id) async {
    final row =
        await (_database.select(_database.movements)
          ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('El movimiento pendiente de sync no existe.');
    }
    return row;
  }

  Future<void> _markEntitySyncedIfQueueEmpty(
    SyncEntityType entityType,
    String entityId,
  ) async {
    final pending =
        await (_database.select(_database.syncQueueEntries)..where(
          (tbl) =>
              tbl.entityType.equals(entityType.value) &
              tbl.entityId.equals(entityId),
        )).getSingleOrNull();
    if (pending != null) {
      return;
    }

    switch (entityType) {
      case SyncEntityType.category:
        await (_database.update(_database.categories)..where(
          (tbl) => tbl.id.equals(entityId),
        )).write(const CategoriesCompanion(syncStatus: Value('synced')));
      case SyncEntityType.group:
        await (_database.update(_database.movementGroups)..where(
          (tbl) => tbl.id.equals(entityId),
        )).write(const MovementGroupsCompanion(syncStatus: Value('synced')));
      case SyncEntityType.movement:
        await (_database.update(_database.movements)..where(
          (tbl) => tbl.id.equals(entityId),
        )).write(const MovementsCompanion(syncStatus: Value('synced')));
    }
  }

  Future<void> _markEntryFailed(SyncQueueEntry entry, String error) async {
    final failureCount = entry.attemptCount + 1;
    final now = DateTime.now();
    await (_database.update(_database.syncQueueEntries)
      ..where((tbl) => tbl.id.equals(entry.id))).write(
      SyncQueueEntriesCompanion(
        attemptCount: Value(failureCount),
        lastError: Value(error),
        nextRetryAt: Value(now.add(_retryDelayForFailure(failureCount))),
        updatedAt: Value(now),
      ),
    );
  }

  Duration _retryDelayForFailure(int failureCount) {
    if (failureCount <= 1) {
      return const Duration(seconds: 30);
    }
    if (failureCount == 2) {
      return const Duration(minutes: 2);
    }
    if (failureCount == 3) {
      return const Duration(minutes: 10);
    }
    return const Duration(minutes: 30);
  }

  int _compareQueueEntries(SyncQueueEntry left, SyncQueueEntry right) {
    final typeComparison = _entityOrder(
      left.entityType,
    ).compareTo(_entityOrder(right.entityType));
    if (typeComparison != 0) {
      return typeComparison;
    }
    return left.createdAt.compareTo(right.createdAt);
  }

  int _entityOrder(String entityType) {
    switch (SyncEntityType.fromStorage(entityType)) {
      case SyncEntityType.category:
        return 0;
      case SyncEntityType.group:
        return 1;
      case SyncEntityType.movement:
        return 2;
    }
  }

  Future<DateTime?> _applyRemoteCategories(List<RemoteCategoryRow> rows) async {
    DateTime? lastApplied;
    for (final row in rows) {
      if (await _hasPendingMutation(SyncEntityType.category, row.id)) {
        break;
      }
      final local =
          await (_database.select(_database.categories)
            ..where((tbl) => tbl.id.equals(row.id))).getSingleOrNull();
      if (local == null || row.updatedAt.isAfter(local.updatedAt)) {
        await _database
            .into(_database.categories)
            .insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: row.id,
                name: row.name,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                deletedAt: Value(row.deletedAt),
                syncStatus: const Value('synced'),
              ),
            );
      }
      lastApplied = row.updatedAt;
    }
    return lastApplied;
  }

  Future<DateTime?> _applyRemoteGroups(List<RemoteGroupRow> rows) async {
    DateTime? lastApplied;
    for (final row in rows) {
      if (await _hasPendingMutation(SyncEntityType.group, row.id)) {
        break;
      }
      final local =
          await (_database.select(_database.movementGroups)
            ..where((tbl) => tbl.id.equals(row.id))).getSingleOrNull();
      if (local == null || row.updatedAt.isAfter(local.updatedAt)) {
        await _database
            .into(_database.movementGroups)
            .insertOnConflictUpdate(
              MovementGroupsCompanion.insert(
                id: row.id,
                name: row.name,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                deletedAt: Value(row.deletedAt),
                syncStatus: const Value('synced'),
              ),
            );
      }
      lastApplied = row.updatedAt;
    }
    return lastApplied;
  }

  Future<DateTime?> _applyRemoteMovements(List<RemoteMovementRow> rows) async {
    DateTime? lastApplied;
    for (final row in rows) {
      if (await _hasPendingMutation(SyncEntityType.movement, row.id)) {
        break;
      }
      final local =
          await (_database.select(_database.movements)
            ..where((tbl) => tbl.id.equals(row.id))).getSingleOrNull();
      if (local == null || row.updatedAt.isAfter(local.updatedAt)) {
        await _database
            .into(_database.movements)
            .insertOnConflictUpdate(
              MovementsCompanion.insert(
                id: row.id,
                tipo: row.tipo,
                categoriaId: row.categoriaId,
                grupoId: Value(row.grupoId),
                concepto: row.concepto,
                amountCents: row.amountCents,
                occurredAt: row.occurredAt,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                deletedAt: Value(row.deletedAt),
                syncStatus: const Value('synced'),
              ),
            );
      }
      lastApplied = row.updatedAt;
    }
    return lastApplied;
  }

  Future<bool> _hasPendingMutation(
    SyncEntityType entityType,
    String entityId,
  ) async {
    final pending =
        await (_database.select(_database.syncQueueEntries)..where(
          (tbl) =>
              tbl.entityType.equals(entityType.value) &
              tbl.entityId.equals(entityId),
        )).getSingleOrNull();
    return pending != null;
  }

  Future<int> _pendingQueueCount() async {
    final countExpression = _database.syncQueueEntries.id.count();
    final query = _database.selectOnly(_database.syncQueueEntries)
      ..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<DateTime?> _readDateSetting(String key) async {
    final row =
        await (_database.select(_database.appSettings)
          ..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    final value = row?.value;
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  Future<void> _writeDateSetting(String key, DateTime value) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: Value(value.toUtc().toIso8601String()),
            updatedAt: DateTime.now(),
          ),
        );
  }
}
