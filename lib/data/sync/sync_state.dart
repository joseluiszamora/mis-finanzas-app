enum SyncPhase { unauthenticated, pending, syncing, synced, error }

class SyncSnapshot {
  const SyncSnapshot({
    required this.phase,
    required this.pendingCount,
    required this.lastSyncedAt,
    required this.lastError,
  });

  const SyncSnapshot.localOnly()
    : phase = SyncPhase.unauthenticated,
      pendingCount = 0,
      lastSyncedAt = null,
      lastError = null;

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  bool get isSyncing => phase == SyncPhase.syncing;
  bool get hasError => phase == SyncPhase.error;

  String get label {
    switch (phase) {
      case SyncPhase.unauthenticated:
        return 'Modo local';
      case SyncPhase.pending:
        return 'Cambios pendientes';
      case SyncPhase.syncing:
        return 'Sincronizando';
      case SyncPhase.synced:
        return 'Sincronizado';
      case SyncPhase.error:
        return 'Error de sincronización';
    }
  }
}
