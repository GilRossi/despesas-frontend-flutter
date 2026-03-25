import 'dart:async';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_repository.dart';
import 'package:despesas_frontend/features/auth/domain/auth_user.dart';
import 'package:despesas_frontend/features/auth/domain/change_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/forgot_password_result.dart';
import 'package:despesas_frontend/features/auth/domain/mobile_session.dart';
import 'package:despesas_frontend/features/auth/domain/reset_password_result.dart';
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
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_ai_usage.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/admin_password_reset_result.dart';
import 'package:despesas_frontend/features/platform_admin/domain/create_household_owner_input.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_household.dart';
import 'package:despesas_frontend/features/platform_admin/domain/platform_admin_repository.dart';
import 'package:despesas_frontend/features/reports/domain/report_category_total.dart';
import 'package:despesas_frontend/features/reports/domain/report_increase_alert.dart';
import 'package:despesas_frontend/features/reports/domain/report_insights.dart';
import 'package:despesas_frontend/features/reports/domain/report_month_comparison.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_recurring_expense.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/report_top_expense.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_item.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.refreshResult,
    this.changePasswordResult,
    this.forgotPasswordResult,
    this.resetPasswordResult,
    this.loginError,
    this.refreshError,
    this.changePasswordError,
    this.forgotPasswordError,
    this.resetPasswordError,
  });

  MobileSession? loginResult;
  MobileSession? refreshResult;
  ChangePasswordResult? changePasswordResult;
  ForgotPasswordResult? forgotPasswordResult;
  ResetPasswordResult? resetPasswordResult;
  Exception? loginError;
  Exception? refreshError;
  Exception? changePasswordError;
  Exception? forgotPasswordError;
  Exception? resetPasswordError;
  int refreshCalls = 0;
  int changePasswordCalls = 0;
  int forgotPasswordCalls = 0;
  int resetPasswordCalls = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastNewPasswordConfirmation;
  String? lastForgotEmail;
  String? lastResetToken;

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

  @override
  Future<ChangePasswordResult> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    changePasswordCalls += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastNewPasswordConfirmation = newPasswordConfirmation;
    if (changePasswordError != null) {
      throw changePasswordError!;
    }
    return changePasswordResult ??
        const ChangePasswordResult(
          revokedRefreshTokens: 1,
          reauthenticationRequired: true,
        );
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    forgotPasswordCalls += 1;
    lastForgotEmail = email;
    if (forgotPasswordError != null) {
      throw forgotPasswordError!;
    }
    return forgotPasswordResult ??
        ForgotPasswordResult(maskedEmail: 'g***@example.com');
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    resetPasswordCalls += 1;
    lastResetToken = token;
    lastNewPassword = newPassword;
    lastNewPasswordConfirmation = newPasswordConfirmation;
    if (resetPasswordError != null) {
      throw resetPasswordError!;
    }
    return resetPasswordResult ??
        const ResetPasswordResult(revokedRefreshTokens: 1, success: true);
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

class ThrowingSessionStore implements SessionStore {
  ThrowingSessionStore({this.readError, this.writeError, this.clearError});

  Exception? readError;
  Exception? writeError;
  Exception? clearError;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<void> clear() async {
    if (clearError != null) {
      throw clearError!;
    }
    refreshToken = null;
    cleared = true;
  }

  @override
  Future<String?> readRefreshToken() async {
    if (readError != null) {
      throw readError!;
    }
    return refreshToken;
  }

  @override
  Future<void> writeRefreshToken(String refreshToken) async {
    if (writeError != null) {
      throw writeError!;
    }
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

class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository({this.snapshot, this.error, this.onLoad});

  ReportsSnapshot? snapshot;
  Exception? error;
  void Function(DateTime referenceMonth, bool comparePrevious)? onLoad;
  int loadCalls = 0;
  DateTime? lastReferenceMonth;
  bool? lastComparePrevious;

  @override
  Future<ReportsSnapshot> loadMonthlyReport({
    required DateTime referenceMonth,
    required bool comparePrevious,
  }) async {
    loadCalls += 1;
    lastReferenceMonth = referenceMonth;
    lastComparePrevious = comparePrevious;
    if (error != null) {
      throw error!;
    }
    onLoad?.call(referenceMonth, comparePrevious);
    return snapshot ??
        fakeReportsSnapshot(
          referenceMonth: referenceMonth,
          comparePrevious: comparePrevious,
        );
  }
}

class FakeFinancialAssistantRepository implements FinancialAssistantRepository {
  FakeFinancialAssistantRepository({this.reply, this.error, this.onAsk});

  FinancialAssistantReply? reply;
  Exception? error;
  FutureOr<void> Function(String question, DateTime referenceMonth)? onAsk;
  int askCalls = 0;
  String? lastQuestion;
  DateTime? lastReferenceMonth;

