import 'package:despesas_frontend/features/incomes/domain/income_reference.dart';

class IncomeRecord {
  const IncomeRecord({
    required this.id,
    required this.description,
    required this.amount,
    required this.receivedOn,
    required this.createdAt,
    this.spaceReference,
  });

  final int id;
  final String description;
  final double amount;
  final DateTime receivedOn;
  final IncomeReference? spaceReference;
  final DateTime createdAt;

  factory IncomeRecord.fromJson(Map<String, dynamic> json) {
    final spaceReferenceJson = json['spaceReference'] as Map<String, dynamic>?;

    return IncomeRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      receivedOn:
          DateTime.tryParse(json['receivedOn'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      spaceReference: spaceReferenceJson == null
          ? null
          : IncomeReference.fromJson(spaceReferenceJson),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
