import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:http/http.dart' as http;

abstract interface class SessionManager {
  String? get accessToken;

  Future<bool> refreshSession();

  Future<void> clearSession();
}

typedef AuthorizedRequestBuilder =
    Future<http.Response> Function(Map<String, String> headers);

class AuthorizedRequestExecutor {
  AuthorizedRequestExecutor({
    required DespesasApiClient apiClient,
    required SessionManager sessionManager,
  }) : _apiClient = apiClient,
       _sessionManager = sessionManager;

  final DespesasApiClient _apiClient;
  final SessionManager _sessionManager;

  DespesasApiClient get apiClient => _apiClient;

  Future<http.Response> run(AuthorizedRequestBuilder builder) async {
    final initialToken = _sessionManager.accessToken;
    if (initialToken == null || initialToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_UNAVAILABLE',
        message: 'A sessão não está disponível.',
      );
    }

    var response = await builder(_authorizationHeaders(initialToken));
    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await _sessionManager.refreshSession();
    if (!refreshed) {
      await _sessionManager.clearSession();
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Sua sessão expirou. Faça login novamente.',
      );
    }

    final refreshedToken = _sessionManager.accessToken;
    if (refreshedToken == null || refreshedToken.isEmpty) {
      await _sessionManager.clearSession();
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Sua sessão expirou. Faça login novamente.',
      );
    }

    response = await builder(_authorizationHeaders(refreshedToken));
    if (response.statusCode == 401) {
      await _sessionManager.clearSession();
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Sua sessão expirou. Faça login novamente.',
      );
    }

    return response;
  }

  Map<String, String> _authorizationHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }
}
