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
  test('listFixedBills interpreta a lista autenticada de contas fixas', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
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
              'nextDueDate': '2026-04-05',
              'operationalStatus': 'UPCOMING',
              'lastGeneratedExpense': {
                'expenseId': 31,
                'dueDate': '2026-03-05',
                'createdAt': '2026-03-05T12:00:00Z',
              },
            },
            {
              'id': 11,
              'description': 'Faxina',
              'amount': 90.0,
              'firstDueDate': '2026-04-03',
              'frequency': 'WEEKLY',
              'category': {'id': 2, 'name': 'Moradia'},
              'subcategory': {'id': 21, 'name': 'Condominio'},
              'active': true,
              'createdAt': '2026-03-29T12:00:00Z',
              'nextDueDate': '2026-04-03',
              'operationalStatus': 'DUE_TODAY',
            },
          ],
        }),
        200,
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

    final fixedBills = await repository.listFixedBills();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/fixed-bills',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer access-token');
    expect(fixedBills, hasLength(2));
    expect(fixedBills.first.description, 'Internet fibra');
    expect(fixedBills.first.spaceReference?.name, 'Projeto Horizonte');
    expect(fixedBills.first.lastGeneratedExpense?.expenseId, 31);
    expect(fixedBills.last.frequency, FixedBillFrequency.weekly);
  });

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
              'nextDueDate': '2026-04-05',
              'operationalStatus': 'UPCOMING',
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
      expect(fixedBill.nextDueDate.year, 2026);
      expect(fixedBill.nextDueDate.month, 4);
      expect(fixedBill.nextDueDate.day, 5);
    },
  );

  test('createFixedBill suporta payload semanal no MVP', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 22,
            'description': 'Faxina',
            'amount': 90.0,
            'firstDueDate': '2026-04-03',
            'frequency': 'WEEKLY',
            'category': {'id': 1, 'name': 'Moradia'},
            'subcategory': {'id': 21, 'name': 'Condominio'},
            'active': true,
            'createdAt': '2026-03-30T12:00:00Z',
            'nextDueDate': '2026-04-03',
            'operationalStatus': 'UPCOMING',
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
        description: 'Faxina',
        amount: 90,
        firstDueDate: DateTime.utc(2026, 4, 3),
        frequency: FixedBillFrequency.weekly,
        categoryId: 1,
        subcategoryId: 21,
      ),
    );

    expect(jsonDecode(capturedRequest.body)['frequency'], 'WEEKLY');
    expect(fixedBill.frequency, FixedBillFrequency.weekly);
  });

  test('getFixedBill carrega a regra operacional completa', () async {
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
            'active': true,
            'createdAt': '2026-03-28T12:00:00Z',
            'nextDueDate': '2026-04-05',
            'operationalStatus': 'UPCOMING',
          },
        }),
        200,
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

    final fixedBill = await repository.getFixedBill(10);

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/fixed-bills/10',
    );
    expect(fixedBill.id, 10);
    expect(fixedBill.description, 'Internet fibra');
  });

  test('updateFixedBill envia patch autenticado', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 10,
            'description': 'Internet fibra atualizada',
            'amount': 159.9,
            'firstDueDate': '2026-04-05',
            'frequency': 'MONTHLY',
            'category': {'id': 1, 'name': 'Casa'},
            'subcategory': {'id': 11, 'name': 'Internet'},
            'active': true,
            'createdAt': '2026-03-28T12:00:00Z',
            'nextDueDate': '2026-04-05',
            'operationalStatus': 'UPCOMING',
          },
        }),
        200,
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

    final fixedBill = await repository.updateFixedBill(
      fixedBillId: 10,
      input: CreateFixedBillInput(
        description: 'Internet fibra atualizada',
        amount: 159.9,
        firstDueDate: DateTime.utc(2026, 4, 5),
        frequency: FixedBillFrequency.monthly,
        categoryId: 1,
        subcategoryId: 11,
      ),
    );

    expect(capturedRequest.method, 'PATCH');
    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/fixed-bills/10',
    );
    expect(fixedBill.description, 'Internet fibra atualizada');
  });

  test('deleteFixedBill envia delete autenticado', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('', 204);
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

    await repository.deleteFixedBill(10);

    expect(capturedRequest.method, 'DELETE');
    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/fixed-bills/10',
    );
  });

  test('launchNextExpense cria a proxima despesa operacional', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 91,
            'description': 'Internet fibra',
            'amount': 129.9,
            'dueDate': '2026-04-05',
            'occurredOn': '2026-04-05',
            'category': {'id': 1, 'name': 'Casa'},
            'subcategory': {'id': 11, 'name': 'Internet'},
            'reference': null,
            'notes': null,
            'status': 'PREVISTA',
            'paidAmount': 0,
            'remainingAmount': 129.9,
            'paymentsCount': 0,
            'overdue': false,
            'createdAt': '2026-04-01T18:00:00Z',
            'updatedAt': '2026-04-01T18:00:00Z',
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

    final expense = await repository.launchNextExpense(10);

    expect(capturedRequest.method, 'POST');
    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/fixed-bills/10/launch-expense',
    );
    expect(expense.id, 91);
    expect(expense.description, 'Internet fibra');
  });

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
