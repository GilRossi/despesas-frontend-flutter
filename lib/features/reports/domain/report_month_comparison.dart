class ReportMonthComparison {
  const ReportMonthComparison({
    required this.currentMonth,
    required this.currentTotal,
    required this.previousMonth,
    required this.previousTotal,
    required this.deltaAmount,
    required this.deltaPercentage,
  });

  final String currentMonth;
  final double currentTotal;
  final String previousMonth;
  final double previousTotal;
  final double deltaAmount;
  final double deltaPercentage;

  factory ReportMonthComparison.fromJson(Map<String, dynamic> json) {
    return ReportMonthComparison(
      currentMonth: json['currentMonth'] as String? ?? '',
      currentTotal: _toDouble(json['currentTotal']),
      previousMonth: json['previousMonth'] as String? ?? '',
      previousTotal: _toDouble(json['previousTotal']),
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
