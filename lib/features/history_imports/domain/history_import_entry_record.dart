class HistoryImportEntryRecord {
  const HistoryImportEntryRecord({
    required this.expenseId,
    required this.paymentId,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
  });

  final int expenseId;
  final int paymentId;
  final String description;
  final double amount;
  final DateTime date;
  final String status;

  factory HistoryImportEntryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryImportEntryRecord(
      expenseId: _toInt(json['expenseId']),
      paymentId: _toInt(json['paymentId']),
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? '',
    );
  }

  static int _toInt(Object? value) {
    return switch (value) {
      int number => number,
      double number => number.toInt(),
      String number => int.parse(number),
      _ => 0,
    };
  }

  static double _toDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String number => double.parse(number),
      _ => 0,
    };
  }
}
