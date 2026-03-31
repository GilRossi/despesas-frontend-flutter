import 'dart:async';

import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
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
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_summary.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_ai_usage.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_reply.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_repository.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_reply.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/create_fixed_bill_input.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_frequency.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_record.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bill_reference.dart';
import 'package:despesas_frontend/features/fixed_bills/domain/fixed_bills_repository.dart';
import 'package:despesas_frontend/features/household_members/domain/create_household_member_input.dart';
import 'package:despesas_frontend/features/household_members/domain/household_member.dart';
import 'package:despesas_frontend/features/household_members/domain/household_members_repository.dart';
import 'package:despesas_frontend/features/history_imports/domain/create_history_import_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_input.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_entry_record.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_result.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_imports_repository.dart';
import 'package:despesas_frontend/features/incomes/domain/create_income_input.dart';
import 'package:despesas_frontend/features/incomes/domain/income_record.dart';
import 'package:despesas_frontend/features/incomes/domain/income_reference.dart';
import 'package:despesas_frontend/features/incomes/domain/incomes_repository.dart';
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
import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.refreshResult,
    this.changePasswordResult,
    this.forgotPasswordResult,
    this.resetPasswordResult,
    this.currentUserResult,
    this.completeOnboardingResult,
    this.loginError,
    this.refreshError,
    this.changePasswordError,
    this.forgotPasswordError,
    this.resetPasswordError,
    this.fetchCurrentUserError,
    this.completeOnboardingError,
  });

  MobileSession? loginResult;
  MobileSession? refreshResult;
  ChangePasswordResult? changePasswordResult;
  ForgotPasswordResult? forgotPasswordResult;
  ResetPasswordResult? resetPasswordResult;
  AuthUser? currentUserResult;
  AuthOnboarding? completeOnboardingResult;
  Exception? loginError;
  Exception? refreshError;
  Exception? changePasswordError;
  Exception? forgotPasswordError;
  Exception? resetPasswordError;
  Exception? fetchCurrentUserError;
  Exception? completeOnboardingError;
  int refreshCalls = 0;
  int changePasswordCalls = 0;
  int forgotPasswordCalls = 0;
  int resetPasswordCalls = 0;
  int fetchCurrentUserCalls = 0;
  int completeOnboardingCalls = 0;
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
  Future<AuthUser> fetchCurrentUser() async {
    fetchCurrentUserCalls += 1;
    if (fetchCurrentUserError != null) {
      throw fetchCurrentUserError!;
    }
    return currentUserResult ?? fakeSession().user;
  }

  @override
  Future<AuthOnboarding> completeOnboarding() async {
    completeOnboardingCalls += 1;
    if (completeOnboardingError != null) {
      throw completeOnboardingError!;
    }
    return completeOnboardingResult ??
        AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        );
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
    this.createResult,
    this.createError,
    this.updateError,
    this.deleteError,
    this.registerPaymentError,
    this.deletePaymentError,
    this.onCreate,
    this.onCreateAsync,
    this.onUpdate,
    this.onDelete,
    this.onRegisterPayment,
    this.onRegisterPaymentAsync,
    this.onDeletePayment,
    this.listDelay,
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
  Exception? deletePaymentError;
  ExpenseSummary? createResult;
  void Function(SaveExpenseInput input)? onCreate;
  Future<void> Function(SaveExpenseInput input)? onCreateAsync;
  void Function(int expenseId, SaveExpenseInput input)? onUpdate;
  void Function(int expenseId)? onDelete;
  void Function(CreateExpensePaymentInput input)? onRegisterPayment;
  Future<void> Function(CreateExpensePaymentInput input)?
  onRegisterPaymentAsync;
  void Function(int paymentId)? onDeletePayment;
  int listCalls = 0;
  int detailCalls = 0;
  int catalogCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int registerPaymentCalls = 0;
  int deletePaymentCalls = 0;
  SaveExpenseInput? lastCreatedInput;
  SaveExpenseInput? lastUpdatedInput;
  int? lastUpdatedExpenseId;
  int? lastDeletedExpenseId;
  int? lastDeletedPaymentId;
  CreateExpensePaymentInput? lastPaymentInput;
  Duration? listDelay;
  ExpenseSummary? _pendingCreatedExpense;

  @override
  ExpenseSummary? get pendingCreatedExpense => _pendingCreatedExpense;

  @override
  void clearPendingCreatedExpense() {
    _pendingCreatedExpense = null;
  }

  @override
  Future<PagedResult<ExpenseSummary>> listExpenses({
    int page = 0,
    int size = 20,
  }) async {
    listCalls += 1;
    if (listDelay != null) {
      await Future<void>.delayed(listDelay!);
    }
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
  Future<ExpenseSummary> createExpense(SaveExpenseInput input) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }
    onCreate?.call(input);
    if (onCreateAsync != null) {
      await onCreateAsync!(input);
    }
    final createdExpense =
        createResult ??
        fakeExpense(
          description: input.description.trim(),
          amount: input.amount,
          dueDate: input.dueDate,
        );
    _pendingCreatedExpense = createdExpense;
    return createdExpense;
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
    if (onRegisterPaymentAsync != null) {
      await onRegisterPaymentAsync!(input);
    }
  }

  @override
  Future<void> deleteExpensePayment(int paymentId) async {
    deletePaymentCalls += 1;
    lastDeletedPaymentId = paymentId;
    if (deletePaymentError != null) {
      throw deletePaymentError!;
    }
    onDeletePayment?.call(paymentId);
  }
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.summary, this.error, this.onFetch});

  DashboardSummary? summary;
  Exception? error;
  Future<DashboardSummary> Function()? onFetch;
  int calls = 0;

  @override
  Future<DashboardSummary> fetchDashboard() async {
    calls += 1;
    if (onFetch != null) {
      return onFetch!.call();
    }
    if (error != null) throw error!;
    return summary ?? fakeDashboardSummary();
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
  FakeFinancialAssistantRepository({
    this.reply,
    this.error,
    this.starterReply,
    this.starterError,
    this.onAsk,
    this.onSelectStarterIntent,
  });

  FinancialAssistantReply? reply;
  Exception? error;
  FinancialAssistantStarterReply? starterReply;
  Exception? starterError;
  FutureOr<void> Function(String question, DateTime referenceMonth)? onAsk;
  FutureOr<void> Function(FinancialAssistantStarterIntent intent)?
  onSelectStarterIntent;
  int askCalls = 0;
  int starterIntentCalls = 0;
  String? lastQuestion;
  DateTime? lastReferenceMonth;
  FinancialAssistantStarterIntent? lastStarterIntent;

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

  @override
  Future<FinancialAssistantStarterReply> fetchStarterIntent({
    required FinancialAssistantStarterIntent intent,
  }) async {
    starterIntentCalls += 1;
    lastStarterIntent = intent;
    if (starterError != null) {
      throw starterError!;
    }
    await onSelectStarterIntent?.call(intent);
    return starterReply ?? fakeStarterReply(intent: intent);
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

class FakeIncomesRepository implements IncomesRepository {
  FakeIncomesRepository({this.createResult, this.createError, this.onCreate});

  IncomeRecord? createResult;
  Exception? createError;
  FutureOr<void> Function(CreateIncomeInput input)? onCreate;
  int createCalls = 0;
  CreateIncomeInput? lastCreatedInput;

  @override
  Future<IncomeRecord> createIncome(CreateIncomeInput input) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }

    await onCreate?.call(input);
    return createResult ??
        fakeIncomeRecord(
          description: input.description.trim(),
          amount: input.amount,
          receivedOn: input.receivedOn,
          spaceReference: input.spaceReferenceId == null
              ? null
              : fakeIncomeReference(id: input.spaceReferenceId!),
        );
  }
}

