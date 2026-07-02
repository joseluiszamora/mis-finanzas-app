enum TipoMovimiento {
  ingreso('ingreso', 'Ingreso'),
  egreso('egreso', 'Egreso');

  const TipoMovimiento(this.storageValue, this.label);

  final String storageValue;
  final String label;

  bool get isIngreso => this == TipoMovimiento.ingreso;

  static TipoMovimiento fromStorage(String value) {
    return TipoMovimiento.values.firstWhere(
      (tipo) => tipo.storageValue == value,
      orElse: () => TipoMovimiento.egreso,
    );
  }

  static TipoMovimiento fromLabel(String value) {
    return TipoMovimiento.values.firstWhere(
      (tipo) => tipo.label.toLowerCase() == value.toLowerCase(),
      orElse: () => TipoMovimiento.egreso,
    );
  }
}
