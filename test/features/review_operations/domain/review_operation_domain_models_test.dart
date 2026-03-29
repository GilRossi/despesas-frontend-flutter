import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review detail decodes nested items and derived flags', () {
    final detail = EmailIngestionReviewDetail.fromJson({
      'ingestionId': '42',
      'sourceAccount': 'fatura@email.com',
      'externalMessageId': 'msg-42',
      'sender': 'Banco',
      'subject': 'Sua fatura',
      'receivedAt': '2026-03-29T12:00:00Z',
      'merchantOrPayee': 'Mercado',
      'suggestedCategoryName': 'Casa',
      'suggestedSubcategoryName': 'Mercado',
      'totalAmount': '129.90',
      'dueDate': '2026-04-05',
      'occurredOn': '2026-03-28',
      'currency': 'BRL',
      'summary': 'Compra da semana',
      'classification': 'MANUAL_PURCHASE',
      'confidence': 0.85,
      'rawReference': 'ref-42',
      'desiredDecision': 'REVIEW',
      'finalDecision': 'REVIEW_REQUIRED',
      'decisionReason': 'LOW_CONFIDENCE',
      'importedExpenseId': 9.0,
      'createdAt': '2026-03-29T12:00:00Z',
      'updatedAt': '2026-03-29T12:05:00Z',
      'items': [
        {'description': 'Arroz', 'amount': 19.9, 'quantity': '2'},
      ],
    });

    expect(detail.ingestionId, 42);
    expect(detail.sourceAccount, 'fatura@email.com');
    expect(detail.externalMessageId, 'msg-42');
    expect(detail.receivedAt, DateTime.parse('2026-03-29T12:00:00Z'));
    expect(detail.totalAmount, 129.9);
    expect(detail.dueDate, DateTime.parse('2026-04-05T00:00:00'));
    expect(detail.occurredOn, DateTime.parse('2026-03-28T00:00:00'));
    expect(detail.importedExpenseId, 9);
    expect(detail.hasItems, isTrue);
    expect(detail.items.single.description, 'Arroz');
    expect(detail.items.single.quantity, 2);
  });

  test('review detail handles nullish values and optional fields', () {
    final detail = EmailIngestionReviewDetail.fromJson({
      'ingestionId': 7,
      'receivedAt': '2026-03-29T12:00:00Z',
      'createdAt': '2026-03-29T12:00:00Z',
      'updatedAt': '2026-03-29T12:05:00Z',
      'totalAmount': null,
      'confidence': null,
      'dueDate': '',
      'occurredOn': null,
      'importedExpenseId': null,
    });

    expect(detail.sourceAccount, '');
    expect(detail.totalAmount, 0);
    expect(detail.confidence, 0);
    expect(detail.dueDate, isNull);
    expect(detail.occurredOn, isNull);
    expect(detail.importedExpenseId, isNull);
    expect(detail.items, isEmpty);
    expect(detail.hasItems, isFalse);
  });

  test('review summary, item and action result decode mixed numeric shapes', () {
    final summary = EmailIngestionReviewSummary.fromJson({
      'ingestionId': 4.0,
      'sourceAccount': 'cartao@email.com',
      'sender': 'Banco',
      'subject': 'Compra',
      'receivedAt': '2026-03-29T12:00:00Z',
      'merchantOrPayee': 'Padaria',
      'totalAmount': 59,
      'currency': 'BRL',
      'summary': 'Resumo',
      'classification': 'RECURRING_BILL',
      'confidence': '0.91',
      'decisionReason': 'REVIEW_REQUESTED',
    });
    final item = EmailIngestionReviewItem.fromJson({
      'description': 'Cafe',
      'amount': '4.50',
      'quantity': 2,
    });
    final action = EmailIngestionReviewActionResult.fromJson({
      'ingestionId': '8',
      'decision': 'APPROVED',
      'decisionReason': 'IMPORTED',
      'expenseId': '11',
    });
    final nullQuantityItem = EmailIngestionReviewItem.fromJson({
      'description': null,
      'amount': null,
      'quantity': null,
    });

    expect(summary.ingestionId, 4);
    expect(summary.totalAmount, 59);
    expect(summary.confidence, 0.91);
    expect(item.amount, 4.5);
    expect(item.quantity, 2);
    expect(action.ingestionId, 8);
    expect(action.expenseId, 11);
    expect(nullQuantityItem.description, '');
    expect(nullQuantityItem.amount, 0);
    expect(nullQuantityItem.quantity, isNull);
  });
}
