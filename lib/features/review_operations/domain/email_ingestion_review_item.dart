class EmailIngestionReviewItem {
  const EmailIngestionReviewItem({
    required this.description,
    required this.amount,
    required this.quantity,
  });

  final String description;
  final double amount;
  final double? quantity;

  factory EmailIngestionReviewItem.fromJson(Map<String, dynamic> json) {
    return EmailIngestionReviewItem(
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
      quantity: _toNullableDouble(json['quantity']),
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

  static double? _toNullableDouble(Object? value) {
    return switch (value) {
      null => null,
      int number => number.toDouble(),
      double number => number,
      String number => double.parse(number),
      _ => null,
    };
  }
}
