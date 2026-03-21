import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';

class HttpExpensesRepository implements ExpensesRepository {
  HttpExpensesRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<PagedResult<ExpenseSummary>> listExpenses({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/expenses',
        headers: headers,
        queryParameters: {'page': '$page', 'size': '$size'},
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (decoded['content'] as List<dynamic>? ?? const [])
        .map((item) => ExpenseSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final pageData = decoded['page'] as Map<String, dynamic>;

    return PagedResult(
      items: content,
      page: pageData['page'] as int,
      size: pageData['size'] as int,
      totalElements: pageData['totalElements'] as int,
      totalPages: pageData['totalPages'] as int,
      hasNext: pageData['hasNext'] as bool,
      hasPrevious: pageData['hasPrevious'] as bool,
    );
  }
}
