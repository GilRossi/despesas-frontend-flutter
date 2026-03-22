class ReportTopExpense {
  const ReportTopExpense({
    required this.expenseId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.categoryName,
    required this.subcategoryName,
    required this.context,
  });

  final int expenseId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String categoryName;
  final String subcategoryName;
  final String context;

  factory ReportTopExpense.fromJson(Map<String, dynamic> json) {
    return ReportTopExpense(
      expenseId: _toInt(json['expenseId']),
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
      dueDate: DateTime.parse('${json['dueDate']}T00:00:00'),
      categoryName: json['categoryName'] as String? ?? '',
      subcategoryName: json['subcategoryName'] as String? ?? '',
      context: json['context'] as String? ?? '',
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
