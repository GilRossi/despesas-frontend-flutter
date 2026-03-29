import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_insights.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a full report snapshot with nested totals and insights', () {
    final summary = ReportSummary.fromJson({
      'from': '2026-03-01',
      'to': '2026-03-31',
      'totalExpenses': '12',
      'totalAmount': 450.75,
      'paidAmount': '320.25',
      'remainingAmount': 130.5,
      'highestSpendingCategory': 'Moradia',
      'categoryTotals': [
        {
          'categoryId': '7',
          'categoryName': 'Moradia',
          'totalAmount': '240.5',
          'expensesCount': 4,
          'sharePercentage': '53.4',
        },
      ],
      'topExpenses': [
        {
          'expenseId': 99,
          'description': 'Aluguel',
          'amount': '1200.50',
          'dueDate': '2026-03-10',
          'categoryName': 'Moradia',
          'subcategoryName': 'Aluguel',
          'context': 'casa',
        },
      ],
    });

    final insights = ReportInsights.fromJson({
      'monthComparison': {
        'currentMonth': '2026-03',
        'currentTotal': '450.75',
        'previousMonth': '2026-02',
        'previousTotal': 300,
        'deltaAmount': '150.75',
        'deltaPercentage': 50,
      },
      'increaseAlerts': [
        {
          'categoryName': 'Lazer',
          'currentAmount': 200,
          'previousAmount': '100',
          'deltaAmount': 100,
          'deltaPercentage': '100',
        },
      ],
      'recurringExpenses': [
        {
          'description': 'Streaming',
          'categoryName': 'Assinaturas',
          'subcategoryName': 'Video',
          'averageAmount': '39.9',
          'occurrences': '3',
          'likelyFixedAmount': true,
          'lastOccurrence': '2026-03-15',
        },
      ],
    });

    final recommendation = ReportRecommendation.fromJson({
      'title': 'Ajustar assinaturas',
      'rationale': 'O gasto recorrente cresceu.',
      'action': 'Revisar planos',
    });

    expect(summary.hasData, isTrue);
    expect(summary.totalExpenses, 12);
    expect(summary.categoryTotals.single.categoryName, 'Moradia');
    expect(summary.topExpenses.single.description, 'Aluguel');
    expect(summary.topExpenses.single.dueDate, DateTime(2026, 3, 10));
    expect(insights.monthComparison, isNotNull);
    expect(insights.increaseAlerts.single.categoryName, 'Lazer');
    expect(insights.recurringExpenses.single.likelyFixedAmount, isTrue);
    expect(recommendation.action, 'Revisar planos');
  });

  test('falls back to defaults when report payload omits optional data', () {
    final summary = ReportSummary.fromJson({
      'from': '2026-03-01',
      'to': '2026-03-31',
    });
    final insights = ReportInsights.fromJson({});
    final recommendation = ReportRecommendation.fromJson({});
    final categoryTotal = ReportCategoryTotal.fromJson({});
    final topExpense = ReportTopExpense.fromJson({
      'dueDate': '2026-03-01',
    });
    final recurringExpense = ReportRecurringExpense.fromJson({
      'lastOccurrence': '2026-03-01',
    });
    final monthComparison = ReportMonthComparison.fromJson({});
    final increaseAlert = ReportIncreaseAlert.fromJson({});

    expect(summary.hasData, isFalse);
    expect(summary.categoryTotals, isEmpty);
    expect(summary.topExpenses, isEmpty);
    expect(insights.monthComparison, isNull);
    expect(insights.increaseAlerts, isEmpty);
    expect(insights.recurringExpenses, isEmpty);
    expect(recommendation.title, isEmpty);
    expect(categoryTotal.categoryId, 0);
    expect(categoryTotal.totalAmount, 0);
    expect(topExpense.expenseId, 0);
    expect(recurringExpense.occurrences, 0);
    expect(monthComparison.currentTotal, 0);
    expect(increaseAlert.deltaPercentage, 0);
  });
}
