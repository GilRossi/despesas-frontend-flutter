import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeSessionManager implements SessionManager {
  _FakeSessionManager({required this.accessTokenValue});

  String? accessTokenValue;
  bool refreshOutcome = true;
  String refreshedToken = 'refreshed-token';
  int refreshCalls = 0;
  int clearCalls = 0;

  @override
  String? get accessToken => accessTokenValue;

  @override
  Future<void> clearSession() async {
    clearCalls += 1;
    accessTokenValue = null;
  }

  @override
  Future<bool> refreshSession() async {
    refreshCalls += 1;
    if (!refreshOutcome) {
      accessTokenValue = null;
      return false;
    }
    accessTokenValue = refreshedToken;
    return true;
  }
}

void main() {
  test('retries once after 401 and uses refreshed token', () async {
    final executor = AuthorizedRequestExecutor(
      apiClient: DespesasApiClient(
        baseUrl: Uri.parse('http://localhost:8080'),
        httpClient: http.Client(),
      ),
      sessionManager: _FakeSessionManager(accessTokenValue: 'initial-token'),
    );
    final usedTokens = <String>[];

    final response = await executor.run((headers) async {
      usedTokens.add(headers['Authorization']!);
      if (usedTokens.length == 1) {
        return http.Response('', 401);
      }
      return http.Response('{}', 200);
    });

    expect(response.statusCode, 200);
    expect(usedTokens, ['Bearer initial-token', 'Bearer refreshed-token']);
  });
}
