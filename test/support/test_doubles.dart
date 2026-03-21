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
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';

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

class FakeReviewOperationsRepository implements ReviewOperationsRepository {
  FakeReviewOperationsRepository({
    this.listResult,
    this.listError,
    this.detailResult,
    this.detailError,
    this.approveResult,
    this.approveError,
    this.rejectResult,
    this.rejectError,
    this.onApprove,
    this.onReject,
  });

  PagedResult<EmailIngestionReviewSummary>? listResult;
  Exception? listError;
  EmailIngestionReviewDetail? detailResult;
  Exception? detailError;
  EmailIngestionReviewActionResult? approveResult;
  Exception? approveError;
  EmailIngestionReviewActionResult? rejectResult;
  Exception? rejectError;
  void Function(int ingestionId)? onApprove;
  void Function(int ingestionId)? onReject;
  int listCalls = 0;
  int detailCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;
  int? lastDetailId;
  int? lastApprovedId;
  int? lastRejectedId;

  @override
  Future<PagedResult<EmailIngestionReviewSummary>> listPendingReviews({
    int page = 0,
    int size = 20,
  }) async {
    listCalls += 1;
    if (listError != null) {
      throw listError!;
    }
    return listResult ?? emptyReviewPage();
  }

  @override
  Future<EmailIngestionReviewDetail> getReviewDetail(int ingestionId) async {
    detailCalls += 1;
    lastDetailId = ingestionId;
    if (detailError != null) {
      throw detailError!;
    }
    return detailResult ?? fakeReviewDetail(ingestionId: ingestionId);
  }

  @override
  Future<EmailIngestionReviewActionResult> approveReview(
    int ingestionId,
  ) async {
    approveCalls += 1;
    lastApprovedId = ingestionId;
    if (approveError != null) {
      throw approveError!;
    }
    onApprove?.call(ingestionId);
    return approveResult ??
        fakeReviewActionResult(
          ingestionId: ingestionId,
          decision: 'AUTO_IMPORTED',
          decisionReason: 'MANUALLY_IMPORTED',
          expenseId: 88,
        );
  }

  @override
  Future<EmailIngestionReviewActionResult> rejectReview(int ingestionId) async {
    rejectCalls += 1;
    lastRejectedId = ingestionId;
    if (rejectError != null) {
      throw rejectError!;
    }
    onReject?.call(ingestionId);
    return rejectResult ??
        fakeReviewActionResult(
          ingestionId: ingestionId,
          decision: 'IGNORED',
          decisionReason: 'MANUALLY_REJECTED',
        );
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

PagedResult<EmailIngestionReviewSummary> emptyReviewPage() {
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

EmailIngestionReviewSummary fakeReviewSummary({
  int ingestionId = 51,
  String subject = 'Compra Cobasi',
  String sender = 'noreply@cobasi.com.br',
  String sourceAccount = 'financeiro@gmail.com',
  String merchantOrPayee = 'Cobasi',
  double totalAmount = 289.7,
  String summary = 'Compra pet shop',
  String classification = 'MANUAL_PURCHASE',
  double confidence = 0.72,
  String decisionReason = 'REVIEW_REQUESTED',
}) {
  return EmailIngestionReviewSummary(
    ingestionId: ingestionId,
    sourceAccount: sourceAccount,
    sender: sender,
    subject: subject,
    receivedAt: DateTime.parse('2026-03-19T10:15:30Z'),
    merchantOrPayee: merchantOrPayee,
    totalAmount: totalAmount,
    currency: 'BRL',
    summary: summary,
    classification: classification,
    confidence: confidence,
    decisionReason: decisionReason,
  );
}

EmailIngestionReviewItem fakeReviewItem({
  String description = 'Racao',
  double amount = 289.7,
  double? quantity,
}) {
  return EmailIngestionReviewItem(
    description: description,
    amount: amount,
    quantity: quantity,
  );
}

EmailIngestionReviewDetail fakeReviewDetail({
  int ingestionId = 51,
  String subject = 'Compra Cobasi',
  String sender = 'noreply@cobasi.com.br',
  String sourceAccount = 'financeiro@gmail.com',
  String merchantOrPayee = 'Cobasi',
  double totalAmount = 289.7,
  String summary = 'Compra pet shop',
  String classification = 'MANUAL_PURCHASE',
  double confidence = 0.72,
  String decisionReason = 'REVIEW_REQUESTED',
  List<EmailIngestionReviewItem>? items,
}) {
  return EmailIngestionReviewDetail(
    ingestionId: ingestionId,
    sourceAccount: sourceAccount,
    externalMessageId: 'msg-1',
    sender: sender,
    subject: subject,
    receivedAt: DateTime.parse('2026-03-19T10:15:30Z'),
    merchantOrPayee: merchantOrPayee,
    suggestedCategoryName: 'Pets',
    suggestedSubcategoryName: 'Pet shop',
    totalAmount: totalAmount,
    dueDate: DateTime.utc(2026, 3, 25),
    occurredOn: DateTime.utc(2026, 3, 19),
    currency: 'BRL',
    summary: summary,
    classification: classification,
    confidence: confidence,
    rawReference: 'gmail:msg-1',
    desiredDecision: 'REVIEW',
    finalDecision: 'REVIEW_REQUIRED',
    decisionReason: decisionReason,
    importedExpenseId: null,
    createdAt: DateTime.parse('2026-03-19T10:15:30Z'),
    updatedAt: DateTime.parse('2026-03-19T10:16:30Z'),
    items: items ?? [fakeReviewItem()],
  );
}

EmailIngestionReviewActionResult fakeReviewActionResult({
  int ingestionId = 51,
  String decision = 'AUTO_IMPORTED',
  String decisionReason = 'MANUALLY_IMPORTED',
  int? expenseId = 88,
}) {
  return EmailIngestionReviewActionResult(
    ingestionId: ingestionId,
    decision: decision,
    decisionReason: decisionReason,
    expenseId: expenseId,
  );
}
