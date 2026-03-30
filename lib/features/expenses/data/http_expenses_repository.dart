import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';

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

  @override
  Future<ExpenseDetail> getExpenseDetail(int expenseId) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/expenses/$expenseId',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return ExpenseDetail.fromJson(data);
  }

  @override
  Future<List<CatalogOption>> listCatalogOptions() async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/catalog/options',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => CatalogOption.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ExpenseSummary> createExpense(SaveExpenseInput input) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/expenses',
        headers: headers,
        body: input.toJson(includeInitialPayment: true),
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return ExpenseSummary.fromJson(data);
  }

  @override
  Future<void> updateExpense({
    required int expenseId,
    required SaveExpenseInput input,
  }) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.patchJson(
        '/api/v1/expenses/$expenseId',
        headers: headers,
        body: input.toJson(includeInitialPayment: false),
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> deleteExpense(int expenseId) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.delete(
        '/api/v1/expenses/$expenseId',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> registerExpensePayment(CreateExpensePaymentInput input) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/payments',
        headers: headers,
        body: {
          'expenseId': input.expenseId,
          'amount': input.amount,
          'paidAt': _formatDate(input.paidAt),
          'method': input.method,
          'notes': input.notes.trim(),
        },
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<void> deleteExpensePayment(int paymentId) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.delete(
        '/api/v1/payments/$paymentId',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
