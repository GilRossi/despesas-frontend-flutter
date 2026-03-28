import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchCurrentUser carrega onboarding do contrato auth/me', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'userId': 1,
            'householdId': 10,
            'email': 'gil@example.com',
            'name': 'Gil Rossi',
            'role': 'OWNER',
            'onboarding': {
              'completed': true,
              'completedAt': '2026-03-28T12:00:00Z',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final apiClient = DespesasApiClient(
      baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
      httpClient: client,
    );
    final repository = HttpAuthRepository(
      apiClient,
      accessTokenProvider: () => 'token-de-teste',
    );

    final user = await repository.fetchCurrentUser();

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/auth/me',
    );
    expect(capturedRequest.headers['authorization'], 'Bearer token-de-teste');
    expect(user.onboarding.completed, isTrue);
    expect(user.onboarding.completedAt, DateTime.parse('2026-03-28T12:00:00Z'));
  });

  test(
    'completeOnboarding envia bearer token para endpoint autenticado',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {'completed': true, 'completedAt': '2026-03-28T12:00:00Z'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = DespesasApiClient(
        baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
        httpClient: client,
      );
      final repository = HttpAuthRepository(
        apiClient,
        accessTokenProvider: () => 'token-de-teste',
      );

      final onboarding = await repository.completeOnboarding();

      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/onboarding/complete',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer token-de-teste');
      expect(
        onboarding,
        isA<AuthOnboarding>()
            .having((item) => item.completed, 'completed', isTrue)
            .having((item) => item.completedAt, 'completedAt', isNotNull),
      );
    },
  );

  test(
    'changeOwnPassword envia bearer token para endpoint autenticado',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'revokedRefreshTokens': 2,
              'reauthenticationRequired': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = DespesasApiClient(
        baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
        httpClient: client,
      );
      final repository = HttpAuthRepository(
        apiClient,
        accessTokenProvider: () => 'token-de-teste',
      );

      final result = await repository.changeOwnPassword(
        currentPassword: 'SenhaAtual123',
        newPassword: 'SenhaNova456',
        newPasswordConfirmation: 'SenhaNova456',
      );

      expect(result.revokedRefreshTokens, 2);
      expect(result.reauthenticationRequired, isTrue);
      expect(
        capturedRequest.url.toString(),
        'https://app.rossicompany.com.br/api/v1/auth/change-password',
      );
      expect(capturedRequest.headers['authorization'], 'Bearer token-de-teste');
    },
  );

  test(
    'changeOwnPassword falha quando a sessao nao tem access token',
    () async {
      final client = MockClient((request) async {
        throw StateError('nao deveria bater na rede sem token');
      });
      final apiClient = DespesasApiClient(
        baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
        httpClient: client,
      );
      final repository = HttpAuthRepository(apiClient);

      await expectLater(
        repository.changeOwnPassword(
          currentPassword: 'SenhaAtual123',
          newPassword: 'SenhaNova456',
          newPasswordConfirmation: 'SenhaNova456',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'SESSION_UNAVAILABLE',
          ),
        ),
      );
    },
  );

  test(
    'completeOnboarding falha quando a sessao nao tem access token',
    () async {
      final client = MockClient((request) async {
        throw StateError('nao deveria bater na rede sem token');
      });
      final apiClient = DespesasApiClient(
        baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
        httpClient: client,
      );
      final repository = HttpAuthRepository(apiClient);

      await expectLater(
        repository.completeOnboarding(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'SESSION_UNAVAILABLE',
          ),
        ),
      );
    },
  );
}
