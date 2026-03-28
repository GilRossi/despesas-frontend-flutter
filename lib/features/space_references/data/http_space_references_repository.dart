import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';

class HttpSpaceReferencesRepository implements SpaceReferencesRepository {
  HttpSpaceReferencesRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<List<SpaceReferenceItem>> listReferences({
    SpaceReferenceTypeGroup? typeGroup,
    SpaceReferenceType? type,
    String? query,
  }) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/space/references',
        headers: headers,
        queryParameters: {
          'typeGroup': typeGroup?.apiValue,
          'type': type?.apiValue,
          'q': query?.trim(),
        },
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SpaceReferenceItem.fromJson)
        .toList();
  }

  @override
  Future<SpaceReferenceCreateResult> createReference(
    CreateSpaceReferenceInput input,
  ) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/space/references',
        headers: headers,
        body: {'type': input.type.apiValue, 'name': input.name},
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return SpaceReferenceCreateResult.fromJson(data);
  }
}
