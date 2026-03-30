import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/fixed_bills/data/http_fixed_bills_repository.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'createFixedBill envia payload autenticado e interpreta a resposta',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'id': 10,
              'description': 'Internet fibra',
              'amount': 129.9,
              'firstDueDate': '2026-04-05',
              'frequency': 'MONTHLY',
              'category': {'id': 1, 'name': 'Casa'},
              'subcategory': {'id': 11, 'name': 'Internet'},
              'spaceReference': {'id': 7, 'name': 'Projeto Horizonte'},
              'active': true,
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
      final repository = HttpFixedBillsRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final fixedBill = await repository.createFixedBill(
        CreateFixedBillInput(
          description: 'Internet fibra',
          amount: 129.9,
          firstDueDate: DateTime.utc(2026, 4, 5),
          frequency: FixedBillFrequency.monthly,
          categoryId: 1,
          subcategoryId: 11,
          spaceReferenceId: 7,
        ),
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/fixed-bills',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(capturedRequest.body), {
        'description': 'Internet fibra',
        'amount': 129.9,
        'firstDueDate': '2026-04-05',
        'frequency': 'MONTHLY',
        'categoryId': 1,
        'subcategoryId': 11,
        'spaceReferenceId': 7,
      });
      expect(fixedBill.description, 'Internet fibra');
      expect(fixedBill.frequency, FixedBillFrequency.monthly);
      expect(fixedBill.spaceReference?.name, 'Projeto Horizonte');
    },
  );

  test('createFixedBill propaga fieldErrors do backend', () async {
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
    final repository = HttpFixedBillsRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );

    expect(
      () => repository.createFixedBill(
        CreateFixedBillInput(
          description: 'Internet fibra',
          amount: 129.9,
          firstDueDate: DateTime.utc(2026, 4, 5),
          frequency: FixedBillFrequency.monthly,
          categoryId: 1,
          subcategoryId: 11,
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
