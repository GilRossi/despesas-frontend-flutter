class FixedBillGeneratedExpense {
  const FixedBillGeneratedExpense({
    required this.expenseId,
    required this.dueDate,
    required this.createdAt,
  });

  final int expenseId;
  final DateTime dueDate;
  final DateTime createdAt;

  factory FixedBillGeneratedExpense.fromJson(Map<String, dynamic> json) {
    return FixedBillGeneratedExpense(
      expenseId: (json['expenseId'] as num?)?.toInt() ?? 0,
      dueDate:
          DateTime.tryParse('${json['dueDate']}T00:00:00') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
