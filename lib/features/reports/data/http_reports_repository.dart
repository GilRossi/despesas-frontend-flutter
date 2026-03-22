import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/reports/domain/report_insights.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';

class HttpReportsRepository implements ReportsRepository {
  HttpReportsRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<ReportsSnapshot> loadMonthlyReport({
    required DateTime referenceMonth,
    required bool comparePrevious,
  }) async {
    final normalizedMonth = DateTime(referenceMonth.year, referenceMonth.month);
    final from = DateTime(normalizedMonth.year, normalizedMonth.month, 1);
    final to = DateTime(normalizedMonth.year, normalizedMonth.month + 1, 0);
    final fromParam = _formatDate(from);
    final toParam = _formatDate(to);
    final monthParam =
        '${normalizedMonth.year}-${normalizedMonth.month.toString().padLeft(2, '0')}';

    final summaryResponse = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/financial-assistant/summary',
        headers: headers,
        queryParameters: {'from': fromParam, 'to': toParam},
      );
    });
    if (summaryResponse.statusCode >= 400) {
      throw ApiException.fromResponse(summaryResponse);
    }

    final insightsResponse = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/financial-assistant/insights',
        headers: headers,
        queryParameters: {'referenceMonth': monthParam},
      );
    });
    if (insightsResponse.statusCode >= 400) {
      throw ApiException.fromResponse(insightsResponse);
    }

    final recommendationsResponse = await _authorizedRequestExecutor.run((
      headers,
    ) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/financial-assistant/recommendations',
        headers: headers,
        queryParameters: {'referenceMonth': monthParam},
      );
    });
    if (recommendationsResponse.statusCode >= 400) {
      throw ApiException.fromResponse(recommendationsResponse);
    }

    final summaryData =
        (jsonDecode(summaryResponse.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    final insightsData =
        (jsonDecode(insightsResponse.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
    final recommendationsData =
        (jsonDecode(recommendationsResponse.body)
                as Map<String, dynamic>)['data']
            as Map<String, dynamic>;

    return ReportsSnapshot(
      referenceMonth: normalizedMonth,
      comparePrevious: comparePrevious,
      summary: ReportSummary.fromJson(summaryData),
      insights: ReportInsights.fromJson(insightsData),
      recommendations:
          (recommendationsData['recommendations'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    ReportRecommendation.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
