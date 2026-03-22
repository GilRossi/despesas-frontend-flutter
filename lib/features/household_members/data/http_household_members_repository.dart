import 'dart:convert';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/core/network/authorized_request_executor.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';

class HttpHouseholdMembersRepository implements HouseholdMembersRepository {
  HttpHouseholdMembersRepository(this._authorizedRequestExecutor);

  final AuthorizedRequestExecutor _authorizedRequestExecutor;

  @override
  Future<List<HouseholdMember>> listMembers() async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.get(
        '/api/v1/household/members',
        headers: headers,
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => HouseholdMember.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<HouseholdMember> createMember(CreateHouseholdMemberInput input) async {
    final response = await _authorizedRequestExecutor.run((headers) {
      return _authorizedRequestExecutor.apiClient.postJson(
        '/api/v1/household/members',
        headers: headers,
        body: {
          'name': input.name,
          'email': input.email,
          'password': input.password,
        },
      );
    });

    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    return HouseholdMember.fromJson(data);
  }
}
