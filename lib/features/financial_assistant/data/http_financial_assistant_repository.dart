import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_reply.dart';

class HttpFinancialAssistantRepository implements FinancialAssistantRepository {
  HttpFinancialAssistantRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<FinancialAssistantReply> askQuestion({
    required String question,
    required DateTime referenceMonth,
  }) async {
    final monthParam =
        '${referenceMonth.year}-${referenceMonth.month.toString().padLeft(2, '0')}';

    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/financial-assistant/query',
        headers: headers,
        body: {'question': question, 'referenceMonth': monthParam},
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return FinancialAssistantReply.fromJson(data);
  }

  @override
  Future<FinancialAssistantStarterReply> fetchStarterIntent({
    required FinancialAssistantStarterIntent intent,
  }) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/financial-assistant/starter-intent',
        headers: headers,
        body: {'intent': intent.apiValue},
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return FinancialAssistantStarterReply.fromJson(data);
  }
}
