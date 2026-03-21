import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';

class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.totalExpenses,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.highestSpendingCategory,
    required this.categoryTotals,
    required this.topExpenses,
  });

  final DateTime from;
  final DateTime to;
  final int totalExpenses;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String highestSpendingCategory;
  final List<ReportCategoryTotal> categoryTotals;
  final List<ReportTopExpense> topExpenses;

  bool get hasData => totalExpenses > 0;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      from: DateTime.parse('${json['from']}T00:00:00'),
      to: DateTime.parse('${json['to']}T00:00:00'),
      totalExpenses: _toInt(json['totalExpenses']),
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      highestSpendingCategory: json['highestSpendingCategory'] as String? ?? '',
      categoryTotals: (json['categoryTotals'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ReportCategoryTotal.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      topExpenses: (json['topExpenses'] as List<dynamic>? ?? const [])
          .map(
            (item) => ReportTopExpense.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
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
