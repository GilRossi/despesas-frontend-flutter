import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';

class ReportInsights {
  const ReportInsights({
    required this.monthComparison,
    required this.increaseAlerts,
    required this.recurringExpenses,
  });

  final ReportMonthComparison? monthComparison;
  final List<ReportIncreaseAlert> increaseAlerts;
  final List<ReportRecurringExpense> recurringExpenses;

  factory ReportInsights.fromJson(Map<String, dynamic> json) {
    final rawComparison = json['monthComparison'];

    return ReportInsights(
      monthComparison: rawComparison is Map<String, dynamic>
          ? ReportMonthComparison.fromJson(rawComparison)
          : null,
      increaseAlerts: (json['increaseAlerts'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ReportIncreaseAlert.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      recurringExpenses:
          (json['recurringExpenses'] as List<dynamic>? ?? const [])
              .map(
                (item) => ReportRecurringExpense.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
    );
  }
}