class FakeFixedBillsRepository implements FixedBillsRepository {
  FakeFixedBillsRepository({
    this.createResult,
    this.createError,
    this.onCreate,
  });

  FixedBillRecord? createResult;
  Exception? createError;
  FutureOr<void> Function(CreateFixedBillInput input)? onCreate;
  int createCalls = 0;
  CreateFixedBillInput? lastCreatedInput;

  @override
  Future<FixedBillRecord> createFixedBill(CreateFixedBillInput input) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }

    await onCreate?.call(input);
    return createResult ??
        fakeFixedBillRecord(
          description: input.description.trim(),
          amount: input.amount,
          firstDueDate: input.firstDueDate,
          frequency: input.frequency,
          category: fakeFixedBillReference(id: input.categoryId, name: 'Casa'),
          subcategory: fakeFixedBillReference(
            id: input.subcategoryId,
            name: 'Internet',
          ),
          spaceReference: input.spaceReferenceId == null
              ? null
              : fakeFixedBillReference(id: input.spaceReferenceId!),
        );
  }
}

class FakeHistoryImportsRepository implements HistoryImportsRepository {
  FakeHistoryImportsRepository({
    this.importResult,
    this.importError,
    this.onImport,
  });

  HistoryImportResult? importResult;
  Exception? importError;
  FutureOr<void> Function(CreateHistoryImportInput input)? onImport;
  int importCalls = 0;
  CreateHistoryImportInput? lastImportInput;

