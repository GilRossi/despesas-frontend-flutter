import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_user.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/auth/domain/session_store.dart';
import 'package:despesas_frontend/features/expenses/domain/catalog_option.dart';
import 'package:despesas_frontend/features/expenses/domain/create_expense_payment_input.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_detail.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_payment.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_reference.dart';
import 'package:despesas_frontend/features/expenses/domain/expense_summary.dart';
import 'package:despesas_frontend/features/expenses/domain/expenses_repository.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.refreshResult,
    this.loginError,
    this.refreshError,
  });

  MobileSession? loginResult;
  MobileSession? refreshResult;
  Exception? loginError;
  Exception? refreshError;
  int refreshCalls = 0;

  @override
  Future<MobileSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) {
      throw loginError!;
    }
    return loginResult ?? fakeSession();
  }

  @override
  Future<MobileSession> refresh({required String refreshToken}) async {
    refreshCalls += 1;
    if (refreshError != null) {
      throw refreshError!;
    }
    return refreshResult ?? fakeSession();
  }
}

class MemorySessionStore implements SessionStore {
  String? refreshToken;
  bool cleared = false;

  @override
  Future<void> clear() async {
    refreshToken = null;
    cleared = true;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    this.refreshToken = refreshToken;
  }
}

class FakeExpensesRepository implements ExpensesRepository {
  FakeExpensesRepository({
    this.result,
    this.error,
    this.detailResult,
    this.detailError,
    this.catalogOptions,
    this.catalogError,
    this.createError,
    this.updateError,
    this.deleteError,
    this.registerPaymentError,
    this.onCreate,
    this.onUpdate,
    this.onDelete,
    this.onRegisterPayment,
  });

  PagedResult<ExpenseSummary>? result;
  Exception? error;
  ExpenseDetail? detailResult;
  Exception? detailError;
  List<CatalogOption>? catalogOptions;
  Exception? catalogError;
  Exception? createError;
  Exception? updateError;
  Exception? deleteError;
  Exception? registerPaymentError;
  void Function(SaveExpenseInput input)? onCreate;
  void Function(int expenseId, SaveExpenseInput input)? onUpdate;
  void Function(int expenseId)? onDelete;
  void Function(CreateExpensePaymentInput input)? onRegisterPayment;
  int listCalls = 0;
  int detailCalls = 0;
  int catalogCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int registerPaymentCalls = 0;
  SaveExpenseInput? lastCreatedInput;
  SaveExpenseInput? lastUpdatedInput;
  int? lastUpdatedExpenseId;
  int? lastDeletedExpenseId;
  CreateExpensePaymentInput? lastPaymentInput;

  @override
  Future<PagedResult<ExpenseSummary>> listExpenses({
    int page = 0,
    int size = 20,
  }) async {
    listCalls += 1;
    if (error != null) {
      throw error!;
    }
    return result ?? emptyPage();
  }

  @override
  Future<ExpenseDetail> getExpenseDetail(int expenseId) async {
    detailCalls += 1;
    if (detailError != null) {
      throw detailError!;
    }
    return detailResult ?? fakeExpenseDetail(id: expenseId);
  }

  @override
  Future<List<CatalogOption>> listCatalogOptions() async {
    catalogCalls += 1;
    if (catalogError != null) {
      throw catalogError!;
    }
    return catalogOptions ?? fakeCatalogOptions();
  }

  @override
  Future<void> createExpense(SaveExpenseInput input) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }
    onCreate?.call(input);
  }

  @override
  Future<void> updateExpense({
    required int expenseId,
    required SaveExpenseInput input,
  }) async {
    updateCalls += 1;
    lastUpdatedExpenseId = expenseId;
    lastUpdatedInput = input;
    if (updateError != null) {
      throw updateError!;
    }
    onUpdate?.call(expenseId, input);
  }

  @override
  Future<void> deleteExpense(int expenseId) async {
    deleteCalls += 1;
    lastDeletedExpenseId = expenseId;
    if (deleteError != null) {
      throw deleteError!;
    }
    onDelete?.call(expenseId);
  }

  @override
  Future<void> registerExpensePayment(CreateExpensePaymentInput input) async {
    registerPaymentCalls += 1;
    lastPaymentInput = input;
    if (registerPaymentError != null) {
      throw registerPaymentError!;
    }
    onRegisterPayment?.call(input);
  }
}

