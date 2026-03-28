import 'dart:async';

import 'package:despesas_frontend/app/app_router.dart';
import 'package:despesas_frontend/app/app_theme.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/financial_assistant/domain/financial_assistant_starter_intent.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:despesas_frontend/features/incomes/presentation/income_form_screen.dart';
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
      FakeFinancialAssistantRepository? financialAssistantRepository,
      FakeFixedBillsRepository? fixedBillsRepository,
      FakeIncomesRepository? incomesRepository,
      FakeSpaceReferencesRepository? spaceReferencesRepository,
    }) async {
      final router = createAppRouter(
        sessionController: sessionController,
        expensesRepository: FakeExpensesRepository(),
        fixedBillsRepository:
            fixedBillsRepository ?? FakeFixedBillsRepository(),
        financialAssistantRepository:
            financialAssistantRepository ?? FakeFinancialAssistantRepository(),
        dashboardRepository: FakeDashboardRepository(),
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

      expect(find.text('Referencias do seu Espaco'), findsOneWidget);
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
      expect(find.text('Cadastrar minhas contas fixas'), findsWidgets);
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

    testWidgets('first access users are redirected to assistant', (
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

      expect(find.text('Bem-vindo ao seu Espaco, Gil'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

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
    });

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

        expect(find.text('Referencias do seu Espaco'), findsOneWidget);
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
        expect(find.text('Revise antes de confirmar.'), findsNothing);
      },
    );
  });
}
