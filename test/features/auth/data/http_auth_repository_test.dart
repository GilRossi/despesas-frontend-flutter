import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HttpAuthRepository buildRepository({
    required http.Client client,
    String? accessToken,
  }) {
    return HttpAuthRepository(
      DespesasApiClient(
        baseUrl: Uri.parse('https://app.rossicompany.com.br/'),
        httpClient: client,
      ),
      accessTokenProvider: accessToken == null ? null : () => accessToken,
    );
  }

  test('login carrega a sessao com contrato auth/login', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'tokenType': 'Bearer',
            'accessToken': 'access-token',
            'accessTokenExpiresAt': '2026-03-29T12:00:00Z',
            'refreshToken': 'refresh-token',
            'refreshTokenExpiresAt': '2026-04-29T12:00:00Z',
            'user': {
              'userId': 1,
              'householdId': 10,
              'email': 'gil@example.com',
              'name': 'Gil Rossi',
              'role': 'OWNER',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = buildRepository(client: client);
    final session = await repository.login(
      email: 'gil@example.com',
      password: 'Senha123!',
    );

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/auth/login',
    );
    expect(session.accessToken, 'access-token');
    expect(session.user.name, 'Gil Rossi');
  });

  test('refresh carrega a sessao com contrato auth/refresh', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'tokenType': 'Bearer',
            'accessToken': 'fresh-access-token',
            'accessTokenExpiresAt': '2026-03-29T12:00:00Z',
            'refreshToken': 'fresh-refresh-token',
            'refreshTokenExpiresAt': '2026-04-29T12:00:00Z',
            'user': {
              'userId': 1,
              'householdId': 10,
              'email': 'gil@example.com',
              'name': 'Gil Rossi',
              'role': 'OWNER',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = buildRepository(client: client);
    final session = await repository.refresh(refreshToken: 'refresh-token');

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/auth/refresh',
    );
    expect(session.accessToken, 'fresh-access-token');
  });

  test('forgotPassword interpreta a resposta mascarada', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'maskedEmail': 'g***@example.com',
          'resetToken': 'token-123',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = buildRepository(client: client);
    final result = await repository.forgotPassword(email: 'gil@example.com');

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/auth/forgot-password',
    );
    expect(result.maskedEmail, 'g***@example.com');
    expect(result.resetToken, 'token-123');
  });

  test('resetPassword interpreta o contrato de redefinicao', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'data': {
            'revokedRefreshTokens': 3,
            'success': true,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = buildRepository(client: client);
    final result = await repository.resetPassword(
      token: 'token-123',
      newPassword: 'SenhaNova456',
      newPasswordConfirmation: 'SenhaNova456',
    );

    expect(
      capturedRequest.url.toString(),
      'https://app.rossicompany.com.br/api/v1/auth/reset-password',
    );
    expect(result.revokedRefreshTokens, 3);
    expect(result.success, isTrue);
  });

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
    final repository = buildRepository(
      client: client,
      accessToken: 'token-de-teste',
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
      final repository = buildRepository(
        client: client,
        accessToken: 'token-de-teste',
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
      final repository = buildRepository(
        client: client,
        accessToken: 'token-de-teste',
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
      final repository = buildRepository(client: client);

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
      final repository = buildRepository(client: client);

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
