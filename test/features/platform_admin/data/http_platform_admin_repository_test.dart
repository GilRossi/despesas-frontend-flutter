import 'dart:convert';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/platform_admin/data/http_platform_admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/test_doubles.dart';

void main() {
  Future<SessionController> buildSessionController() async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          role: 'PLATFORM_ADMIN',
          householdId: null,
          email: 'admin@local.invalid',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'Senha123!',
    );
    return sessionController;
  }

  HttpPlatformAdminRepository buildRepository({
    required http.Client client,
    required SessionController sessionController,
  }) {
    return HttpPlatformAdminRepository(
      AuthorizedRequestExecutor(
        apiClient: DespesasApiClient(
          baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
          httpClient: client,
        ),
        sessionManager: sessionController,
      ),
    );
  }

  test('fetchOverview consome o contrato overview do admin platform', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'totalSpaces': 4,
            'activeSpaces': 4,
            'totalUsers': 6,
            'totalPlatformAdmins': 1,
            'modules': [
              {
                'key': 'FINANCIAL',
                'enabledSpaces': 4,
                'disabledSpaces': 0,
                'mandatory': true,
              },
              {
                'key': 'DRIVER',
                'enabledSpaces': 0,
                'disabledSpaces': 4,
                'mandatory': false,
              },
            ],
            'actuator': {
              'healthExposed': true,
              'infoExposed': true,
              'metricsExposed': false,
            },
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

    final result = await repository.fetchOverview();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/admin/platform/overview',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer access-token');
    expect(result.totalSpaces, 4);
    expect(result.modules.first.key, 'FINANCIAL');
    expect(result.actuator.metricsExposed, isFalse);
  });

  test('fetchHealth consome o contrato health do admin platform', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'applicationStatus': 'UP',
            'checkedAt': '2026-04-14T21:38:15.826747912Z',
            'actuator': {
              'healthExposed': true,
              'infoExposed': true,
              'metricsExposed': false,
            },
            'jvm': {
              'availableProcessors': 4,
              'uptimeMs': 1100573,
              'heapUsedBytes': 554439688,
              'heapCommittedBytes': 788529152,
              'heapMaxBytes': 15015608320,
            },
            'system': {'systemLoadAverage': 0.046875},
            'info': {},
            'alerts': [
              {
                'code': 'ACTUATOR_METRICS_NOT_EXPOSED',
                'severity': 'WARNING',
                'source': 'ACTUATOR',
                'title': 'Actuator metrics fechado',
                'message':
                    'As métricas do Actuator ainda não estão expostas por HTTP nesta fase.',
              },
              {
                'code': 'ACTUATOR_INFO_EMPTY',
                'severity': 'INFO',
                'source': 'ACTUATOR',
                'title': 'Actuator info vazio',
                'message':
                    'O endpoint de info está exposto, mas sem dados extras publicados agora.',
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

    final result = await repository.fetchHealth();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/admin/platform/health',
    );
    expect(result.applicationStatus, 'UP');
    expect(result.jvm.availableProcessors, 4);
    expect(result.system.systemLoadAverage, 0.046875);
    expect(result.alerts, hasLength(2));
    expect(result.alerts.first.code, 'ACTUATOR_METRICS_NOT_EXPOSED');
  });

  test('fetchSpaces consome a lista de Espacos do admin platform', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'spaceId': 4,
              'spaceName': 'Teste',
              'createdAt': '2026-04-01T20:23:38.252123Z',
              'updatedAt': '2026-04-01T20:23:38.252123Z',
              'activeMembersCount': 2,
              'owner': {
                'userId': 6,
                'name': 'Teste Owner',
                'email': 'teste@teste.com',
              },
              'modules': [
                {'key': 'FINANCIAL', 'enabled': true, 'mandatory': true},
                {'key': 'DRIVER', 'enabled': false, 'mandatory': false},
              ],
            },
          ],
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

    final result = await repository.fetchSpaces();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/admin/spaces',
    );
    expect(result.single.spaceName, 'Teste');
    expect(result.single.owner?.email, 'teste@teste.com');
    expect(result.single.modules.last.key, 'DRIVER');
  });

  test('fetchSpace consome o detalhe de um Espaco do admin platform', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'spaceId': 4,
            'spaceName': 'Teste',
            'createdAt': '2026-04-01T20:23:38.252123Z',
            'updatedAt': '2026-04-10T20:23:38.252123Z',
            'activeMembersCount': 2,
            'owner': {
              'userId': 6,
              'name': 'Teste Owner',
              'email': 'teste@teste.com',
            },
            'modules': [
              {'key': 'FINANCIAL', 'enabled': true, 'mandatory': true},
              {'key': 'DRIVER', 'enabled': false, 'mandatory': false},
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

    final result = await repository.fetchSpace(4);

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/admin/spaces/4',
    );
    expect(result.spaceId, 4);
    expect(result.updatedAt, DateTime.parse('2026-04-10T20:23:38.252123Z'));
  });

  test(
    'updateSpaceModules envia o payload real de modulos do Espaco',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'spaceId': 4,
              'spaceName': 'Teste',
              'createdAt': '2026-04-01T20:23:38.252123Z',
              'updatedAt': '2026-04-10T20:23:38.252123Z',
              'activeMembersCount': 2,
              'owner': {
                'userId': 6,
                'name': 'Teste Owner',
                'email': 'teste@teste.com',
              },
              'modules': [
                {'key': 'FINANCIAL', 'enabled': true, 'mandatory': true},
                {'key': 'DRIVER', 'enabled': true, 'mandatory': false},
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

      final result = await repository.updateSpaceModules(
        spaceId: 4,
        enabledModuleKeys: const ['FINANCIAL', 'DRIVER'],
      );

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/admin/spaces/4/modules',
      );
      expect(capturedRequest.method, 'PUT');
      expect(jsonDecode(capturedRequest.body), {
        'enabledModules': ['FINANCIAL', 'DRIVER'],
      });
      expect(result.modules.last.enabled, isTrue);
    },
  );

  test('fetchSpaces propaga erro quando o contrato vem invalido', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({'data': {}}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final sessionController = await buildSessionController();
    final repository = buildRepository(
      client: client,
      sessionController: sessionController,
    );

    expect(
      repository.fetchSpaces(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });
}
