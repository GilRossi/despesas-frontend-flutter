import 'package:despesas_frontend/app/app_router.dart';
import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
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
import 'package:despesas_frontend/features/reports/domain/report_insights.dart';
import 'package:despesas_frontend/features/reports/domain/report_recommendation.dart';
import 'package:despesas_frontend/features/reports/domain/report_summary.dart';
import 'package:despesas_frontend/features/reports/domain/reports_repository.dart';
import 'package:despesas_frontend/features/reports/domain/reports_snapshot.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_action_result.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_detail.dart';
import 'package:despesas_frontend/features/review_operations/domain/email_ingestion_review_summary.dart';
import 'package:despesas_frontend/features/review_operations/domain/review_operations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('App router', () {
    late TestDeps deps;

    setUp(() {
      deps = TestDeps.standard();
    });

    testWidgets('unauthenticated users are redirected to login', (tester) async {
      await deps.sessionController.clearSession();

      final router = deps.buildRouter(
        login: const Text('login'),
      );

      await tester.pumpWidget(MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('authenticated users land on home shell', (tester) async {
      await deps.sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = deps.buildRouter(login: const Text('login'));

      await tester.pumpWidget(MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gestao principal de despesas'), findsOneWidget);
    });
  });
}

class TestDeps {
  TestDeps({
    required this.environment,
    required this.sessionController,
    required this.expensesRepository,
    required this.financialAssistantRepository,
    required this.householdMembersRepository,
    required this.platformAdminRepository,
    required this.reportsRepository,
    required this.reviewOperationsRepository,
  });

  final AppEnvironment environment;
  final SessionController sessionController;
  final ExpensesRepository expensesRepository;
  final FinancialAssistantRepository financialAssistantRepository;
  final HouseholdMembersRepository householdMembersRepository;
  final PlatformAdminRepository platformAdminRepository;
  final ReportsRepository reportsRepository;
  final ReviewOperationsRepository reviewOperationsRepository;

  factory TestDeps.standard() {
    final environment = AppEnvironment(
      name: 'test',
      apiBaseUrl: Uri.parse('http://localhost:8080'),
    );
    final authRepository = FakeAuthRepository();
    final sessionStore = FakeSessionStore();
    final sessionController = SessionController(
      authRepository: authRepository,
      sessionStore: sessionStore,
    );

    return TestDeps(
      environment: environment,
      sessionController: sessionController,
      expensesRepository: FakeExpensesRepository(),
      financialAssistantRepository: FakeFinancialAssistantRepository(),
      householdMembersRepository: FakeHouseholdMembersRepository(),
      platformAdminRepository: FakePlatformAdminRepository(),
      reportsRepository: FakeReportsRepository(),
      reviewOperationsRepository: FakeReviewOperationsRepository(),
    );
  }

  GoRouter buildRouter({required Widget login}) {
    return createAppRouter(
      sessionController: sessionController,
      expensesRepository: expensesRepository,
      financialAssistantRepository: financialAssistantRepository,
      householdMembersRepository: householdMembersRepository,
      platformAdminRepository: platformAdminRepository,
      reportsRepository: reportsRepository,
      reviewOperationsRepository: reviewOperationsRepository,
      splashScreen: const Placeholder(),
      loginScreenBuilder: () => login,
    );
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<MobileSession> login({required String email, required String password}) async {
    return MobileSession(
      tokenType: 'Bearer',
      accessToken: 'access',
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
      refreshToken: 'refresh',
      refreshTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AuthUser(
        userId: 1,
        householdId: 1,
        email: 'user@example.com',
        name: 'Test User',
        role: 'STANDARD_USER',
      ),
    );
  }

  @override
  Future<MobileSession> refresh({required String refreshToken}) {
    return login(email: 'user@example.com', password: 'password');
  }

  @override
  Future<ChangePasswordResult> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return const ChangePasswordResult(
      revokedRefreshTokens: 0,
      reauthenticationRequired: false,
    );
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    return ForgotPasswordResult(maskedEmail: 'm***@example.com');
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return const ResetPasswordResult(revokedRefreshTokens: 0, success: true);
  }
}

class FakeSessionStore implements SessionStore {
  String? _token;

  @override
  Future<void> clear() async => _token = null;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String refreshToken) async => _token = refreshToken;
}

class FakeExpensesRepository implements ExpensesRepository {
  @override
  Future<void> createExpense(SaveExpenseInput input) async {}

  @override
  Future<void> deleteExpense(int expenseId) async {}

  @override
  Future<ExpenseDetail> getExpenseDetail(int expenseId) async {
    throw UnimplementedError();
  }

