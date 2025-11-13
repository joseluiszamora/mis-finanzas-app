class Movimiento {
  final String fecha;
  final String mes;
  final String tipo; // 'Ingreso' o 'Egreso'
  final String categoria;
  final String concepto;
  final double monto;
  final String grupo;

  Movimiento({
    required this.fecha,
    required this.mes,
    required this.tipo,
    required this.categoria,
    required this.concepto,
    required this.monto,
    required this.grupo,
  });

  // Constructor desde una fila de Google Sheets
  factory Movimiento.fromSheetRow(List<dynamic> row) {
    String fechaStr = row.length > 0 ? row[0].toString() : '';

    // Si la fecha es un número (formato serial de Excel), convertirlo a fecha legible
    if (fechaStr.isNotEmpty && double.tryParse(fechaStr) != null) {
      // Es un número serial de Excel/Sheets (días desde 01/01/1900)
      final serialNumber = double.parse(fechaStr);
      // Google Sheets usa 30/12/1899 como día 1
      final baseDate = DateTime(1899, 12, 30);
      final fecha = baseDate.add(Duration(days: serialNumber.toInt()));
      fechaStr =
          '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    }

    return Movimiento(
      fecha: fechaStr,
      mes: row.length > 1 ? row[1].toString() : '',
      tipo: row.length > 2 ? row[2].toString() : '',
      categoria: row.length > 3 ? row[3].toString() : '',
      concepto: row.length > 4 ? row[4].toString() : '',
      monto: row.length > 5 ? double.tryParse(row[5].toString()) ?? 0.0 : 0.0,
      grupo: row.length > 6 ? row[6].toString() : '',
    );
  }

  // Convertir a lista para insertar en Google Sheets
  // Agregamos ' al inicio de la fecha para forzar formato texto
  List<dynamic> toSheetRow() {
    return ["'$fecha", mes, tipo, categoria, concepto, monto, grupo];
  }

  // Copiar con modificaciones
  Movimiento copyWith({
    String? fecha,
    String? mes,
    String? tipo,
    String? categoria,
    String? concepto,
    double? monto,
    String? grupo,
  }) {
    return Movimiento(
      fecha: fecha ?? this.fecha,
      mes: mes ?? this.mes,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      grupo: grupo ?? this.grupo,
    );
  }
}
