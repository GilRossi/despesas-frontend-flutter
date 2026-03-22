class ReportCategoryTotal {
  const ReportCategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.expensesCount,
    required this.sharePercentage,
  });

  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final int expensesCount;
  final double sharePercentage;

  factory ReportCategoryTotal.fromJson(Map<String, dynamic> json) {
    return ReportCategoryTotal(
      categoryId: _toInt(json['categoryId']),
      categoryName: json['categoryName'] as String? ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      expensesCount: _toInt(json['expensesCount']),
      sharePercentage: _toDouble(json['sharePercentage']),
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
