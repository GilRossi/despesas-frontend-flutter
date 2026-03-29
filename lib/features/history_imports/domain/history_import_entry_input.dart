class HistoryImportEntryInput {
  const HistoryImportEntryInput({
    required this.description,
    required this.amount,
    required this.date,
    required this.context,
    required this.categoryId,
    required this.subcategoryId,
    this.notes,
  });

  final String description;
  final double amount;
  final DateTime date;
  final String context;
  final int categoryId;
  final int subcategoryId;
  final String? notes;

  Map<String, Object?> toJson() {
    final normalizedNotes = notes?.trim();
    return {
      'description': description.trim(),
      'amount': amount,
      'date': _formatDate(date),
      'context': context,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      if (normalizedNotes != null && normalizedNotes.isNotEmpty)
        'notes': normalizedNotes,
    };
  }

  static String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
