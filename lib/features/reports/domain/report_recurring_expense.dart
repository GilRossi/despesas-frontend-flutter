class ReportRecurringExpense {
  const ReportRecurringExpense({
    required this.description,
    required this.categoryName,
    required this.subcategoryName,
    required this.averageAmount,
    required this.occurrences,
    required this.likelyFixedAmount,
    required this.lastOccurrence,
  });

  final String description;
  final String categoryName;
  final String subcategoryName;
  final double averageAmount;
  final int occurrences;
  final bool likelyFixedAmount;
  final DateTime lastOccurrence;

  factory ReportRecurringExpense.fromJson(Map<String, dynamic> json) {
    return ReportRecurringExpense(
      description: json['description'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      subcategoryName: json['subcategoryName'] as String? ?? '',
      averageAmount: _toDouble(json['averageAmount']),
      occurrences: _toInt(json['occurrences']),
      likelyFixedAmount: json['likelyFixedAmount'] as bool? ?? false,
      lastOccurrence: DateTime.parse('${json['lastOccurrence']}T00:00:00'),
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
