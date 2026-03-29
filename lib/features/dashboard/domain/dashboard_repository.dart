import 'package:despesas_frontend/features/dashboard/domain/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchDashboard();
}
