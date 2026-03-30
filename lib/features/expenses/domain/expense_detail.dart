import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';

class ExpenseDetail {
  const ExpenseDetail({
    required this.id,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.occurredOn,
    required this.category,
    required this.subcategory,
    required this.reference,
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
  final DateTime? dueDate;
  final DateTime occurredOn;
  final ExpenseReference category;
  final ExpenseReference subcategory;
  final ExpenseReference? reference;
  final String notes;
  final String status;
  final double paidAmount;
  final double remainingAmount;
  final int paymentsCount;
  final bool overdue;
  final List<ExpensePayment> payments;

  bool get hasNotes => notes.trim().isNotEmpty;
  bool get hasPayments => payments.isNotEmpty;
  bool get hasDueDate => dueDate != null;
  bool get hasReference => reference != null;

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseDetail(
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
