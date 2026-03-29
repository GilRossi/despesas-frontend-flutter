import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';

class HttpHistoryImportsRepository implements HistoryImportsRepository {
  HttpHistoryImportsRepository(this._requestExecutor);

  final AuthorizedRequestExecutor _requestExecutor;

  @override
  Future<HistoryImportResult> importHistory(
    CreateHistoryImportInput input,
  ) async {
    final response = await _requestExecutor.run(
      (headers) => _requestExecutor.apiClient.postJson(
        '/api/v1/history-imports',
        headers: headers,
        body: input.toJson(),
      ),
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? const {};
    return HistoryImportResult.fromJson(data);
  }
}
