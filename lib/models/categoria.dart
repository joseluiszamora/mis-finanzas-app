import 'sync_status.dart';

class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });

  final String id;
  final String nombre;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get isActive => deletedAt == null;
}
