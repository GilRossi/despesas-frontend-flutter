import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses review summary and detail payloads with nested items', () {
    final summary = EmailIngestionReviewSummary.fromJson({
      'ingestionId': '51',
      'sourceAccount': 'financeiro@example.com',
      'sender': 'noreply@loja.com',
      'subject': 'Compra confirmada',
      'receivedAt': '2026-03-21T10:00:00Z',
      'merchantOrPayee': 'Loja Central',
      'totalAmount': '129.90',
      'currency': 'BRL',
      'summary': 'Compra de supermercado',
      'classification': 'EXPENSE',
      'confidence': 0.91,
      'decisionReason': 'Regras deterministicas',
    });

    final detail = EmailIngestionReviewDetail.fromJson({
      'ingestionId': 52,
      'sourceAccount': 'financeiro@example.com',
      'externalMessageId': 'abc-123',
      'sender': 'noreply@loja.com',
      'subject': 'Compra confirmada',
      'receivedAt': '2026-03-21T10:00:00Z',
      'merchantOrPayee': 'Loja Central',
      'suggestedCategoryName': 'Mercado',
      'suggestedSubcategoryName': 'Supermercado',
      'totalAmount': '129.90',
      'dueDate': '2026-03-25',
      'occurredOn': '2026-03-20',
      'currency': 'BRL',
      'summary': 'Compra de supermercado',
      'classification': 'EXPENSE',
      'confidence': '0.91',
      'rawReference': 'ref-1',
      'desiredDecision': 'IMPORT',
      'finalDecision': 'IMPORTED',
      'decisionReason': 'Regras deterministicas',
      'importedExpenseId': '77',
      'createdAt': '2026-03-21T10:00:00Z',
      'updatedAt': '2026-03-21T10:10:00Z',
      'items': [
        {
          'description': 'Arroz',
          'amount': '10.5',
          'quantity': '2',
        },
      ],
    });

    expect(summary.ingestionId, 51);
    expect(summary.totalAmount, 129.9);
    expect(summary.confidence, 0.91);
    expect(detail.hasItems, isTrue);
    expect(detail.importedExpenseId, 77);
    expect(detail.dueDate, DateTime(2026, 3, 25));
    expect(detail.occurredOn, DateTime(2026, 3, 20));
    expect(detail.items.single.description, 'Arroz');
    expect(detail.items.single.quantity, 2);
  });

  test('falls back to defaults when optional review fields are absent', () {
    final summary = EmailIngestionReviewSummary.fromJson({
      'ingestionId': 1,
      'receivedAt': '2026-03-21T10:00:00Z',
    });
    final detail = EmailIngestionReviewDetail.fromJson({
      'ingestionId': 1,
      'sourceAccount': 'financeiro@example.com',
      'externalMessageId': 'abc-123',
      'sender': 'noreply@loja.com',
      'subject': 'Compra confirmada',
      'receivedAt': '2026-03-21T10:00:00Z',
      'merchantOrPayee': 'Loja Central',
      'suggestedCategoryName': 'Mercado',
      'suggestedSubcategoryName': 'Supermercado',
      'totalAmount': 0,
      'currency': 'BRL',
      'summary': 'Compra de supermercado',
      'classification': 'EXPENSE',
      'confidence': 0,
      'rawReference': 'ref-1',
      'desiredDecision': 'IMPORT',
      'finalDecision': 'IMPORTED',
      'decisionReason': '',
      'importedExpenseId': null,
      'createdAt': '2026-03-21T10:00:00Z',
      'updatedAt': '2026-03-21T10:10:00Z',
      'dueDate': null,
      'occurredOn': '',
      'items': const [],
    });
    final item = EmailIngestionReviewItem.fromJson({
      'description': 'Cafe',
      'amount': 9,
      'quantity': null,
    });

    expect(summary.sourceAccount, isEmpty);
    expect(summary.totalAmount, 0);
    expect(detail.dueDate, isNull);
    expect(detail.occurredOn, isNull);
    expect(detail.items, isEmpty);
    expect(detail.hasItems, isFalse);
    expect(item.quantity, isNull);
  });
}
