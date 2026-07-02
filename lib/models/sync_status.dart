enum SyncStatus {
  localOnly('localOnly'),
  pendingCreate('pendingCreate'),
  pendingUpdate('pendingUpdate'),
  pendingDelete('pendingDelete'),
  synced('synced'),
  syncError('syncError');

  const SyncStatus(this.storageValue);

  final String storageValue;

  String get label {
    switch (this) {
      case SyncStatus.localOnly:
        return 'Solo local';
      case SyncStatus.pendingCreate:
        return 'Pendiente de crear';
      case SyncStatus.pendingUpdate:
        return 'Pendiente de actualizar';
      case SyncStatus.pendingDelete:
        return 'Pendiente de eliminar';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.syncError:
        return 'Error de sincronización';
    }
  }

  static SyncStatus fromStorage(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => SyncStatus.localOnly,
    );
  }
}
