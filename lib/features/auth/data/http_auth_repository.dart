import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:http/http.dart' as http;

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._apiClient);

  final DespesasApiClient _apiClient;

  @override
  Future<MobileSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );

    return _parseSessionResponse(response);
  }

  @override
  Future<MobileSession> refresh({required String refreshToken}) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    return _parseSessionResponse(response);
  }

  MobileSession _parseSessionResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Resposta de autenticacao invalida.',
      );
    }

    return MobileSession.fromJson(data);
  }
}
