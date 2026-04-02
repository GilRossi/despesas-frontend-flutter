import 'dart:async';

import 'package:despesas_frontend/app/app_router.dart';
import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_payment_screen.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bills_list_screen.dart';
import 'package:despesas_frontend/features/history_imports/presentation/history_import_form_screen.dart';
import 'package:despesas_frontend/features/incomes/presentation/income_form_screen.dart';
import 'package:despesas_frontend/features/reports/presentation/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/test_doubles.dart';

void main() {
  group('App router', () {
    late FakeAuthRepository authRepository;
    late MemorySessionStore sessionStore;
    late SessionController sessionController;

    setUp(() {
      authRepository = FakeAuthRepository();
      sessionStore = MemorySessionStore();
      sessionController = SessionController(
        authRepository: authRepository,
        sessionStore: sessionStore,
      );
    });

    Future<GoRouter> pumpRouter(
      WidgetTester tester, {
      required Widget login,
      FakeExpensesRepository? expensesRepository,
      FakeFinancialAssistantRepository? financialAssistantRepository,
      FakeFixedBillsRepository? fixedBillsRepository,
      FakeHistoryImportsRepository? historyImportsRepository,
      FakeIncomesRepository? incomesRepository,
      FakeSpaceReferencesRepository? spaceReferencesRepository,
      FakeDashboardRepository? dashboardRepository,
    }) async {
      final router = createAppRouter(
        sessionController: sessionController,
        expensesRepository: expensesRepository ?? FakeExpensesRepository(),
        fixedBillsRepository:
            fixedBillsRepository ?? FakeFixedBillsRepository(),
        financialAssistantRepository:
            financialAssistantRepository ?? FakeFinancialAssistantRepository(),
        historyImportsRepository:
            historyImportsRepository ?? FakeHistoryImportsRepository(),
        dashboardRepository: dashboardRepository ?? FakeDashboardRepository(),
        householdMembersRepository: FakeHouseholdMembersRepository(),
        incomesRepository: incomesRepository ?? FakeIncomesRepository(),
        platformAdminRepository: FakePlatformAdminRepository(),
        reportsRepository: FakeReportsRepository(),
        reviewOperationsRepository: FakeReviewOperationsRepository(),
        spaceReferencesRepository:
            spaceReferencesRepository ?? FakeSpaceReferencesRepository(),
        splashScreen: const Placeholder(),
        loginScreenBuilder: () => login,
      );

      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      return router;
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('unauthenticated users are redirected to login', (
      tester,
    ) async {
      await sessionController.clearSession();

      await pumpRouter(tester, login: const Text('login'));

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('logout refreshes the router and returns to login', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      await pumpRouter(tester, login: const Text('login'));

      await sessionController.logout();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(authRepository.logoutCalls, 1);
    });

    testWidgets('dashboard oferece historico direto no menu principal', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/history/import'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Trazer meu histórico'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryImportFormScreen), findsOneWidget);
    });

    testWidgets('logout fica acessivel direto na dashboard', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(authRepository.logoutCalls, 1);
    });

    testWidgets('authenticated users can open /space/references', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/space/references');
      await tester.pumpAndSettle();

      expect(find.text('Referências do seu espaço'), findsOneWidget);
    });

    testWidgets('authenticated users can open /fixed-bills/new', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/fixed-bills/new');
      await tester.pumpAndSettle();

      expect(find.byType(FixedBillFormScreen), findsOneWidget);
      expect(find.text('Cadastrar conta fixa'), findsWidgets);
    });

    testWidgets('authenticated users can open /fixed-bills', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(
        tester,
        login: const Text('login'),
        fixedBillsRepository: FakeFixedBillsRepository(
          listResult: [fakeFixedBillRecord(description: 'Internet fibra')],
        ),
      );
      router.go('/fixed-bills');
      await tester.pumpAndSettle();

      expect(find.byType(FixedBillsListScreen), findsOneWidget);
      expect(find.text('Minhas contas fixas'), findsWidgets);
      expect(find.text('Internet fibra'), findsOneWidget);
    });

    testWidgets('minhas contas fixas mantem menu autenticado e omite a tela atual', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(
        tester,
        login: const Text('login'),
        fixedBillsRepository: FakeFixedBillsRepository(
          listResult: [fakeFixedBillRecord(description: 'Internet fibra')],
        ),
      );
      router.go('/fixed-bills');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/fixed-bills')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/expenses')),
        findsOneWidget,
      );
    });

    testWidgets('authenticated users can open /fixed-bills/:id/edit', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(
        tester,
        login: const Text('login'),
        fixedBillsRepository: FakeFixedBillsRepository(
          getResult: fakeFixedBillRecord(id: 10, description: 'Internet fibra'),
        ),
      );
      router.go('/fixed-bills/10/edit');
      await tester.pumpAndSettle();

      expect(find.byType(FixedBillFormScreen), findsOneWidget);
      expect(find.text('Editar conta fixa'), findsOneWidget);
    });

    testWidgets('cadastro de conta fixa mantem menu autenticado e navegacao coerente', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/fixed-bills/new');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/fixed-bills')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/expenses')),
        findsOneWidget,
      );
    });

    testWidgets('edicao de conta fixa mantem menu autenticado e navegacao coerente', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(
        tester,
        login: const Text('login'),
        fixedBillsRepository: FakeFixedBillsRepository(
          getResult: fakeFixedBillRecord(id: 10, description: 'Internet fibra'),
        ),
      );
      router.go('/fixed-bills/10/edit');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/fixed-bills')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/expenses')),
        findsOneWidget,
      );
    });

    testWidgets('authenticated users can open /history/import', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/history/import');
      await tester.pumpAndSettle();

      expect(find.byType(HistoryImportFormScreen), findsOneWidget);
      expect(find.text('Trazer meu histórico'), findsWidgets);
    });

    testWidgets('menu principal omite a tela atual no historico', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/history/import');
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/history/import'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/expenses')),
        findsOneWidget,
      );
    });

    testWidgets('authenticated users can open /incomes/new', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/incomes/new');
      await tester.pumpAndSettle();

      expect(find.byType(IncomeFormScreen), findsOneWidget);
      expect(find.text('Cadastrar meus ganhos'), findsWidgets);
    });

    testWidgets('authenticated users can open /reports', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/reports');
      await tester.pumpAndSettle();

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.text('Leitura clara do mês financeiro'), findsOneWidget);
    });

    testWidgets('reports mantem menu autenticado e logout acessivel', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/reports');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-menu-item-/reports')),
        findsNothing,
      );

      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('minha senha mantem menu autenticado e omite a tela atual', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        role: 'OWNER',
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'owner@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/change-password');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/change-password'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/history/import'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('owner pages mantem menu autenticado no household', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        role: 'OWNER',
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'owner@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));

      router.go('/household-members');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/household-members'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/review-operations'),
        ),
        findsOneWidget,
      );

      router.go('/review-operations');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('authenticated-top-bar-logout-button')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/review-operations'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('authenticated-top-bar-menu-item-/household-members'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('authenticated users can open /expenses/new', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/expenses/new');
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      expect(find.text('Lançar despesa'), findsOneWidget);
      expect(find.text('Ver despesas'), findsOneWidget);
    });

    testWidgets('authenticated users can open /expenses/:expenseId/pay', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      final router = await pumpRouter(tester, login: const Text('login'));
      router.go('/expenses/7/pay');
      await tester.pumpAndSettle();

      expect(find.byType(ExpensePaymentScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('expense-payment-submit-button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'dashboard -> pagamento direto -> sucesso funciona no fluxo principal do bloco 9',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: AuthOnboarding(
            completed: true,
            completedAt: DateTime.utc(2026, 3, 28, 12),
          ),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        late final FakeExpensesRepository expensesRepository;
        expensesRepository = FakeExpensesRepository(
          detailResult: fakeExpenseDetail(
            id: 10,
            description: 'Internet',
            paidAmount: 0,
            remainingAmount: 89.9,
            paymentsCount: 0,
            payments: const [],
          ),
          onRegisterPayment: (input) {
            expensesRepository.detailResult = fakeExpenseDetail(
              id: 10,
              description: 'Internet',
              status: 'PAGA',
              paidAmount: input.amount,
              remainingAmount: 0,
              paymentsCount: 1,
              payments: [
                fakeExpensePayment(
                  id: 77,
                  expenseId: 10,
                  amount: input.amount,
                  notes: input.notes,
                  method: input.method,
                ),
              ],
            );
          },
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          dashboardRepository: FakeDashboardRepository(
            summary: fakeDashboardSummary(role: 'OWNER'),
          ),
          expensesRepository: expensesRepository,
        );

        await scrollTo(tester, find.text('Internet').first);
        await tester.tap(find.text('Internet').first, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(ExpensePaymentScreen), findsOneWidget);

        await scrollTo(
          tester,
          find.byKey(const ValueKey('expense-payment-submit-button')),
        );
        await tester.tap(
          find.byKey(const ValueKey('expense-payment-submit-button')),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Despesa quitada com sucesso'), findsOneWidget);
      },
    );

    testWidgets('first access users land on the manual-first dashboard', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: const AuthOnboarding(completed: false),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      await pumpRouter(tester, login: const Text('login'));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-first-use-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-first-use-manual-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        findsOneWidget,
      );
      expect(find.text('Bem-vindo ao seu Espaco, Gil'), findsNothing);
    });

    testWidgets(
      'first access users can still open the assistant as optional help',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        await pumpRouter(tester, login: const Text('login'));

        await tester.tap(
          find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Assistente financeiro'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('assistant-tour-card')),
          findsOneWidget,
        );
      },
    );

    testWidgets('subsequent access users keep the normal home flow', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      await pumpRouter(tester, login: const Text('login'));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
        findsOneWidget,
      );
    });

    testWidgets('dashboard home CTA leva para /expenses/new', (tester) async {
      authRepository.loginResult = fakeSession(
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      );

      await sessionController.login(
        email: 'user@example.com',
        password: 'password',
      );

      await pumpRouter(tester, login: const Text('login'));

      await tester.tap(
        find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      expect(find.text('Lançar despesa'), findsOneWidget);
    });

    testWidgets(
      'home -> /expenses/new -> sucesso -> Lancar outra funciona como fluxo diario',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: AuthOnboarding(
            completed: true,
            completedAt: DateTime.utc(2026, 3, 28, 12),
          ),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        final expensesRepository = FakeExpensesRepository(
          createResult: fakeExpense(
            id: 99,
            description: 'Mercado',
            amount: 110,
            createdAt: DateTime.utc(2026, 3, 30, 15, 20),
          ),
          result: PagedResult(
            items: [
              fakeExpense(
                id: 99,
                description: 'Mercado',
                amount: 110,
                createdAt: DateTime.utc(2026, 3, 30, 15, 20),
              ),
            ],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
            hasPrevious: false,
          ),
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          expensesRepository: expensesRepository,
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('expense-form-description-field')),
          'Padaria',
        );
        await tester.enterText(
          find.byKey(const ValueKey('expense-form-amount-field')),
          '23,90',
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('expense-form-submit-button')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('expense-form-submit-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('expense-form-submit-button')),
        );
        await tester.pumpAndSettle();

        expect(expensesRepository.createCalls, 1);
        expect(find.text('Despesa lançada com sucesso'), findsOneWidget);

        await tester.tap(
          find.byKey(
            const ValueKey('expense-form-success-create-another-button'),
          ),
        );
        await tester.pumpAndSettle();

        final descriptionField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('expense-form-description-field')),
        );
        expect(descriptionField.controller?.text, isEmpty);
        expect(find.text('Despesa lançada com sucesso'), findsNothing);
      },
    );

    testWidgets(
      'home -> /expenses/new -> sucesso -> Ver despesas volta para a gestão',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: AuthOnboarding(
            completed: true,
            completedAt: DateTime.utc(2026, 3, 28, 12),
          ),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        final expensesRepository = FakeExpensesRepository(
          createResult: fakeExpense(
            id: 99,
            description: 'Mercado',
            amount: 110,
            createdAt: DateTime.utc(2026, 3, 30, 15, 20),
          ),
          result: PagedResult(
            items: [
              fakeExpense(
                id: 99,
                description: 'Mercado',
                amount: 110,
                createdAt: DateTime.utc(2026, 3, 30, 15, 20),
              ),
            ],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
            hasPrevious: false,
          ),
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          expensesRepository: expensesRepository,
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('expense-form-description-field')),
          'Mercado',
        );
        await tester.enterText(
          find.byKey(const ValueKey('expense-form-amount-field')),
          '110,00',
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('expense-form-submit-button')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('expense-form-submit-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('expense-form-submit-button')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey('expense-form-success-open-expenses-button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suas despesas'), findsOneWidget);
        expect(find.text('Mercado'), findsOneWidget);
      },
    );

    testWidgets('platform admin is not forced into onboarding gate', (
      tester,
    ) async {
      authRepository.loginResult = fakeSession(
        role: 'PLATFORM_ADMIN',
        householdId: null,
        onboarding: const AuthOnboarding(completed: false),
      );

      await sessionController.login(
        email: 'admin@example.com',
        password: 'password',
      );

      await pumpRouter(tester, login: const Text('login'));

      expect(find.text('Provisionamento administrativo'), findsOneWidget);
    });

    testWidgets(
      'expired session while bootstrapping still falls back to login',
      (tester) async {
        sessionStore.refreshToken = 'expired-refresh';
        authRepository.refreshError = const ApiException(
          statusCode: 401,
          message: 'Sua sessao expirou. Faca login novamente.',
        );

        unawaited(sessionController.restoreSession());

        await pumpRouter(tester, login: const Text('login'));

        expect(find.text('login'), findsOneWidget);
      },
    );

    testWidgets(
      'OPEN_IMPORT_HISTORY leva o assistente para o fluxo real de historico',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          financialAssistantRepository: FakeFinancialAssistantRepository(
            starterReply: fakeStarterReply(
              intent: FinancialAssistantStarterIntent.importHistory,
              title: 'Vamos trazer seu histórico',
              message: 'Primeiro monte o lote e revise antes de confirmar.',
              primaryActionKey: 'OPEN_IMPORT_HISTORY',
            ),
          ),
          historyImportsRepository: FakeHistoryImportsRepository(),
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        );
        await tester.pumpAndSettle();

        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-import_history-button')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-import_history-button')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-primary-action')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-primary-action')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(HistoryImportFormScreen), findsOneWidget);
        expect(find.text('Revise antes de confirmar.'), findsNothing);
      },
    );

    testWidgets(
      'OPEN_CONFIGURE_SPACE leva o assistente para o fluxo real de referencias',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          financialAssistantRepository: FakeFinancialAssistantRepository(
            starterReply: fakeStarterReply(
              intent: FinancialAssistantStarterIntent.configureSpace,
              title: 'Vamos organizar seu Espaco',
              message: 'Primeiro, escolha ou crie uma referencia base.',
              primaryActionKey: 'OPEN_CONFIGURE_SPACE',
            ),
          ),
          spaceReferencesRepository: FakeSpaceReferencesRepository(
            references: [fakeSpaceReferenceItem(name: 'Projeto Acme')],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        );
        await tester.pumpAndSettle();

        await scrollTo(
          tester,
          find.byKey(
            const ValueKey('assistant-starter-configure_space-button'),
          ),
        );
        await tester.tap(
          find.byKey(
            const ValueKey('assistant-starter-configure_space-button'),
          ),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-primary-action')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-primary-action')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('Referências do seu espaço'), findsOneWidget);
        expect(find.text('Projeto Acme'), findsOneWidget);
      },
    );

    testWidgets(
      'OPEN_REGISTER_INCOME leva o assistente para o fluxo real de ganhos',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          financialAssistantRepository: FakeFinancialAssistantRepository(
            starterReply: fakeStarterReply(
              intent: FinancialAssistantStarterIntent.registerIncome,
              title: 'Vamos registrar seus ganhos',
              message: 'Primeiro, confirme o essencial antes de gravar.',
              primaryActionKey: 'OPEN_REGISTER_INCOME',
            ),
          ),
          incomesRepository: FakeIncomesRepository(),
          spaceReferencesRepository: FakeSpaceReferencesRepository(
            references: [fakeSpaceReferenceItem(name: 'Projeto Acme')],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        );
        await tester.pumpAndSettle();

        await scrollTo(
          tester,
          find.byKey(
            const ValueKey('assistant-starter-register_income-button'),
          ),
        );
        await tester.tap(
          find.byKey(
            const ValueKey('assistant-starter-register_income-button'),
          ),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-primary-action')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-primary-action')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(IncomeFormScreen), findsOneWidget);
        expect(find.text('Revise antes de confirmar.'), findsNothing);
      },
    );

    testWidgets(
      'OPEN_FIXED_BILLS leva o assistente para o fluxo real de contas fixas',
      (tester) async {
        authRepository.loginResult = fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        );

        await sessionController.login(
          email: 'user@example.com',
          password: 'password',
        );

        await pumpRouter(
          tester,
          login: const Text('login'),
          financialAssistantRepository: FakeFinancialAssistantRepository(
            starterReply: fakeStarterReply(
              intent: FinancialAssistantStarterIntent.fixedBills,
              title: 'Vamos registrar sua conta fixa',
              message: 'Primeiro confirme os dados base antes de gravar.',
              primaryActionKey: 'OPEN_FIXED_BILLS',
            ),
          ),
          fixedBillsRepository: FakeFixedBillsRepository(),
          spaceReferencesRepository: FakeSpaceReferencesRepository(
            references: [fakeSpaceReferenceItem(name: 'Projeto Acme')],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboard-first-use-assistant-button')),
        );
        await tester.pumpAndSettle();

        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-fixed_bills-button')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-fixed_bills-button')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await scrollTo(
          tester,
          find.byKey(const ValueKey('assistant-starter-primary-action')),
        );
        await tester.tap(
          find.byKey(const ValueKey('assistant-starter-primary-action')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(FixedBillFormScreen), findsOneWidget);
        expect(find.text('Cadastrar conta fixa'), findsWidgets);
      },
    );
  });
}
