class EmailIngestionReviewActionResult {
  const EmailIngestionReviewActionResult({
    required this.ingestionId,
    required this.decision,
    required this.decisionReason,
    required this.expenseId,
  });

  final int ingestionId;
  final String decision;
  final String decisionReason;
  final int? expenseId;

  factory EmailIngestionReviewActionResult.fromJson(Map<String, dynamic> json) {
    return EmailIngestionReviewActionResult(
      ingestionId: _toInt(json['ingestionId']),
      decision: json['decision'] as String? ?? '',
      decisionReason: json['decisionReason'] as String? ?? '',
      expenseId: _toNullableInt(json['expenseId']),
    );
  }

  static int _toInt(Object? value) {
    return switch (value) {
      int number => number,
      double number => number.toInt(),
      String number => int.parse(number),
      _ => 0,
    };
  }

  static int? _toNullableInt(Object? value) {
    return switch (value) {
      null => null,
      int number => number,
      double number => number.toInt(),
      String number => int.parse(number),
      _ => null,
    };
  }
}
