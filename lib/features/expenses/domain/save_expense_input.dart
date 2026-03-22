class SaveExpenseInput {
  const SaveExpenseInput({
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.context,
    required this.categoryId,
    required this.subcategoryId,
    required this.notes,
  });

  final String description;
  final double amount;
  final DateTime dueDate;
  final String context;
  final int categoryId;
  final int subcategoryId;
  final String notes;

  Map<String, Object?> toJson() {
    final day = dueDate.day.toString().padLeft(2, '0');
    final month = dueDate.month.toString().padLeft(2, '0');

    return {
      'description': description,
      'amount': amount,
      'dueDate': '${dueDate.year}-$month-$day',
      'context': context,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'notes': notes.trim().isEmpty ? null : notes.trim(),
    };
  }
}
