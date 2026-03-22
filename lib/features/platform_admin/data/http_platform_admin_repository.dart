import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';

class HttpPlatformAdminRepository implements PlatformAdminRepository {
  HttpPlatformAdminRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<PlatformAdminHousehold> createHouseholdWithOwner(
    CreateHouseholdOwnerInput input,
  ) async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/admin/households',
        headers: headers,
        body: {
          'householdName': input.householdName,
          'ownerName': input.ownerName,
          'ownerEmail': input.ownerEmail,
          'ownerPassword': input.ownerPassword,
        },
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
        message: 'Resposta invalida do provisionamento administrativo.',
      );
    }

    return PlatformAdminHousehold.fromJson(data);
  }
}
