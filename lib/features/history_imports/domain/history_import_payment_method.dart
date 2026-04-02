enum HistoryImportPaymentMethod {
  pix(apiValue: 'PIX', label: 'PIX'),
  dinheiro(apiValue: 'DINHEIRO', label: 'Dinheiro'),
  debito(apiValue: 'DEBITO', label: 'Debito'),
  credito(apiValue: 'CREDITO', label: 'Credito'),
  transferencia(apiValue: 'TRANSFERENCIA', label: 'Transferencia'),
  boleto(apiValue: 'BOLETO', label: 'Boleto');

  const HistoryImportPaymentMethod({
    required this.apiValue,
    required this.label,
  });

  final String apiValue;
  final String label;

  static HistoryImportPaymentMethod fromApiValue(String value) {
    return values.firstWhere(
      (method) => method.apiValue == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Método de pagamento desconhecido.',
      ),
    );
  }
}
