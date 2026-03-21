class ExpensePayment {
  const ExpensePayment({
    required this.id,
    required this.expenseId,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.notes,
  });

  final int id;
  final int expenseId;
  final double amount;
  final DateTime paidAt;
  final String method;
  final String notes;

  bool get hasNotes => notes.trim().isNotEmpty;

  factory ExpensePayment.fromJson(Map<String, dynamic> json) {
    return ExpensePayment(
      id: json['id'] as int,
      expenseId: json['expenseId'] as int,
      amount: _toDouble(json['amount']),
      paidAt: DateTime.parse('${json['paidAt']}T00:00:00'),
      method: json['method'] as String,
      notes: json['notes'] as String? ?? '',
    );
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
