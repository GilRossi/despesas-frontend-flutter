import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_bootstrap.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_module_repository.dart';

class HttpDriverModuleRepository implements DriverModuleRepository {
  HttpDriverModuleRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<DriverModuleBootstrap> fetchBootstrap() async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.get(
        '/api/v1/driver/bootstrap',
        headers: headers,
      ),
    );

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: 'Resposta inválida da fundação do Driver Module.',
      );
    }

    return DriverModuleBootstrap.fromJson(data);
  }
}
