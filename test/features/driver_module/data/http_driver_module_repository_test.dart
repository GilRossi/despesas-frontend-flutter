import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/driver_module/data/http_driver_module_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  Future<SessionController> buildSessionController() async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          householdId: 10,
          email: 'driver-owner@local.invalid',
          name: 'Driver Owner',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'driver-owner@local.invalid',
      password: 'Senha123!',
    );
    return sessionController;
  }

  HttpDriverModuleRepository buildRepository({
    required http.Client client,
    required SessionController sessionController,
  }) {
    return HttpDriverModuleRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );
  }

  test('fetchBootstrap consome o contrato bootstrap do Driver Module', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'moduleKey': 'DRIVER',
            'spaceId': 10,
            'targetCity': 'Praia Grande',
            'targetState': 'SP',
            'targetCountry': 'BR',
            'providers': [
              {
                'key': 'UBER_DRIVER',
                'label': 'Uber Driver',
                'category': 'RIDE_HAILING',
              },
              {
                'key': 'APP99_DRIVER',
                'label': '99 Motorista',
                'category': 'RIDE_HAILING',
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final sessionController = await buildSessionController();
    final repository = buildRepository(
      client: client,
      sessionController: sessionController,
    );

    final result = await repository.fetchBootstrap();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/driver/bootstrap',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer access-token');
    expect(result.moduleKey, 'DRIVER');
    expect(result.spaceId, 10);
    expect(result.targetCity, 'Praia Grande');
    expect(result.providers, hasLength(2));
    expect(result.providers.first.label, 'Uber Driver');
  });
}
