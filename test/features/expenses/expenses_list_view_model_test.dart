import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  test('load populates expenses from repository', () async {
    final repository = FakeExpensesRepository(
      result: PagedResult(
        items: [fakeExpense()],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      ),
    );
    final viewModel = ExpensesListViewModel(expensesRepository: repository);

    await viewModel.load();

    expect(repository.listCalls, 1);
    expect(viewModel.expenses, hasLength(1));
    expect(viewModel.expenses.first.description, 'Internet Fibra');
    expect(viewModel.errorMessage, isNull);
  });
}
