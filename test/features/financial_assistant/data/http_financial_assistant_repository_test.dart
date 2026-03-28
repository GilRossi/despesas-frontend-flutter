import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/financial_assistant/data/http_financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  test(
    'fetchStarterIntent envia intent explicita ao endpoint autenticado',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'intent': 'REGISTER_INCOME',
              'kind': 'STARTER',
              'title': 'Vamos organizar seus ganhos',
              'message': 'Comece registrando de onde entra sua renda.',
              'primaryActionKey': 'OPEN_REGISTER_INCOME',
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
      final executor = AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      );
      final repository = HttpFinancialAssistantRepository(executor);

      final response = await repository.fetchStarterIntent(
        intent: FinancialAssistantStarterIntent.registerIncome,
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/financial-assistant/starter-intent',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer access-token');
      expect(jsonDecode(capturedRequest.body), {'intent': 'REGISTER_INCOME'});
      expect(response.intent, FinancialAssistantStarterIntent.registerIncome);
      expect(response.kind, 'STARTER');
      expect(response.primaryActionKey, 'OPEN_REGISTER_INCOME');
    },
  );
}
