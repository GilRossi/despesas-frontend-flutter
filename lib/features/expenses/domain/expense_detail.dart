import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';

class ExpenseDetail {
  const ExpenseDetail({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.context,
    required this.category,
    required this.subcategory,
    required this.notes,
    required this.status,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentsCount,
    required this.overdue,
    required this.payments,
  });

  final int id;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String context;
  final ExpenseReference category;
  final ExpenseReference subcategory;
  final String notes;
  final String status;
  final double paidAmount;
  final double remainingAmount;
  final int paymentsCount;
  final bool overdue;
  final List<ExpensePayment> payments;

  bool get hasNotes => notes.trim().isNotEmpty;
  bool get hasPayments => payments.isNotEmpty;

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseDetail(
      id: json['id'] as int,
      description: json['description'] as String,
      amount: _toDouble(json['amount']),
      dueDate: DateTime.parse('${json['dueDate']}T00:00:00'),
      context: json['context'] as String,
      category: ExpenseReference.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      subcategory: ExpenseReference.fromJson(
        json['subcategory'] as Map<String, dynamic>,
      ),
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String,
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      paymentsCount: json['paymentsCount'] as int? ?? 0,
      overdue: json['overdue'] as bool? ?? false,
      payments: (json['payments'] as List<dynamic>? ?? const [])
          .map((item) => ExpensePayment.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
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
