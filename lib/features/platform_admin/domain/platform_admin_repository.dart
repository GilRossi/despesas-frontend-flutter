import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_health.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_overview.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_space.dart';

abstract interface class PlatformAdminRepository {
  Future<PlatformAdminOverview> fetchOverview();

  Future<PlatformAdminHealth> fetchHealth();

  Future<List<PlatformAdminSpace>> fetchSpaces();

  Future<PlatformAdminHousehold> createHouseholdWithOwner(
    CreateHouseholdOwnerInput input,
  );

  Future<AdminPasswordResetResult> resetUserPassword(
    AdminPasswordResetInput input,
  );
}
