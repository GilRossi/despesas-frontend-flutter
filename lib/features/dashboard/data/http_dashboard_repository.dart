import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_summary.dart';

class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository(this._executor);

  final AuthorizedRequestExecutor _executor;

  @override
  Future<DashboardSummary> fetchDashboard() async {
    final response = await _executor.run(
      (headers) => _executor.apiClient.get(
        '/api/v1/dashboard',
        headers: headers,
      ),
    );
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Resposta invalida do dashboard.',
      );
    }
    return DashboardSummary.fromJson(data);
  }
}
