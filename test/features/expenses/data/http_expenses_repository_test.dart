import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/expenses/data/http_expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
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
}
