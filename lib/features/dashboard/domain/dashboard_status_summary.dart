class DashboardStatusSummary {
  const DashboardStatusSummary({
    required this.status,
    required this.count,
    required this.amount,
  });

  final String status;
  final int count;
  final double amount;

  factory DashboardStatusSummary.fromJson(Map<String, dynamic> json) {
    return DashboardStatusSummary(
      status: json['status'] as String,
      count: (json['count'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
