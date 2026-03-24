import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
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

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta invalida do provisionamento administrativo.',
    );
    return PlatformAdminHousehold.fromJson(data);
  }

  @override
  Future<AdminPasswordResetResult> resetUserPassword(
    AdminPasswordResetInput input,
  ) async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/admin/users/password-reset',
        headers: headers,
        body: {
          'targetEmail': input.targetEmail,
          'newPassword': input.newPassword,
          'newPasswordConfirmation': input.newPasswordConfirmation,
        },
      ),
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta invalida do reset administrativo de senha.',
    );
    return AdminPasswordResetResult.fromJson(data);
  }

  Map<String, dynamic> _parseDataMap(
    dynamic response, {
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
