class EmailIngestionReviewSummary {
  const EmailIngestionReviewSummary({
    required this.ingestionId,
    required this.sourceAccount,
    required this.sender,
    required this.subject,
    required this.receivedAt,
    required this.merchantOrPayee,
    required this.totalAmount,
    required this.currency,
    required this.summary,
    required this.classification,
    required this.confidence,
    required this.decisionReason,
  });

  final int ingestionId;
  final String sourceAccount;
  final String sender;
  final String subject;
  final DateTime receivedAt;
  final String merchantOrPayee;
  final double totalAmount;
  final String currency;
  final String summary;
  final String classification;
  final double confidence;
  final String decisionReason;

  factory EmailIngestionReviewSummary.fromJson(Map<String, dynamic> json) {
    return EmailIngestionReviewSummary(
      ingestionId: _toInt(json['ingestionId']),
      sourceAccount: json['sourceAccount'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      merchantOrPayee: json['merchantOrPayee'] as String? ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      currency: json['currency'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      confidence: _toDouble(json['confidence']),
      decisionReason: json['decisionReason'] as String? ?? '',
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

  static double _toDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String number => double.parse(number),
      _ => 0,
    };
  }
}