  @override
  Future<HistoryImportResult> importHistory(
    CreateHistoryImportInput input,
  ) async {
    importCalls += 1;
    lastImportInput = input;
    if (importError != null) {
      throw importError!;
    }

    await onImport?.call(input);
    return importResult ??
        fakeHistoryImportResult(
          importedCount: input.entries.length,
          entries: [
            for (final entry in input.entries)
              fakeHistoryImportEntryRecord(
                description: entry.description.trim(),
                amount: entry.amount,
                date: entry.date,
              ),
          ],
        );
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

class FakeSpaceReferencesRepository implements SpaceReferencesRepository {
  FakeSpaceReferencesRepository({
    this.references,
    this.listError,
    this.createError,
    this.createResult,
    this.onCreate,
  });

  List<SpaceReferenceItem>? references;
  Exception? listError;
  Exception? createError;
  SpaceReferenceCreateResult? createResult;
  FutureOr<void> Function(CreateSpaceReferenceInput input)? onCreate;
  int listCalls = 0;
  int createCalls = 0;
  SpaceReferenceTypeGroup? lastTypeGroup;
  SpaceReferenceType? lastType;
  String? lastQuery;
  CreateSpaceReferenceInput? lastCreatedInput;

  @override
  Future<List<SpaceReferenceItem>> listReferences({
    SpaceReferenceTypeGroup? typeGroup,
    SpaceReferenceType? type,
    String? query,
  }) async {
    listCalls += 1;
    lastTypeGroup = typeGroup;
    lastType = type;
    lastQuery = query;
    if (listError != null) {
      throw listError!;
    }

    final normalizedQuery = (query ?? '').trim().toLowerCase();
    return (references ?? [fakeSpaceReferenceItem()]).where((reference) {
      if (typeGroup != null && reference.typeGroup != typeGroup) {
        return false;
      }
      if (type != null && reference.type != type) {
        return false;
      }
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return reference.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<SpaceReferenceCreateResult> createReference(
    CreateSpaceReferenceInput input,
  ) async {
    createCalls += 1;
    lastCreatedInput = input;
    if (createError != null) {
      throw createError!;
    }

    await onCreate?.call(input);
    final result =
        createResult ??
        SpaceReferenceCreateResult(
          result: SpaceReferenceCreateResultType.created,
          reference: fakeSpaceReferenceItem(
            id: 99,
            type: input.type,
            name: input.name.trim(),
          ),
        );

    if (result.reference != null) {
      references = [...?references, result.reference!];
    }

    return result;
  }
}

MobileSession fakeSession({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  String name = 'Gil Rossi',
  String email = 'gil@example.com',
  String role = 'OWNER',
  int? householdId = 10,
  AuthOnboarding onboarding = const AuthOnboarding(completed: false),
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
      onboarding: onboarding,
    ),
  );
}

DashboardSummary fakeDashboardSummary({
  String role = 'OWNER',
  DashboardAssistantCard? assistantCard,
  DashboardMonthOverview? monthOverview,
  DashboardCategorySpending? categorySpending,
  DashboardHouseholdSummary? householdSummary,
  DashboardQuickActions? quickActions,
  DashboardActionNeeded? actionNeeded,
  DashboardRecentActivity? recentActivity,
}) {
  final isOwner = role == 'OWNER';
  return DashboardSummary(
    role: role,
    summaryMain: const DashboardSummaryMain(
      referenceMonth: '2026-03',
      totalOpenAmount: 320,
      totalOverdueAmount: 120,
      paidThisMonthAmount: 540,
      openCount: 2,
      overdueCount: 1,
    ),
    actionNeeded:
        actionNeeded ??
        DashboardActionNeeded(
          overdueCount: 1,
          overdueAmount: 120,
          openCount: 2,
          openAmount: 320,
          items: [
            DashboardActionItem(
              expenseId: 10,
              description: 'Internet',
              dueDate: DateTime.utc(2026, 3, 10),
              status: 'VENCIDA',
              amount: 120,
              route: '/expenses/10/pay',
            ),
            DashboardActionItem(
              expenseId: 11,
              description: 'Mercado',
              dueDate: DateTime.utc(2026, 3, 20),
              status: 'PREVISTA',
              amount: 200,
              route: '/expenses/11/pay',
            ),
          ],
        ),
    recentActivity:
        recentActivity ??
        DashboardRecentActivity(
          items: [
            DashboardRecentActivityItem(
              type: 'PAYMENT_RECORDED',
              title: 'Pagamento registrado',
              subtitle: 'Aluguel',
              amount: 500,
              occurredAt: DateTime.utc(2026, 3, 21, 12),
              route: '/expenses',
            ),
            DashboardRecentActivityItem(
              type: 'EXPENSE_CREATED',
              title: 'Despesa adicionada',
              subtitle: 'Mercado',
              amount: 200,
              occurredAt: DateTime.utc(2026, 3, 21, 9),
              route: '/expenses',
            ),
          ],
        ),
    assistantCard:
        assistantCard ??
        const DashboardAssistantCard(
          title: 'Assistente financeiro',
          message:
              'Revise a categoria que mais pesa e siga para a próxima ação.',
          primaryActionKey: 'OPEN_ASSISTANT',
          route: '/assistant',
        ),
    monthOverview: isOwner
        ? monthOverview ??
              const DashboardMonthOverview(
                referenceMonth: '2026-03',
                totalAmount: 860,
                paidAmount: 540,
                remainingAmount: 320,
                monthComparison: ReportMonthComparison(
                  currentMonth: '2026-03',
                  currentTotal: 860,
                  previousMonth: '2026-02',
                  previousTotal: 700,
                  deltaAmount: 160,
                  deltaPercentage: 22.86,
                ),
                highestSpendingCategory: DashboardHighestSpendingCategory(
                  categoryId: 1,
                  categoryName: 'Moradia',
                  totalAmount: 540,
                  sharePercentage: 62.79,
                ),
              )
        : null,
    categorySpending: isOwner
        ? categorySpending ??
              const DashboardCategorySpending(
                items: [
                  ReportCategoryTotal(
                    categoryId: 1,
                    categoryName: 'Moradia',
                    totalAmount: 540,
                    expensesCount: 2,
                    sharePercentage: 62.79,
                  ),
                  ReportCategoryTotal(
                    categoryId: 2,
                    categoryName: 'Alimentação',
                    totalAmount: 320,
                    expensesCount: 2,
                    sharePercentage: 37.21,
                  ),
                ],
              )
        : null,
    householdSummary: isOwner
        ? householdSummary ??
              const DashboardHouseholdSummary(
                membersCount: 3,
                ownersCount: 1,
                membersOnlyCount: 2,
                spaceReferencesCount: 4,
                referencesByGroup: [
                  DashboardReferenceGroupSummary(
                    group: SpaceReferenceTypeGroup.residencial,
                    count: 2,
                  ),
                  DashboardReferenceGroupSummary(
                    group: SpaceReferenceTypeGroup.comercialTrabalho,
                    count: 2,
                  ),
                ],
              )
        : null,
    quickActions: isOwner
        ? null
        : quickActions ??
              const DashboardQuickActions(
                items: [
                  DashboardQuickActionItem(
                    key: 'OPEN_EXPENSES',
                    label: 'Ver despesas',
                    route: '/expenses',
                  ),
                  DashboardQuickActionItem(
                    key: 'OPEN_ASSISTANT',
                    label: 'Abrir assistente',
                    route: '/assistant',
                  ),
                  DashboardQuickActionItem(
                    key: 'OPEN_REPORTS',
                    label: 'Ver relatorios',
                    route: '/reports',
                  ),
                ],
              ),
  );
}

FinancialAssistantStarterReply fakeStarterReply({
  FinancialAssistantStarterIntent intent =
      FinancialAssistantStarterIntent.fixedBills,
  String kind = 'STARTER',
  String title = 'Vamos organizar esse primeiro passo',
  String message = 'Tudo certo. Esta e a proxima orientacao preparada.',
  String primaryActionKey = 'OPEN_FLOW',
}) {
  return FinancialAssistantStarterReply(
    intent: intent,
    kind: kind,
    title: title,
    message: message,
    primaryActionKey: primaryActionKey,
  );
}

SpaceReferenceItem fakeSpaceReferenceItem({
  int id = 1,
  SpaceReferenceType type = SpaceReferenceType.cliente,
  String name = 'Projeto Acme',
}) {
  return SpaceReferenceItem(
    id: id,
    type: type,
    typeGroup: type.group,
    name: name,
  );
}

SpaceReferenceCreateResult fakeSpaceReferenceCreateResult({
  SpaceReferenceCreateResultType result =
      SpaceReferenceCreateResultType.created,
  SpaceReferenceItem? reference,
  SpaceReferenceItem? suggestedReference,
  String? message,
}) {
  return SpaceReferenceCreateResult(
    result: result,
    reference: reference,
    suggestedReference: suggestedReference,
    message: message,
  );
}

IncomeReference fakeIncomeReference({
  int id = 1,
  String name = 'Projeto Acme',
}) {
  return IncomeReference(id: id, name: name);
}

IncomeRecord fakeIncomeRecord({
  int id = 1,
  String description = 'Freelance de marco',
  double amount = 1800,
  DateTime? receivedOn,
  IncomeReference? spaceReference,
  DateTime? createdAt,
}) {
  return IncomeRecord(
    id: id,
    description: description,
    amount: amount,
    receivedOn: receivedOn ?? DateTime.utc(2026, 3, 28),
    spaceReference: spaceReference,
    createdAt: createdAt ?? DateTime.utc(2026, 3, 28, 12),
  );
}

FixedBillReference fakeFixedBillReference({
  int id = 1,
  String name = 'Projeto Acme',
}) {
  return FixedBillReference(id: id, name: name);
}

FixedBillRecord fakeFixedBillRecord({
  int id = 1,
  String description = 'Internet fibra',
  double amount = 129.9,
  DateTime? firstDueDate,
  FixedBillFrequency frequency = FixedBillFrequency.monthly,
  FixedBillReference? category,
  FixedBillReference? subcategory,
  FixedBillReference? spaceReference,
  bool active = true,
  DateTime? createdAt,
}) {
  return FixedBillRecord(
    id: id,
    description: description,
    amount: amount,
    firstDueDate: firstDueDate ?? DateTime.utc(2026, 4, 5),
    frequency: frequency,
    category: category ?? fakeFixedBillReference(id: 1, name: 'Casa'),
    subcategory:
        subcategory ?? fakeFixedBillReference(id: 11, name: 'Internet'),
    spaceReference: spaceReference,
    active: active,
    createdAt: createdAt ?? DateTime.utc(2026, 3, 28, 12),
  );
}

HistoryImportEntryRecord fakeHistoryImportEntryRecord({
  int expenseId = 1,
  int paymentId = 101,
  String description = 'Mercado de fevereiro',
  double amount = 189.9,
  DateTime? date,
  String status = 'PAGA',
}) {
  return HistoryImportEntryRecord(
    expenseId: expenseId,
    paymentId: paymentId,
    description: description,
    amount: amount,
    date: date ?? DateTime.utc(2026, 2, 14),
    status: status,
  );
}

HistoryImportResult fakeHistoryImportResult({
  int importedCount = 1,
  List<HistoryImportEntryRecord>? entries,
}) {
  return HistoryImportResult(
    importedCount: importedCount,
    entries: entries ?? [fakeHistoryImportEntryRecord()],
  );
}

HistoryImportEntryInput fakeHistoryImportEntryInput({
  String description = 'Mercado de fevereiro',
  double amount = 189.9,
  DateTime? date,
  int categoryId = 1,
  int subcategoryId = 11,
  String? notes,
}) {
  return HistoryImportEntryInput(
    description: description,
    amount: amount,
    date: date ?? DateTime.utc(2026, 2, 14),
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    notes: notes,
  );
}

CreateHistoryImportInput fakeCreateHistoryImportInput({
  List<HistoryImportEntryInput>? entries,
  HistoryImportPaymentMethod paymentMethod = HistoryImportPaymentMethod.pix,
}) {
  return CreateHistoryImportInput(
    entries: entries ?? [fakeHistoryImportEntryInput()],
    paymentMethod: paymentMethod,
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
  DateTime? dueDate,
  DateTime? occurredOn,
  DateTime? createdAt,
  String category = 'Casa',
  String subcategory = 'Internet',
  String status = 'ABERTA',
  ExpenseReference? reference,
  double paidAmount = 0,
  double? remainingAmount,
}) {
  return ExpenseSummary(
    id: id,
    description: description,
    amount: amount,
    dueDate: dueDate ?? DateTime.utc(2026, 3, 25),
    occurredOn: occurredOn ?? DateTime.utc(2026, 3, 25),
    category: ExpenseReference(id: 1, name: category),
    subcategory: ExpenseReference(id: 2, name: subcategory),
    reference: reference,
    status: status,
    paidAmount: paidAmount,
    remainingAmount: remainingAmount ?? amount,
    overdue: false,
    createdAt: createdAt ?? DateTime.utc(2026, 3, 28, 12),
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
  DateTime? dueDate,
  DateTime? occurredOn,
  ExpenseReference? reference,
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
    dueDate: dueDate ?? DateTime.utc(2026, 3, 25),
    occurredOn: occurredOn ?? DateTime.utc(2026, 3, 25),
    category: ExpenseReference(id: 1, name: category),
    subcategory: ExpenseReference(id: 2, name: subcategory),
    reference: reference,
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
