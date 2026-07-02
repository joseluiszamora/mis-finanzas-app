import 'package:intl/intl.dart';

import 'sync_status.dart';
import 'tipo_movimiento.dart';

class Movimiento {
  static const _groupSentinel = Object();

  const Movimiento({
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
    required this.syncStatus,
    this.categoriaNombre,
    this.grupoNombre,
  });

  final String id;
  final TipoMovimiento tipo;
  final String categoriaId;
  final String? grupoId;
  final String concepto;
  final int amountCents;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;
  final String? categoriaNombre;
  final String? grupoNombre;

  double get monto => amountCents / 100;
  String get fecha => DateFormat('dd/MM/yyyy').format(occurredAt);
  String get mes => DateFormat('MMMM', 'es').format(occurredAt);
  bool get isIngreso => tipo.isIngreso;
  bool get isDeleted => deletedAt != null;

  Movimiento copyWith({
    String? id,
    TipoMovimiento? tipo,
    String? categoriaId,
    Object? grupoId = _groupSentinel,
    String? concepto,
    int? amountCents,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    String? categoriaNombre,
    String? grupoNombre,
  }) {
    return Movimiento(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      grupoId:
          identical(grupoId, _groupSentinel)
              ? this.grupoId
              : grupoId as String?,
      concepto: concepto ?? this.concepto,
      amountCents: amountCents ?? this.amountCents,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      grupoNombre:
          identical(grupoId, _groupSentinel)
              ? (grupoNombre ?? this.grupoNombre)
              : grupoNombre,
    );
  }
}
