import 'package:despesas_frontend/core/network/api_exception.dart';
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
      'Nao foi possivel carregar o detalhe da despesa.',
    );
    expect(viewModel.isNotFound, isFalse);
  });
}
