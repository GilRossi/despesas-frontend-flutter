import 'package:despesas_frontend/features/reports/domain/report_insights.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.referenceMonth,
    required this.comparePrevious,
    required this.summary,
    required this.insights,
    required this.recommendations,
  });

  final DateTime referenceMonth;
  final bool comparePrevious;
  final ReportSummary summary;
  final ReportInsights insights;
  final List<ReportRecommendation> recommendations;
}
