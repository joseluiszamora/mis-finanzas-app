class ResumenFinanciero {
  const ResumenFinanciero({
    required this.totalIngresosCents,
    required this.totalEgresosCents,
  });

  final int totalIngresosCents;
  final int totalEgresosCents;

  double get totalIngresos => totalIngresosCents / 100;
  double get totalEgresos => totalEgresosCents / 100;
  double get balance => (totalIngresosCents - totalEgresosCents) / 100;
}