  @override
  Future<FinancialAssistantReply> askQuestion({
    required String question,
    required DateTime referenceMonth,
  }) async {
    askCalls += 1;
    lastQuestion = question;
    lastReferenceMonth = referenceMonth;
    if (error != null) {
      throw error!;
    }
    await onAsk?.call(question, referenceMonth);
    return reply ??
        fakeFinancialAssistantReply(
          question: question,
          mode: 'FALLBACK',
          intent: 'PERIOD_SUMMARY',
        );
  }
}

class FakeHouseholdMembersRepository implements HouseholdMembersRepository {
  FakeHouseholdMembersRepository({
    this.members,
    this.listError,
    this.createError,
    this.onCreate,
  });

  List<HouseholdMember>? members;
  Exception? listError;
  Exception? createError;
  void Function(CreateHouseholdMemberInput input)? onCreate;
  int listCalls = 0;
  int createCalls = 0;
  CreateHouseholdMemberInput? lastCreatedInput;

  @override
  Future<List<HouseholdMember>> listMembers() async {
    listCalls += 1;
    if (listError != null) {
      throw listError!;
    }
    return members ?? [fakeHouseholdMember()];
  }

  @override
  Future<HouseholdMember> createMember(CreateHouseholdMemberInput input) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }
    onCreate?.call(input);
    final created = fakeHouseholdMember(
      id: 99,
      userId: 77,
      name: input.name,
      email: input.email,
      role: 'MEMBER',
    );
    final current = List<HouseholdMember>.from(
      members ?? [fakeHouseholdMember()],
    );
    current.add(created);
    members = current;
    return created;
  }
}

class FakePlatformAdminRepository implements PlatformAdminRepository {
  FakePlatformAdminRepository({
    this.result,
    this.error,
    this.onCreate,
    this.resetResult,
    this.resetError,
    this.onReset,
  });

  PlatformAdminHousehold? result;
  Exception? error;
  void Function(CreateHouseholdOwnerInput input)? onCreate;
  AdminPasswordResetResult? resetResult;
  Exception? resetError;
  void Function(AdminPasswordResetInput input)? onReset;
  int createCalls = 0;
  int resetCalls = 0;
  CreateHouseholdOwnerInput? lastInput;
  AdminPasswordResetInput? lastResetInput;

  @override
  Future<PlatformAdminHousehold> createHouseholdWithOwner(
    CreateHouseholdOwnerInput input,
  ) async {
    createCalls += 1;
    lastInput = input;
    if (error != null) {
      throw error!;
    }
    onCreate?.call(input);
    return result ??
        PlatformAdminHousehold(
          householdId: 99,
          householdName: input.householdName,
          ownerUserId: 77,
          ownerEmail: input.ownerEmail,
          ownerRole: 'OWNER',
        );
  }

  @override
  Future<AdminPasswordResetResult> resetUserPassword(
    AdminPasswordResetInput input,
  ) async {
    resetCalls += 1;
    lastResetInput = input;
    if (resetError != null) {
      throw resetError!;
    }
    onReset?.call(input);
    return resetResult ??
        const AdminPasswordResetResult(
          targetEmailMasked: 'u***@local.invalid',
          revokedRefreshTokens: 2,
        );
  }
}

MobileSession fakeSession({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  String name = 'Gil Rossi',
  String email = 'gil@example.com',
  String role = 'OWNER',
  int? householdId = 10,
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
      householdId: householdId,
      email: email,
      name: name,
      role: role,
    ),
  );
}

