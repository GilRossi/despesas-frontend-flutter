import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/data/http_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
}
