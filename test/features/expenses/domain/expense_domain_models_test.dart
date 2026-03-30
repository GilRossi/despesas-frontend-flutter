import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense summary decodes mixed numeric payloads', () {
    final summary = ExpenseSummary.fromJson({
      'id': 7,
      'description': 'Conta de luz',
      'amount': '129.90',
      'dueDate': '2026-03-25',
      'occurredOn': '2026-03-20',
      'category': {'id': 1, 'name': 'Casa'},
      'subcategory': {'id': 11, 'name': 'Energia'},
      'reference': {'id': 99, 'name': 'Apartamento 12'},
      'status': 'ABERTA',
      'paidAmount': 20,
      'remainingAmount': 109.9,
      'overdue': true,
    });

    expect(summary.id, 7);
    expect(summary.amount, 129.9);
    expect(summary.paidAmount, 20);
    expect(summary.remainingAmount, 109.9);
    expect(summary.overdue, isTrue);
    expect(summary.category.name, 'Casa');
    expect(summary.subcategory.id, 11);
    expect(summary.reference?.name, 'Apartamento 12');
  });

  test('expense detail decodes payments and derived flags', () {
    final detail = ExpenseDetail.fromJson({
      'id': 9,
      'description': 'Internet',
      'amount': 99,
      'dueDate': '2026-03-31',
      'occurredOn': '2026-03-20',
      'category': {'id': 1, 'name': 'Casa'},
      'subcategory': {'id': 11, 'name': 'Internet'},
      'reference': {'id': 7, 'name': 'Casa principal'},
      'notes': 'Conta da operadora',
      'status': 'PARCIALMENTE_PAGA',
      'paidAmount': '40.00',
      'remainingAmount': '59.00',
      'paymentsCount': 1,
      'overdue': false,
      'payments': [
        {
          'id': 15,
          'expenseId': 9,
          'amount': '40.00',
          'paidAt': '2026-03-20',
          'method': 'PIX',
          'notes': 'Primeira parcela',
        },
      ],
    });

    expect(detail.id, 9);
    expect(detail.amount, 99);
    expect(detail.paidAmount, 40);
    expect(detail.remainingAmount, 59);
    expect(detail.hasNotes, isTrue);
    expect(detail.hasPayments, isTrue);
    expect(detail.payments.single.method, 'PIX');
    expect(detail.payments.single.hasNotes, isTrue);
    expect(detail.reference?.name, 'Casa principal');
  });

  test('expense payment and references handle defaults and conversion', () {
    final payment = ExpensePayment.fromJson({
      'id': 3,
      'expenseId': 9,
      'amount': 15,
      'paidAt': '2026-03-18',
      'method': 'DINHEIRO',
      'notes': '  ',
    });
    final reference = ExpenseReference.fromJson({'id': 11, 'name': 'Internet'});
    final emptyDetail = ExpenseDetail.fromJson({
      'id': 1,
      'description': 'Teste',
      'amount': null,
      'dueDate': '2026-03-01',
      'occurredOn': '2026-03-01',
      'category': {'id': 1, 'name': 'Casa'},
      'subcategory': {'id': 2, 'name': 'Mercado'},
      'status': 'ABERTA',
      'paidAmount': null,
      'remainingAmount': null,
    });

    expect(payment.amount, 15);
    expect(payment.hasNotes, isFalse);
    expect(reference.id, 11);
    expect(reference.name, 'Internet');
    expect(emptyDetail.notes, '');
    expect(emptyDetail.payments, isEmpty);
    expect(emptyDetail.hasNotes, isFalse);
    expect(emptyDetail.hasPayments, isFalse);
    expect(emptyDetail.reference, isNull);
  });

  test('catalog option and save expense input map to the form contract', () {
    final option = CatalogOption.fromJson({
      'id': '1',
      'name': 'Casa',
      'subcategories': [
        {'id': 11, 'name': 'Internet'},
      ],
    });
    final inputWithNotes = SaveExpenseInput(
      description: 'Mercado',
      amount: 120.5,
      occurredOn: DateTime.utc(2026, 3, 29),
      dueDate: DateTime.utc(2026, 3, 29),
      categoryId: 1,
      subcategoryId: 11,
      spaceReferenceId: 77,
      notes: '  compra da semana  ',
    );
    final inputWithoutNotes = SaveExpenseInput(
      description: 'Mercado',
      amount: 120.5,
      occurredOn: DateTime.utc(2026, 3, 29),
      dueDate: DateTime.utc(2026, 3, 29),
      categoryId: 1,
      subcategoryId: 11,
      spaceReferenceId: null,
      notes: '   ',
    );

    expect(option.id, 1);
    expect(option.subcategories.single.name, 'Internet');
    expect(inputWithNotes.toJson()['occurredOn'], '2026-03-29');
    expect(inputWithNotes.toJson()['dueDate'], '2026-03-29');
    expect(inputWithNotes.toJson()['spaceReferenceId'], 77);
    expect(inputWithNotes.toJson()['notes'], 'compra da semana');
    expect(inputWithoutNotes.toJson()['notes'], isNull);
  });
}
