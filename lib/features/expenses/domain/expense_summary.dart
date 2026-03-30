import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';

class ExpenseSummary {
  const ExpenseSummary({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.occurredOn,
    required this.category,
    required this.subcategory,
    required this.reference,
    required this.status,
    required this.paidAmount,
    required this.remainingAmount,
    required this.overdue,
  });

  final int id;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final DateTime occurredOn;
  final ExpenseReference category;
  final ExpenseReference subcategory;
  final ExpenseReference? reference;
  final String status;
  final double paidAmount;
  final double remainingAmount;
  final bool overdue;

  bool get hasDueDate => dueDate != null;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: _toDouble(json['amount']),
      dueDate: _toNullableDate(json['dueDate']),
      occurredOn: DateTime.parse('${json['occurredOn']}T00:00:00'),
      category: ExpenseReference.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      subcategory: ExpenseReference.fromJson(
        json['subcategory'] as Map<String, dynamic>,
      ),
      reference: json['reference'] is Map<String, dynamic>
          ? ExpenseReference.fromJson(json['reference'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      overdue: json['overdue'] as bool? ?? false,
    );
  }

  static DateTime? _toNullableDate(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.parse('${text}T00:00:00');
  }

  static double _toDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String number => double.parse(number),
      _ => 0,
    };
  }
}
