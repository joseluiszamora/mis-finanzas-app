enum SyncEntityType {
  movement('movement'),
  category('category'),
  group('group');

  const SyncEntityType(this.value);
  final String value;

  static SyncEntityType fromStorage(String value) {
    return SyncEntityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw StateError('Tipo de entidad sync inválido: $value'),
    );
  }
}

enum SyncOperation {
  create('create'),
  update('update'),
  delete('delete');

  const SyncOperation(this.value);
  final String value;

  static SyncOperation fromStorage(String value) {
    return SyncOperation.values.firstWhere(
      (operation) => operation.value == value,
      orElse:
          () =>
              throw StateError('Operación de sincronización inválida: $value'),
    );
  }
}

class RemoteCategoryRow {
  const RemoteCategoryRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class RemoteGroupRow {
  const RemoteGroupRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class RemoteMovementRow {
  const RemoteMovementRow({
    required this.id,
    required this.tipo,
    required this.categoriaId,
    required this.grupoId,
    required this.concepto,
    required this.amountCents,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String tipo;
  final String categoriaId;
  final String? grupoId;
  final String concepto;
  final int amountCents;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class RemoteChanges {
  const RemoteChanges({
    required this.categories,
    required this.groups,
    required this.movements,
  });

  final List<RemoteCategoryRow> categories;
  final List<RemoteGroupRow> groups;
  final List<RemoteMovementRow> movements;
}
