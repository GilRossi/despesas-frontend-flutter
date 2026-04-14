import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_health.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';

class HttpPlatformAdminRepository implements PlatformAdminRepository {
  HttpPlatformAdminRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<PlatformAdminOverview> fetchOverview() async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.get(
        '/api/v1/admin/platform/overview',
        headers: headers,
      ),
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta inválida da visão geral da plataforma.',
    );
    return PlatformAdminOverview.fromJson(data);
  }

  @override
  Future<PlatformAdminHealth> fetchHealth() async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.get(
        '/api/v1/admin/platform/health',
        headers: headers,
      ),
    );

    final data = _parseDataMap(
      response,
      fallbackMessage: 'Resposta inválida da saúde da plataforma.',
    );
    return PlatformAdminHealth.fromJson(data);
  }

  @override
  Future<List<PlatformAdminSpace>> fetchSpaces() async {
    final response = await _authorizedRequestExecutor.run(
      (headers) => _authorizedRequestExecutor.apiClient.get(
        '/api/v1/admin/spaces',
        headers: headers,
      ),
    );

    final data = _parseDataList(
      response,
      fallbackMessage: 'Resposta inválida da lista de espaços.',
    );
    return data.map(PlatformAdminSpace.fromJson).toList();
  }

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

  List<Map<String, dynamic>> _parseDataList(
    dynamic response, {
    required String fallbackMessage,
  }) {
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List) {
      throw ApiException(
        statusCode: 500,
        code: 'INVALID_RESPONSE',
        message: fallbackMessage,
      );
    }

    return data.whereType<Map<String, dynamic>>().toList();
  }
}
