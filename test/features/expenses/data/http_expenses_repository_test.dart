import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/expenses/data/http_expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  Future<HttpExpensesRepository> buildRepository(
    Future<http.Response> Function(http.Request request) handler,
  ) async {
    final client = MockClient((request) async => handler(request));
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: true),
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );

    return HttpExpensesRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );
  }

  test(
    'registerExpensePayment envia payload autenticado para /api/v1/payments',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'id': 15,
              'expenseId': 7,
              'amount': 89.9,
              'paidAt': '2026-03-29',
              'method': 'PIX',
              'notes': 'Quitacao',
              'expenseStatus': 'PAGA',
              'expensePaidAmount': 129.9,
              'expenseRemainingAmount': 0,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final sessionController = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: true),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );
      await sessionController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );

      final repository = HttpExpensesRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      await repository.registerExpensePayment(
        CreateExpensePaymentInput(
          expenseId: 7,
          amount: 89.9,
          paidAt: DateTime.utc(2026, 3, 29),
          method: 'PIX',
          notes: 'Quitacao',
        ),
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/payments',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(capturedRequest.body), {
        'expenseId': 7,
        'amount': 89.9,
        'paidAt': '2026-03-29',
        'method': 'PIX',
        'notes': 'Quitacao',
      });
    },
  );

  test('registerExpensePayment propaga erro de saldo do backend', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'code': 'BUSINESS_RULE',
          'message': 'Payment amount exceeds remaining expense balance',
        }),
        422,
        headers: {'content-type': 'application/json'},
      );
    });
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: true),
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );

    final repository = HttpExpensesRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );

    expect(
      () => repository.registerExpensePayment(
        CreateExpensePaymentInput(
          expenseId: 7,
          amount: 120,
          paidAt: DateTime.utc(2026, 3, 29),
          method: 'PIX',
          notes: '',
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.message,
              'message',
              'Payment amount exceeds remaining expense balance',
            ),
      ),
    );
  });

  test('listExpenses envia pagina e decodifica o envelope paginado', () async {
    late http.Request capturedRequest;
    final repository = await buildRepository((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'content': [
            {
              'id': 7,
              'description': 'Conta de Luz',
              'amount': 129.9,
              'context': 'CASA',
              'status': 'ABERTA',
              'dueDate': '2026-03-25',
              'occurredOn': '2026-03-20',
              'householdId': 10,
              'category': {'id': 1, 'name': 'Casa'},
              'subcategory': {'id': 11, 'name': 'Internet'},
              'reference': {'id': 88, 'name': 'Casa principal'},
              'paidAmount': 0,
              'remainingAmount': 129.9,
              'paymentsCount': 0,
              'payments': [],
            },
          ],
          'page': {
            'page': 2,
            'size': 10,
            'totalElements': 1,
            'totalPages': 1,
            'hasNext': false,
            'hasPrevious': true,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await repository.listExpenses(page: 2, size: 10);

    expect(capturedRequest.url.path, '/api/v1/expenses');
    expect(capturedRequest.url.queryParameters['page'], '2');
    expect(capturedRequest.url.queryParameters['size'], '10');
    expect(result.items, hasLength(1));
    expect(result.items.first.description, 'Conta de Luz');
    expect(result.page, 2);
    expect(result.size, 10);
    expect(result.totalElements, 1);
    expect(result.hasPrevious, isTrue);
  });

  test('getExpenseDetail decodifica o payload da despesa', () async {
    final repository = await buildRepository((request) async {
      return http.Response(
        jsonEncode({
          'data': {
            'id': 7,
            'description': 'Conta de Agua',
            'amount': 89.9,
            'context': 'CASA',
            'status': 'PAGA',
            'dueDate': '2026-03-18',
            'occurredOn': '2026-03-18',
            'householdId': 10,
            'category': {'id': 1, 'name': 'Casa'},
            'subcategory': {'id': 11, 'name': 'Internet'},
            'reference': {'id': 50, 'name': 'Casa principal'},
            'notes': 'Conta do mes',
            'paidAmount': 89.9,
            'remainingAmount': 0,
            'paymentsCount': 1,
            'payments': [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final detail = await repository.getExpenseDetail(7);

    expect(detail.id, 7);
    expect(detail.description, 'Conta de Agua');
    expect(detail.remainingAmount, 0);
    expect(detail.status, 'PAGA');
  });

  test('listCatalogOptions decodifica o catálogo para o formulário', () async {
    final repository = await buildRepository((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'name': 'Casa',
              'subcategories': [
                {'id': 11, 'name': 'Internet'},
              ],
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final options = await repository.listCatalogOptions();

    expect(options, hasLength(1));
    expect(options.first.name, 'Casa');
    expect(options.first.subcategories.first.name, 'Internet');
  });

  test('createExpense envia o payload da despesa para POST /expenses', () async {
    late http.Request capturedRequest;
    final repository = await buildRepository((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 99,
            'description': 'Mercado',
            'amount': 120.5,
            'dueDate': '2026-03-29',
            'occurredOn': '2026-03-29',
            'context': 'CASA',
            'category': {'id': 1, 'name': 'Casa'},
            'subcategory': {'id': 11, 'name': 'Supermercado'},
            'reference': {'id': 77, 'name': 'Casa principal'},
            'status': 'PENDENTE',
            'remainingAmount': 120.5,
            'paidAmount': 0,
            'overdue': false,
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    await repository.createExpense(
      SaveExpenseInput(
        description: 'Mercado',
        amount: 120.5,
        occurredOn: DateTime.utc(2026, 3, 29),
        dueDate: DateTime.utc(2026, 3, 29),
        context: 'CASA',
        categoryId: 1,
        subcategoryId: 11,
        spaceReferenceId: 77,
        notes: 'Compra da semana',
      ),
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/v1/expenses');
    expect(jsonDecode(capturedRequest.body), {
      'description': 'Mercado',
      'amount': 120.5,
      'occurredOn': '2026-03-29',
      'dueDate': '2026-03-29',
      'context': 'CASA',
      'categoryId': 1,
      'subcategoryId': 11,
      'spaceReferenceId': 77,
      'notes': 'Compra da semana',
    });
  });

  test('updateExpense envia PATCH com o id correto', () async {
    late http.Request capturedRequest;
    final repository = await buildRepository((request) async {
      capturedRequest = request;
      return http.Response('', 200);
    });

    await repository.updateExpense(
      expenseId: 12,
      input: SaveExpenseInput(
        description: 'Internet',
        amount: 89.9,
        occurredOn: DateTime.utc(2026, 3, 30),
        dueDate: DateTime.utc(2026, 3, 30),
        context: 'CASA',
        categoryId: 1,
        subcategoryId: 11,
        spaceReferenceId: null,
        notes: 'Atualizada',
      ),
    );

    expect(capturedRequest.method, 'PATCH');
    expect(capturedRequest.url.path, '/api/v1/expenses/12');
  });

  test('deleteExpense envia DELETE para o id informado', () async {
    late http.Request capturedRequest;
    final repository = await buildRepository((request) async {
      capturedRequest = request;
      return http.Response('', 204);
    });

    await repository.deleteExpense(44);

    expect(capturedRequest.method, 'DELETE');
    expect(capturedRequest.url.path, '/api/v1/expenses/44');
  });

  test('listExpenses propaga erro do backend', () async {
    final repository = await buildRepository((request) async {
      return http.Response(
        jsonEncode({
          'code': 'SERVER_ERROR',
          'message': 'Falha simulada',
        }),
        500,
        headers: {'content-type': 'application/json'},
      );
    });

    expect(
      () => repository.listExpenses(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.message, 'message', 'Falha simulada'),
      ),
    );
  });
}
