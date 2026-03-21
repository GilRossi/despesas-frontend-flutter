import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_ai_usage.dart';
import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';

class FinancialAssistantReply {
  const FinancialAssistantReply({
    required this.question,
    required this.mode,
    required this.intent,
    required this.answer,
    required this.summary,
    required this.monthComparison,
    required this.highestSpendingCategory,
    required this.topExpenses,
    required this.increaseAlerts,
    required this.recurringExpenses,
    required this.recommendations,
    required this.aiUsage,
  });

  final String question;
  final String mode;
  final String intent;
  final String answer;
  final ReportSummary? summary;
  final ReportMonthComparison? monthComparison;
  final ReportCategoryTotal? highestSpendingCategory;
  final List<ReportTopExpense> topExpenses;
  final List<ReportIncreaseAlert> increaseAlerts;
  final List<ReportRecurringExpense> recurringExpenses;
  final List<ReportRecommendation> recommendations;
  final FinancialAssistantAiUsage? aiUsage;

  bool get hasSupportingData =>
      summary != null ||
      monthComparison != null ||
      highestSpendingCategory != null ||
      topExpenses.isNotEmpty ||
      increaseAlerts.isNotEmpty ||
      recurringExpenses.isNotEmpty ||
      recommendations.isNotEmpty;

  bool get usesAi => mode == 'AI';

  factory FinancialAssistantReply.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    final rawMonthComparison = json['monthComparison'];
    final rawHighestCategory = json['highestSpendingCategory'];
    final rawAiUsage = json['aiUsage'];

    return FinancialAssistantReply(
      question: json['question'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      summary: rawSummary is Map<String, dynamic>
          ? ReportSummary.fromJson(rawSummary)
          : null,
      monthComparison: rawMonthComparison is Map<String, dynamic>
          ? ReportMonthComparison.fromJson(rawMonthComparison)
          : null,
      highestSpendingCategory: rawHighestCategory is Map<String, dynamic>
          ? ReportCategoryTotal.fromJson(rawHighestCategory)
          : null,
      topExpenses: (json['topExpenses'] as List<dynamic>? ?? const [])
          .map((item) => ReportTopExpense.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
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
      recommendations:
          (json['recommendations'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    ReportRecommendation.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
      aiUsage: rawAiUsage is Map<String, dynamic>
          ? FinancialAssistantAiUsage.fromJson(rawAiUsage)
          : null,
    );
  }
}
