String formatCurrency(double amount) {
  final absolute = amount.abs().toStringAsFixed(2);
  final parts = absolute.split('.');
  final integerPart = parts.first;
  final decimalPart = parts.last;
  final grouped = <String>[];

  for (var index = integerPart.length; index > 0; index -= 3) {
    final start = (index - 3).clamp(0, integerPart.length);
    grouped.insert(0, integerPart.substring(start, index));
  }

  final prefix = amount < 0 ? '-R\$ ' : 'R\$ ';
  return '$prefix${grouped.join('.')},$decimalPart';
}
