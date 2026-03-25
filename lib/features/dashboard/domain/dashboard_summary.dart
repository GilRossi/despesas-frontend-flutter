import 'package:despesas_frontend/features/dashboard/domain/dashboard_status_summary.dart';
class DashboardSummary {
  const DashboardSummary({
    required this.householdId,
    required this.totalExpenses,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.overdueCount,
    required this.overdueAmount,
    required this.openCount,
    required this.openAmount,
    required this.statuses,
  });

  final int householdId;
  final int totalExpenses;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int overdueCount;
  final double overdueAmount;
  final int openCount;
  final double openAmount;
  final List<DashboardStatusSummary> statuses;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      householdId: (json['householdId'] as num).toInt(),
      totalExpenses: (json['totalExpenses'] as num).toInt(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      overdueCount: (json['overdueCount'] as num).toInt(),
      overdueAmount: (json['overdueAmount'] as num).toDouble(),
      openCount: (json['openCount'] as num).toInt(),
      openAmount: (json['openAmount'] as num).toDouble(),
      statuses: (json['statuses'] as List<dynamic>? ?? [])
          .map((item) => DashboardStatusSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
