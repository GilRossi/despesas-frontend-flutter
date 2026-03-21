import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';

class EmailIngestionReviewDetail {
  const EmailIngestionReviewDetail({
    required this.ingestionId,
    required this.sourceAccount,
    required this.externalMessageId,
    required this.sender,
    required this.subject,
    required this.receivedAt,
    required this.merchantOrPayee,
    required this.suggestedCategoryName,
    required this.suggestedSubcategoryName,
    required this.totalAmount,
    required this.dueDate,
    required this.occurredOn,
    required this.currency,
    required this.summary,
    required this.classification,
    required this.confidence,
    required this.rawReference,
    required this.desiredDecision,
    required this.finalDecision,
    required this.decisionReason,
    required this.importedExpenseId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final int ingestionId;
  final String sourceAccount;
  final String externalMessageId;
  final String sender;
  final String subject;
  final DateTime receivedAt;
  final String merchantOrPayee;
  final String suggestedCategoryName;
  final String suggestedSubcategoryName;
  final double totalAmount;
  final DateTime? dueDate;
  final DateTime? occurredOn;
  final String currency;
  final String summary;
  final String classification;
  final double confidence;
  final String rawReference;
  final String desiredDecision;
  final String finalDecision;
  final String decisionReason;
  final int? importedExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EmailIngestionReviewItem> items;

  bool get hasItems => items.isNotEmpty;

  factory EmailIngestionReviewDetail.fromJson(Map<String, dynamic> json) {
    return EmailIngestionReviewDetail(
      ingestionId: _toInt(json['ingestionId']),
      sourceAccount: json['sourceAccount'] as String? ?? '',
      externalMessageId: json['externalMessageId'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      merchantOrPayee: json['merchantOrPayee'] as String? ?? '',
      suggestedCategoryName: json['suggestedCategoryName'] as String? ?? '',
      suggestedSubcategoryName:
          json['suggestedSubcategoryName'] as String? ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      dueDate: _toNullableDate(json['dueDate']),
      occurredOn: _toNullableDate(json['occurredOn']),
      currency: json['currency'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      confidence: _toDouble(json['confidence']),
      rawReference: json['rawReference'] as String? ?? '',
      desiredDecision: json['desiredDecision'] as String? ?? '',
      finalDecision: json['finalDecision'] as String? ?? '',
      decisionReason: json['decisionReason'] as String? ?? '',
      importedExpenseId: _toNullableInt(json['importedExpenseId']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                EmailIngestionReviewItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
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

  static double _toDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String number => double.parse(number),
      _ => 0,
    };
  }

  static DateTime? _toNullableDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse('${value}T00:00:00');
  }
}
