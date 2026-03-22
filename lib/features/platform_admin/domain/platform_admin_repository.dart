import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';

abstract interface class PlatformAdminRepository {
  Future<PlatformAdminHousehold> createHouseholdWithOwner(
    CreateHouseholdOwnerInput input,
  );
}
