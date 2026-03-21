import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
  });

  final int statusCode;
  final String message;
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromResponse(http.Response response) {
    final fallback = ApiException(
      statusCode: response.statusCode,
      message: 'Nao foi possivel concluir a solicitacao.',
    );

    if (response.body.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiException(
          statusCode: response.statusCode,
          message: decoded['message'] as String? ?? fallback.message,
          code: decoded['code'] as String?,
        );
      }
    } catch (_) {
      return fallback;
    }

    return fallback;
  }

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
