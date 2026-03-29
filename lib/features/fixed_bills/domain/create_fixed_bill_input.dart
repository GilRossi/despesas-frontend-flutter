import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';

class CreateFixedBillInput {
  const CreateFixedBillInput({
    required this.description,
    required this.amount,
    required this.firstDueDate,
    required this.frequency,
    required this.context,
    required this.categoryId,
    required this.subcategoryId,
    this.spaceReferenceId,
  });

  final String description;
  final double amount;
  final DateTime firstDueDate;
  final FixedBillFrequency frequency;
  final String context;
  final int categoryId;
  final int subcategoryId;
  final int? spaceReferenceId;

  Map<String, Object?> toJson() {
    final month = firstDueDate.month.toString().padLeft(2, '0');
    final day = firstDueDate.day.toString().padLeft(2, '0');

    return {
      'description': description.trim(),
      'amount': amount,
      'firstDueDate': '${firstDueDate.year}-$month-$day',
      'frequency': frequency.apiValue,
      'context': context,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'spaceReferenceId': spaceReferenceId,
    };
  }
}
