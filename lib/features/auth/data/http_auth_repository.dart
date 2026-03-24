import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/change_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:http/http.dart' as http;

typedef AccessTokenProvider = String? Function();

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(
    this._apiClient, {
    AccessTokenProvider? accessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider;

  final DespesasApiClient _apiClient;
  final AccessTokenProvider? _accessTokenProvider;

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

  @override
  Future<ChangePasswordResult> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final accessToken = _accessTokenProvider?.call();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_UNAVAILABLE',
        message: 'A sessao nao esta disponivel.',
      );
    }

    final response = await _apiClient.postJson(
      '/api/v1/auth/change-password',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'newPasswordConfirmation': newPasswordConfirmation,
      },
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta invalida da troca de senha.',
    );
    return ChangePasswordResult.fromJson(data);
  }

  MobileSession _parseSessionResponse(http.Response response) {
    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta de autenticacao invalida.',
    );
    return MobileSession.fromJson(data);
  }

  Map<String, dynamic> _parseDataMap(
    http.Response response, {
    required String fallbackMessage,
  }) {
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: fallbackMessage,
      );
    }
    return data;
  }
}
