import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';

class HttpFixedBillsRepository implements FixedBillsRepository {
  HttpFixedBillsRepository(this._requestExecutor);

  final AuthorizedRequestExecutor _requestExecutor;

  @override
  Future<List<FixedBillRecord>> listFixedBills() async {
    final response = await _requestExecutor.run(
      (headers) => _requestExecutor.apiClient.get(
        '/api/v1/fixed-bills',
        headers: headers,
      ),
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(FixedBillRecord.fromJson)
        .toList();
  }

  @override
  Future<FixedBillRecord> createFixedBill(CreateFixedBillInput input) async {
    final response = await _requestExecutor.run(
      (headers) => _requestExecutor.apiClient.postJson(
        '/api/v1/fixed-bills',
        headers: headers,
        body: input.toJson(),
      ),
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? const {};
    return FixedBillRecord.fromJson(data);
  }
}