  @override
  Future<PagedResult<ExpenseSummary>> listExpenses({int page = 0, int size = 20}) async {
    return PagedResult(
      items: const [],
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<List<CatalogOption>> listCatalogOptions() async => const [];

  @override
  Future<void> registerExpensePayment(CreateExpensePaymentInput input) async {}

  @override
  Future<void> updateExpense({required int expenseId, required SaveExpenseInput input}) async {}
}

class FakeFinancialAssistantRepository implements FinancialAssistantRepository {
  @override
  Future<FinancialAssistantReply> askQuestion({
    required String question,
    required DateTime referenceMonth,
  }) async {
    return FinancialAssistantReply(
      question: question,
      mode: 'AI',
      intent: 'INSIGHT',
      answer: 'ok',
      summary: buildReportSummary(),
      monthComparison: null,
      highestSpendingCategory: null,
      topExpenses: const [],
      increaseAlerts: const [],
      recurringExpenses: const [],
      recommendations: const [],
      aiUsage: const FinancialAssistantAiUsage(
        model: 'test-model',
        inputTokens: 0,
        outputTokens: 0,
        totalTokens: 0,
        cachedInputTokens: 0,
        reasoningTokens: 0,
        toolExecutionCount: 0,
        finishReason: 'stop',
      ),
    );
  }
}

class FakeHouseholdMembersRepository implements HouseholdMembersRepository {
  @override
  Future<HouseholdMember> createMember(CreateHouseholdMemberInput input) async {
    return HouseholdMember(
      id: 1,
      userId: 1,
      householdId: 1,
      email: input.email,
      name: 'Member',
      role: 'MEMBER',
    );
  }

  @override
  Future<List<HouseholdMember>> listMembers() async => const [];
}

class FakePlatformAdminRepository implements PlatformAdminRepository {
  @override
  Future<PlatformAdminHousehold> createHouseholdWithOwner(
    CreateHouseholdOwnerInput input,
  ) async {
    return PlatformAdminHousehold(
      householdId: 1,
      householdName: input.householdName,
      ownerUserId: 2,
      ownerEmail: input.ownerEmail,
      ownerRole: 'OWNER',
    );
  }

  @override
  Future<AdminPasswordResetResult> resetUserPassword(AdminPasswordResetInput input) async {
    return const AdminPasswordResetResult(
      targetEmailMasked: 'u***@example.com',
      revokedRefreshTokens: 0,
    );
  }
}

class FakeReportsRepository implements ReportsRepository {
  @override
  Future<ReportsSnapshot> loadMonthlyReport({
    required DateTime referenceMonth,
    required bool comparePrevious,
  }) async {
    return ReportsSnapshot(
      referenceMonth: referenceMonth,
      comparePrevious: comparePrevious,
      summary: buildReportSummary(),
      insights: const ReportInsights(
        monthComparison: null,
        increaseAlerts: [],
        recurringExpenses: [],
      ),
      recommendations: const <ReportRecommendation>[],
    );
  }
}

class FakeReviewOperationsRepository implements ReviewOperationsRepository {
  @override
  Future<EmailIngestionReviewActionResult> approveReview(int ingestionId) async {
    return EmailIngestionReviewActionResult(
      ingestionId: ingestionId,
      decision: 'APPROVED',
      decisionReason: 'ok',
      expenseId: null,
    );
  }

  @override
  Future<EmailIngestionReviewDetail> getReviewDetail(int ingestionId) async {
    return EmailIngestionReviewDetail(
      ingestionId: ingestionId,
      sourceAccount: 'noreply',
      externalMessageId: 'ext',
      sender: 'test',
      subject: 'subject',
      receivedAt: DateTime.now(),
      merchantOrPayee: '-',
      suggestedCategoryName: '-',
      suggestedSubcategoryName: '-',
      totalAmount: 0,
      dueDate: null,
      occurredOn: null,
      currency: 'BRL',
      summary: '-',
      classification: '-',
      confidence: 0,
      rawReference: '-',
      desiredDecision: '-',
      finalDecision: '-',
      decisionReason: '-',
      importedExpenseId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: const [],
    );
  }

  @override
  Future<PagedResult<EmailIngestionReviewSummary>> listPendingReviews({int page = 0, int size = 20}) async {
    return PagedResult(
      items: const [],
      page: 0,
      size: size,
      totalElements: 0,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  Future<EmailIngestionReviewActionResult> rejectReview(int ingestionId) async {
    return EmailIngestionReviewActionResult(
      ingestionId: ingestionId,
      decision: 'REJECTED',
      decisionReason: 'ok',
      expenseId: null,
    );
  }
}
ReportSummary buildReportSummary() => ReportSummary(
      from: DateTime(2024, 1, 1),
      to: DateTime(2024, 1, 31),
      totalExpenses: 0,
      totalAmount: 0,
      paidAmount: 0,
      remainingAmount: 0,
      highestSpendingCategory: '-',
      categoryTotals: const [],
      topExpenses: const [],
    );
