import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/domain/income_record.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';

class HttpIncomesRepository implements IncomesRepository {
  HttpIncomesRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<IncomeRecord> createIncome(CreateIncomeInput input) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/incomes',
        headers: headers,
        body: input.toJson(),
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return IncomeRecord.fromJson(data);
  }
}
