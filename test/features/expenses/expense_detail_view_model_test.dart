import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('load populates expense detail from repository', () async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(description: 'Conta de Luz'),
    );
    final viewModel = ExpenseDetailViewModel(
      expenseId: 10,
      expensesRepository: repository,
    );

    await viewModel.load();

    expect(viewModel.expense?.description, 'Conta de Luz');
    expect(viewModel.isNotFound, isFalse);
    expect(viewModel.errorMessage, isNull);
    expect(repository.detailCalls, 1);
  });

  test('load exposes not found state when backend returns 404', () async {
    final viewModel = ExpenseDetailViewModel(
      expenseId: 99,
      expensesRepository: FakeExpensesRepository(
        detailError: const ApiException(statusCode: 404, message: 'Nao achou'),
      ),
    );

    await viewModel.load();

    expect(viewModel.isNotFound, isTrue);
    expect(viewModel.expense, isNull);
    expect(viewModel.errorMessage, isNull);
  });

  test('load exposes generic error message for unexpected failure', () async {
    final viewModel = ExpenseDetailViewModel(
      expenseId: 11,
      expensesRepository: FakeExpensesRepository(
        detailError: Exception('Falha inesperada'),
      ),
    );

    await viewModel.load();

    expect(
      viewModel.errorMessage,
      'Não foi possível carregar o detalhe da despesa.',
    );
    expect(viewModel.isNotFound, isFalse);
  });

  test('registerPayment reloads detail after success', () async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 89.9,
        paymentsCount: 1,
      ),
      onRegisterPayment: (_) {},
    );
    repository.onRegisterPayment = (input) {
      repository.detailResult = fakeExpenseDetail(
        paidAmount: 89.9,
        remainingAmount: 40,
        paymentsCount: 2,
        payments: [
          fakeExpensePayment(id: 2, amount: 49.9, notes: 'Novo pagamento'),
          fakeExpensePayment(),
        ],
      );
    };

    final viewModel = ExpenseDetailViewModel(
      expenseId: 10,
      expensesRepository: repository,
    );

    await viewModel.load();
    final success = await viewModel.registerPayment(
      CreateExpensePaymentInput(
        expenseId: 10,
        amount: 49.9,
        paidAt: DateTime.utc(2026, 3, 21),
        method: 'PIX',
        notes: 'Novo pagamento',
      ),
    );

    expect(success, isTrue);
    expect(viewModel.paymentErrorMessage, isNull);
    expect(viewModel.expense?.paymentsCount, 2);
    expect(viewModel.expense?.payments.first.notes, 'Novo pagamento');
    expect(repository.registerPaymentCalls, 1);
    expect(repository.detailCalls, 2);
  });

  test('registerPayment exposes API message when submission fails', () async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(),
      registerPaymentError: fakeApiException(
        statusCode: 422,
        message: 'Payment amount exceeds remaining expense balance',
      ),
    );
    final viewModel = ExpenseDetailViewModel(
      expenseId: 10,
      expensesRepository: repository,
    );

    await viewModel.load();
    final success = await viewModel.registerPayment(
      CreateExpensePaymentInput(
        expenseId: 10,
        amount: 200,
        paidAt: DateTime.utc(2026, 3, 21),
        method: 'PIX',
        notes: '',
      ),
    );

    expect(success, isFalse);
    expect(
      viewModel.paymentErrorMessage,
      'Payment amount exceeds remaining expense balance',
    );
    expect(repository.registerPaymentCalls, 1);
  });
}
