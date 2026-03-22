class ReportIncreaseAlert {
  const ReportIncreaseAlert({
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
    required this.deltaAmount,
    required this.deltaPercentage,
  });

  final String categoryName;
  final double currentAmount;
  final double previousAmount;
  final double deltaAmount;
  final double deltaPercentage;

  factory ReportIncreaseAlert.fromJson(Map<String, dynamic> json) {
    return ReportIncreaseAlert(
      categoryName: json['categoryName'] as String? ?? '',
      currentAmount: _toDouble(json['currentAmount']),
      previousAmount: _toDouble(json['previousAmount']),
      deltaAmount: _toDouble(json['deltaAmount']),
      deltaPercentage: _toDouble(json['deltaPercentage']),
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
