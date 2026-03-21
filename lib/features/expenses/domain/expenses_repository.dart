import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';

abstract interface class ExpensesRepository {
  Future<PagedResult<ExpenseSummary>> listExpenses({
    int page = 0,
    int size = 20,
  });

  Future<ExpenseDetail> getExpenseDetail(int expenseId);
}
