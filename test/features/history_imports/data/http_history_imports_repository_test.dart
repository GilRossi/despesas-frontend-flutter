import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/history_imports/data/http_history_imports_repository.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'importHistory envia payload autenticado e interpreta a resposta em lote',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'importedCount': 2,
              'entries': [
                {
                  'expenseId': 10,
                  'paymentId': 100,
                  'description': 'Mercado de fevereiro',
                  'amount': 189.9,
                  'date': '2026-02-14',
                  'status': 'PAGA',
                },
                {
                  'expenseId': 11,
                  'paymentId': 101,
                  'description': 'Combustivel de fevereiro',
                  'amount': 240.0,
                  'date': '2026-02-15',
                  'status': 'PAGA',
                },
              ],
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
      final repository = HttpHistoryImportsRepository(
        AuthorizedRequestExecutor(
          apiClient: DespesasApiClient(
            baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
            httpClient: client,
          ),
          sessionManager: sessionController,
        ),
      );

      final result = await repository.importHistory(
        CreateHistoryImportInput(
          paymentMethod: HistoryImportPaymentMethod.pix,
          entries: [
            HistoryImportEntryInput(
              description: 'Mercado de fevereiro',
              amount: 189.9,
              date: DateTime.utc(2026, 2, 14),
              context: 'CASA',
              categoryId: 1,
              subcategoryId: 11,
            ),
            HistoryImportEntryInput(
              description: 'Combustivel de fevereiro',
              amount: 240,
              date: DateTime.utc(2026, 2, 15),
              context: 'VEICULO',
              categoryId: 2,
              subcategoryId: 21,
              notes: 'abastecimento do inicio do mes',
            ),
          ],
        ),
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/history-imports',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(capturedRequest.body), {
        'entries': [
          {
            'description': 'Mercado de fevereiro',
            'amount': 189.9,
            'date': '2026-02-14',
            'context': 'CASA',
            'categoryId': 1,
            'subcategoryId': 11,
          },
          {
            'description': 'Combustivel de fevereiro',
            'amount': 240.0,
            'date': '2026-02-15',
            'context': 'VEICULO',
            'categoryId': 2,
            'subcategoryId': 21,
            'notes': 'abastecimento do inicio do mes',
          },
        ],
        'paymentMethod': 'PIX',
      });
      expect(result.importedCount, 2);
      expect(result.entries[1].description, 'Combustivel de fevereiro');
      expect(result.entries[1].status, 'PAGA');
    },
  );

  test('importHistory propaga fieldErrors indexados do backend', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'code': 'BUSINESS_RULE',
          'message': 'History import validation failed',
          'fieldErrors': [
            {
              'field': 'entries[1].subcategoryId',
              'message': 'subcategoryId must belong to the informed category',
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
    final repository = HttpHistoryImportsRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );

    expect(
      () => repository.importHistory(fakeCreateHistoryImportInput()),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.fieldErrors['entries[1].subcategoryId'],
              'entries[1].subcategoryId',
              'subcategoryId must belong to the informed category',
            ),
      ),
    );
  });
}
