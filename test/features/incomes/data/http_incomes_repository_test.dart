import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/incomes/data/http_incomes_repository.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'createIncome envia payload autenticado e interpreta a resposta',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'id': 10,
              'description': 'Freelance de marco',
              'amount': 1800.0,
              'receivedOn': '2026-03-28',
              'spaceReference': {'id': 7, 'name': 'Projeto Horizonte'},
              'createdAt': '2026-03-28T12:00:00Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final sessionController = SessionController(
        authRepository: FakeAuthRepository(
          loginResult: fakeSession(
            onboarding: const AuthOnboarding(completed: false),
          ),
        ),
        sessionStore: MemorySessionStore(),
      );
      await sessionController.login(
        email: 'gil@example.com',
        password: 'Senha123!',
      );
      final repository = HttpIncomesRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final income = await repository.createIncome(
        CreateIncomeInput(
          description: 'Freelance de marco',
          amount: 1800,
          receivedOn: DateTime.utc(2026, 3, 28),
          spaceReferenceId: 7,
        ),
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/incomes',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(capturedRequest.body), {
        'description': 'Freelance de marco',
        'amount': 1800.0,
        'receivedOn': '2026-03-28',
        'spaceReferenceId': 7,
      });
      expect(income.description, 'Freelance de marco');
      expect(income.spaceReference?.name, 'Projeto Horizonte');
    },
  );

  test('createIncome propaga fieldErrors do backend', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'code': 'BUSINESS_RULE',
          'message': 'spaceReferenceId must belong to the active household',
          'fieldErrors': [
            {
              'field': 'spaceReferenceId',
              'message': 'spaceReferenceId must belong to the active household',
            },
          ],
        }),
        422,
        headers: {'content-type': 'application/json'},
      );
    });
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );
    final repository = HttpIncomesRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );

    expect(
      () => repository.createIncome(
        CreateIncomeInput(
          description: 'Freelance de marco',
          amount: 1800,
          receivedOn: DateTime.utc(2026, 3, 28),
          spaceReferenceId: 99,
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.fieldErrors['spaceReferenceId'],
              'spaceReferenceId',
              'spaceReferenceId must belong to the active household',
            ),
      ),
    );
  });
}
