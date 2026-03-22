import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';

abstract interface class HouseholdMembersRepository {
  Future<List<HouseholdMember>> listMembers();

  Future<HouseholdMember> createMember(CreateHouseholdMemberInput input);
}