HouseholdMember fakeHouseholdMember({
  int id = 1,
  int userId = 1,
  int householdId = 10,
  String name = 'Gil Rossi',
  String email = 'gil@example.com',
  String role = 'OWNER',
}) {
  return HouseholdMember(
    id: id,
    userId: userId,
    householdId: householdId,
    name: name,
    email: email,
    role: role,
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

ReportsSnapshot fakeReportsSnapshot({
  DateTime? referenceMonth,
  bool comparePrevious = true,
  ReportSummary? summary,
  ReportInsights? insights,
  List<ReportRecommendation>? recommendations,
}) {
  final month = referenceMonth ?? DateTime(2026, 3);

  return ReportsSnapshot(
    referenceMonth: DateTime(month.year, month.month),
    comparePrevious: comparePrevious,
    summary: summary ?? fakeReportSummary(),
    insights: insights ?? fakeReportInsights(),
    recommendations: recommendations ?? [fakeReportRecommendation()],
  );
}

ReportSummary fakeReportSummary({
  DateTime? from,
  DateTime? to,
  int totalExpenses = 3,
  double totalAmount = 420,
  double paidAmount = 180,
  double remainingAmount = 240,
  String highestSpendingCategory = 'Moradia',
  List<ReportCategoryTotal>? categoryTotals,
  List<ReportTopExpense>? topExpenses,
}) {
  return ReportSummary(
    from: from ?? DateTime.utc(2026, 3, 1),
    to: to ?? DateTime.utc(2026, 3, 31),
    totalExpenses: totalExpenses,
    totalAmount: totalAmount,
    paidAmount: paidAmount,
    remainingAmount: remainingAmount,
    highestSpendingCategory: highestSpendingCategory,
    categoryTotals: categoryTotals ?? [fakeReportCategoryTotal()],
    topExpenses: topExpenses ?? [fakeReportTopExpense()],
  );
}

ReportCategoryTotal fakeReportCategoryTotal({
  int categoryId = 10,
  String categoryName = 'Moradia',
  double totalAmount = 220,
  int expensesCount = 2,
  double sharePercentage = 52.38,
}) {
  return ReportCategoryTotal(
    categoryId: categoryId,
    categoryName: categoryName,
    totalAmount: totalAmount,
    expensesCount: expensesCount,
    sharePercentage: sharePercentage,
  );
}

ReportTopExpense fakeReportTopExpense({
  int expenseId = 7,
  String description = 'Aluguel',
  double amount = 220,
}) {
  return ReportTopExpense(
    expenseId: expenseId,
    description: description,
    amount: amount,
    dueDate: DateTime.utc(2026, 3, 10),
    categoryName: 'Moradia',
    subcategoryName: 'Aluguel',
    context: 'CASA',
  );
}

ReportInsights fakeReportInsights({
  ReportMonthComparison? monthComparison,
  List<ReportIncreaseAlert>? increaseAlerts,
  List<ReportRecurringExpense>? recurringExpenses,
}) {
  return ReportInsights(
    monthComparison: monthComparison ?? fakeReportMonthComparison(),
    increaseAlerts: increaseAlerts ?? [fakeReportIncreaseAlert()],
    recurringExpenses: recurringExpenses ?? [fakeReportRecurringExpense()],
  );
}

ReportMonthComparison fakeReportMonthComparison({
  String currentMonth = '2026-03',
  double currentTotal = 420,
  String previousMonth = '2026-02',
  double previousTotal = 300,
  double deltaAmount = 120,
  double deltaPercentage = 40,
}) {
  return ReportMonthComparison(
    currentMonth: currentMonth,
    currentTotal: currentTotal,
    previousMonth: previousMonth,
    previousTotal: previousTotal,
    deltaAmount: deltaAmount,
    deltaPercentage: deltaPercentage,
  );
}

ReportRecurringExpense fakeReportRecurringExpense({
  String description = 'Internet Fibra',
  double averageAmount = 129.9,
  int occurrences = 3,
}) {
  return ReportRecurringExpense(
    description: description,
    categoryName: 'Casa',
    subcategoryName: 'Internet',
    averageAmount: averageAmount,
    occurrences: occurrences,
    likelyFixedAmount: true,
    lastOccurrence: DateTime.utc(2026, 3, 25),
  );
}

ReportIncreaseAlert fakeReportIncreaseAlert({
  String categoryName = 'Moradia',
  double currentAmount = 220,
  double previousAmount = 150,
  double deltaAmount = 70,
  double deltaPercentage = 46.67,
}) {
  return ReportIncreaseAlert(
    categoryName: categoryName,
    currentAmount: currentAmount,
    previousAmount: previousAmount,
    deltaAmount: deltaAmount,
    deltaPercentage: deltaPercentage,
  );
}

ReportRecommendation fakeReportRecommendation({
  String title = 'Revisar gastos fixos',
  String rationale = 'Moradia segue liderando o mes.',
  String action = 'Negocie contratos ou reduza custos recorrentes.',
}) {
  return ReportRecommendation(
    title: title,
    rationale: rationale,
    action: action,
  );
}

FinancialAssistantReply fakeFinancialAssistantReply({
  String question = 'Como posso economizar este mes?',
  String mode = 'AI',
  String intent = 'SAVINGS_RECOMMENDATIONS',
  String answer =
      'Voce pode revisar os gastos de moradia e reduzir despesas recorrentes menos criticas.',
  ReportSummary? summary,
  ReportMonthComparison? monthComparison,
  ReportCategoryTotal? highestSpendingCategory,
  List<ReportTopExpense>? topExpenses,
  List<ReportIncreaseAlert>? increaseAlerts,
  List<ReportRecurringExpense>? recurringExpenses,
  List<ReportRecommendation>? recommendations,
  FinancialAssistantAiUsage? aiUsage,
}) {
  return FinancialAssistantReply(
    question: question,
    mode: mode,
    intent: intent,
    answer: answer,
    summary: summary ?? fakeReportSummary(),
    monthComparison: monthComparison ?? fakeReportMonthComparison(),
    highestSpendingCategory:
        highestSpendingCategory ?? fakeReportCategoryTotal(),
    topExpenses: topExpenses ?? [fakeReportTopExpense()],
    increaseAlerts: increaseAlerts ?? [fakeReportIncreaseAlert()],
    recurringExpenses: recurringExpenses ?? [fakeReportRecurringExpense()],
    recommendations: recommendations ?? [fakeReportRecommendation()],
    aiUsage:
        aiUsage ??
        const FinancialAssistantAiUsage(
          model: 'deepseek-chat',
          inputTokens: 80,
          outputTokens: 40,
          totalTokens: 120,
          cachedInputTokens: 0,
          reasoningTokens: 20,
          toolExecutionCount: 1,
          finishReason: 'STOP',
        ),
  );
}
