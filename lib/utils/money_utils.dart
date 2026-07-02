int parseAmountToCents(String rawValue) {
  final normalized = rawValue.trim().replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) {
    throw const FormatException('Monto inválido');
  }
  return (value * 100).round();
}

String normalizeAmountInput(String rawValue) {
  return rawValue.trim().replaceAll(',', '.');
}
