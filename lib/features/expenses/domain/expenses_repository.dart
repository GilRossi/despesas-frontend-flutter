import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';

abstract interface class ExpensesRepository {
  Future<PagedResult<ExpenseSummary>> listExpenses({
    int page = 0,
    int size = 20,
  });

  Future<ExpenseDetail> getExpenseDetail(int expenseId);

  Future<List<CatalogOption>> listCatalogOptions();

  Future<void> createExpense(SaveExpenseInput input);

  Future<void> updateExpense({
    required int expenseId,
    required SaveExpenseInput input,
  });

  Future<void> deleteExpense(int expenseId);

  Future<void> registerExpensePayment(CreateExpensePaymentInput input);
}
