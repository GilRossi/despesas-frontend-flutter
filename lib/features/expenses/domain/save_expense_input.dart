class SaveExpenseInput {
  const SaveExpenseInput({
    required this.description,
    required this.amount,
    required this.occurredOn,
    required this.dueDate,
    required this.categoryId,
    required this.subcategoryId,
    required this.spaceReferenceId,
    required this.notes,
    this.initialPayment,
  });

  final String description;
  final double amount;
  final DateTime occurredOn;
  final DateTime? dueDate;
  final int categoryId;
  final int subcategoryId;
  final int? spaceReferenceId;
  final String notes;
  final ExpenseInitialPaymentInput? initialPayment;

  Map<String, Object?> toJson({bool includeInitialPayment = true}) {
    return {
      'description': description,
      'amount': amount,
      'occurredOn': _formatDate(occurredOn),
      'dueDate': dueDate == null ? null : _formatDate(dueDate!),
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'spaceReferenceId': spaceReferenceId,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      if (includeInitialPayment && initialPayment != null)
        'initialPayment': initialPayment!.toJson(),
    };
  }
}

class ExpenseInitialPaymentInput {
  const ExpenseInitialPaymentInput({
    required this.paidAt,
    required this.method,
  });

  final DateTime paidAt;
  final String method;

  Map<String, Object?> toJson() {
    return {
      'paidAt': _formatDate(paidAt),
      'method': method,
    };
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
