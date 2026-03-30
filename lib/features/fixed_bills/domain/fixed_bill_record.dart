import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_reference.dart';

class FixedBillRecord {
  const FixedBillRecord({
    required this.id,
    required this.description,
    required this.amount,
    required this.firstDueDate,
    required this.frequency,
    required this.category,
    required this.subcategory,
    required this.active,
    required this.createdAt,
    this.spaceReference,
  });

  final int id;
  final String description;
  final double amount;
  final DateTime firstDueDate;
  final FixedBillFrequency frequency;
  final FixedBillReference category;
  final FixedBillReference subcategory;
  final FixedBillReference? spaceReference;
  final bool active;
  final DateTime createdAt;

  factory FixedBillRecord.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>? ?? const {};
    final subcategoryJson =
        json['subcategory'] as Map<String, dynamic>? ?? const {};
    final spaceReferenceJson = json['spaceReference'] as Map<String, dynamic>?;

    return FixedBillRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      firstDueDate:
          DateTime.tryParse(json['firstDueDate'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      frequency: FixedBillFrequency.fromApiValue(
        json['frequency'] as String? ?? '',
      ),
      category: FixedBillReference.fromJson(categoryJson),
      subcategory: FixedBillReference.fromJson(subcategoryJson),
      spaceReference: spaceReferenceJson == null
          ? null
          : FixedBillReference.fromJson(spaceReferenceJson),
      active: json['active'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
