import 'dart:convert';

import 'package:http/http.dart' as http;

class DespesasApiClient {
  DespesasApiClient({required Uri baseUrl, required http.Client httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient;

  final Uri _baseUrl;
  final http.Client _httpClient;

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String?>? queryParameters,
  }) {
    return _httpClient.get(
      _buildUri(path, queryParameters),
      headers: {'Accept': 'application/json', ...?headers},
    );
  }

  Future<http.Response> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) {
    return _httpClient.post(
      _buildUri(path, null),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? const {}),
    );
  }

  Future<http.Response> patchJson(
    String path, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) {
    return _httpClient.patch(
      _buildUri(path, null),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? const {}),
    );
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    return _httpClient.delete(
      _buildUri(path, null),
      headers: {'Accept': 'application/json', ...?headers},
    );
  }

  Uri _buildUri(String path, Map<String, String?>? queryParameters) {
    final resolved = _baseUrl.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );

    final filteredQuery = <String, String>{
      for (final entry in queryParameters?.entries ?? const Iterable.empty())
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };

    return resolved.replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }
}