MobileSession fakeSession({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  String name = 'Gil Rossi',
  String email = 'gil@example.com',
}) {
  final now = DateTime.utc(2026, 3, 21, 10);
  return MobileSession(
    tokenType: 'Bearer',
    accessToken: accessToken,
    accessTokenExpiresAt: now.add(const Duration(minutes: 15)),
    refreshToken: refreshToken,
    refreshTokenExpiresAt: now.add(const Duration(days: 7)),
    user: AuthUser(
      userId: 1,
      householdId: 10,
      email: email,
      name: name,
      role: 'OWNER',
    ),
  );
}

ExpenseSummary fakeExpense({
  int id = 1,
  String description = 'Internet Fibra',
  double amount = 129.9,
  String category = 'Casa',
  String subcategory = 'Internet',
  String status = 'ABERTA',
}) {
  return ExpenseSummary(
    id: id,
    description: description,
    amount: amount,
    dueDate: DateTime.utc(2026, 3, 25),
    context: 'CASA',
    category: ExpenseReference(id: 1, name: category),
    subcategory: ExpenseReference(id: 2, name: subcategory),
    status: status,
    paidAmount: 0,
    remainingAmount: amount,
    overdue: false,
  );
}

ExpenseDetail fakeExpenseDetail({
  int id = 1,
  String description = 'Internet Fibra',
  double amount = 129.9,
  String category = 'Casa',
  String subcategory = 'Internet',
  String status = 'ABERTA',
  String notes = 'Conta mensal',
  double paidAmount = 40,
  double remainingAmount = 89.9,
  int paymentsCount = 1,
  bool overdue = false,
  List<ExpensePayment>? payments,
}) {
  return ExpenseDetail(
    id: id,
    description: description,
    amount: amount,
    dueDate: DateTime.utc(2026, 3, 25),
    context: 'CASA',
    category: ExpenseReference(id: 1, name: category),
    subcategory: ExpenseReference(id: 2, name: subcategory),
    notes: notes,
    status: status,
    paidAmount: paidAmount,
    remainingAmount: remainingAmount,
    paymentsCount: paymentsCount,
    overdue: overdue,
    payments: payments ?? [fakeExpensePayment()],
  );
}

ExpensePayment fakeExpensePayment({
  int id = 1,
  int expenseId = 1,
  double amount = 40,
  String method = 'PIX',
  String notes = 'Pagamento parcial',
}) {
  return ExpensePayment(
    id: id,
    expenseId: expenseId,
    amount: amount,
    paidAt: DateTime.utc(2026, 3, 20),
    method: method,
    notes: notes,
  );
}

PagedResult<ExpenseSummary> emptyPage() {
  return const PagedResult(
    items: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    hasNext: false,
    hasPrevious: false,
  );
}

List<CatalogOption> fakeCatalogOptions() {
  return const [
    CatalogOption(
      id: 1,
      name: 'Casa',
      subcategories: [
        ExpenseReference(id: 11, name: 'Internet'),
        ExpenseReference(id: 12, name: 'Energia'),
      ],
    ),
    CatalogOption(
      id: 2,
      name: 'Veiculo',
      subcategories: [ExpenseReference(id: 21, name: 'Combustivel')],
    ),
  ];
}

ApiException fakeApiException({
  int statusCode = 422,
  String message = 'Falha simulada',
  Map<String, String> fieldErrors = const {},
}) {
  return ApiException(
    statusCode: statusCode,
    message: message,
    fieldErrors: fieldErrors,
  );
}
