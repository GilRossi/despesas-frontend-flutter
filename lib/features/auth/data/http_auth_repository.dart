import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/despesas_api_client.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_user.dart';
import 'package:despesas_frontend/features/auth/domain/change_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/forgot_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/auth/domain/reset_password_result.dart';
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
  Future<void> logout({required String refreshToken}) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/logout',
      headers: _authorizationHeaders(),
      body: {'refreshToken': refreshToken},
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
  }

  @override
  Future<AuthUser> fetchCurrentUser() async {
    final response = await _apiClient.get(
      '/api/v1/auth/me',
      headers: _authorizationHeaders(),
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta inválida da sessão atual.',
    );
    return AuthUser.fromJson(data);
  }

  @override
  Future<AuthOnboarding> completeOnboarding() async {
    final response = await _apiClient.postJson(
      '/api/v1/onboarding/complete',
      headers: _authorizationHeaders(),
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta inválida da conclusão do onboarding.',
    );
    return AuthOnboarding.fromJson(data);
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
        message: 'A sessão não está disponível.',
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
      fallbackMessage: 'Resposta inválida da troca de senha.',
    );
    return ChangePasswordResult.fromJson(data);
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/forgot-password',
      body: {'email': email},
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final maskedEmail = decoded['maskedEmail'] as String?;
    if (maskedEmail == null) {
      throw const ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Resposta inválida do pedido de recuperação de senha.',
      );
    }
    final resetToken = decoded['resetToken'] as String?;
    return ForgotPasswordResult(
      maskedEmail: maskedEmail,
      resetToken: resetToken,
    );
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/reset-password',
      body: {
        'token': token,
        'newPassword': newPassword,
        'newPasswordConfirmation': newPasswordConfirmation,
      },
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta inválida da redefinição de senha.',
    );

    final revokedTokens = data['revokedRefreshTokens'];
    final success = data['success'];
    if (revokedTokens is! int || success is! bool) {
      throw const ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Resposta inválida da redefinição de senha.',
      );
    }

    return ResetPasswordResult(
      revokedRefreshTokens: revokedTokens,
      success: success,
    );
  }

  MobileSession _parseSessionResponse(http.Response response) {
    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta de autenticação inválida.',
    );
    return MobileSession.fromJson(data);
  }

  Map<String, String> _authorizationHeaders() {
    final accessToken = _accessTokenProvider?.call();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_UNAVAILABLE',
        message: 'A sessão não está disponível.',
      );
    }

    return {'Authorization': 'Bearer $accessToken'};
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
