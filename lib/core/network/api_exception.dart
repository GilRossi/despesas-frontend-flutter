import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.fieldErrors = const {},
  });

  final int statusCode;
  final String message;
  final String? code;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  String? fieldMessage(String field) => fieldErrors[field];

  factory ApiException.fromResponse(http.Response response) {
    final fallback = ApiException(
      statusCode: response.statusCode,
      message: 'Não foi possível concluir a solicitação.',
    );

    if (response.body.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final rawFieldErrors =
            decoded['fieldErrors'] as List<dynamic>? ?? const [];
        final fieldErrors = <String, String>{
          for (final item in rawFieldErrors)
            if (item is Map<String, dynamic>)
              (item['field'] as String? ?? ''):
                  item['message'] as String? ?? '',
        }..removeWhere((key, value) => key.isEmpty || value.isEmpty);

        return ApiException(
          statusCode: response.statusCode,
          message: decoded['message'] as String? ?? fallback.message,
          code: decoded['code'] as String?,
          fieldErrors: fieldErrors,
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
