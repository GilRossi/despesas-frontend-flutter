import 'dart:async';

import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_repository.dart';
import 'package:despesas_frontend/features/dashboard/domain/dashboard_summary.dart';
import 'package:despesas_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_doubles.dart';

void main() {
  SessionController buildSessionController({
    String role = 'OWNER',
    AuthOnboarding onboarding = const AuthOnboarding(
      completed: true,
      completedAt: null,
    ),
    FakeAuthRepository? authRepository,
  }) {
    final repository =
        authRepository ??
        FakeAuthRepository(
          loginResult: fakeSession(
            role: role,
            onboarding: onboarding.completed
                ? AuthOnboarding(
                    completed: true,
                    completedAt:
                        onboarding.completedAt ?? DateTime.utc(2026, 3, 28, 12),
                  )
                : onboarding,
          ),
        );
    final sessionController = SessionController(
      authRepository: repository,
      sessionStore: MemorySessionStore(),
    );
    return sessionController;
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required DashboardRepository repository,
    required SessionController sessionController,
  }) async {
    await sessionController.login(
      email: 'user@example.com',
      password: 'password',
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardScreen(
            dashboardRepository: repository,
            sessionController: sessionController,
          ),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) =>
              const Scaffold(body: Text('assistant-page')),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) =>
              const Scaffold(body: Text('expenses-page')),
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) =>
              const Scaffold(body: Text('new-expense-page')),
        ),
        GoRoute(
          path: '/expenses/:expenseId/pay',
          builder: (context, state) => Scaffold(
            body: Text('pay-page-${state.pathParameters['expenseId']}'),
          ),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) =>
              const Scaffold(body: Text('reports-page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('renderiza blocos de OWNER e omite quickActions', (tester) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'OWNER'),
    );
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo principal'), findsOneWidget);
    expect(find.text('Precisa da sua ação'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-open-assistant-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-month-overview-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-category-spending-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-household-summary-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-member-quick-actions-card')),
      findsNothing,
    );
    expect(repository.calls, 1);
  });

  testWidgets('renderiza blocos de MEMBER e omite owner-only', (tester) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'MEMBER'),
    );
    final sessionController = buildSessionController(role: 'MEMBER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo principal'), findsOneWidget);
    expect(find.text('Precisa da sua ação'), findsOneWidget);
    expect(find.text('Atividade recente'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-member-quick-actions-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-quick-action-OPEN_REPORTS')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-month-overview-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-category-spending-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard-owner-household-summary-card')),
      findsNothing,
    );
  });

  testWidgets('card do assistente leva para /assistant', (tester) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'OWNER'),
    );
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dashboard-open-assistant-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('dashboard-open-assistant-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('assistant-page'), findsOneWidget);
  });

  testWidgets('primeiro uso mostra onboarding curto orientado ao manual', (
    tester,
  ) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'OWNER'),
    );
    final sessionController = buildSessionController(
      role: 'OWNER',
      onboarding: const AuthOnboarding(completed: false),
    );

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

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
  });

  testWidgets(
    'CTA manual do onboarding conclui a introducao e leva para /expenses/new',
    (tester) async {
      final repository = FakeDashboardRepository(
        summary: fakeDashboardSummary(role: 'OWNER'),
      );
      final authRepository = FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: const AuthOnboarding(completed: false),
        ),
      );
      final sessionController = buildSessionController(
        role: 'OWNER',
        onboarding: const AuthOnboarding(completed: false),
        authRepository: authRepository,
      );

      await pumpDashboard(
        tester,
        repository: repository,
        sessionController: sessionController,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('dashboard-first-use-manual-button')),
      );
      await tester.pumpAndSettle();

      expect(authRepository.completeOnboardingCalls, 1);
      expect(find.text('new-expense-page'), findsOneWidget);
    },
  );

  testWidgets('CTA de lancar despesa leva para /expenses/new para OWNER', (
    tester,
  ) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'OWNER'),
    );
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('new-expense-page'), findsOneWidget);
  });

  testWidgets('CTA de lancar despesa leva para /expenses/new para MEMBER', (
    tester,
  ) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'MEMBER'),
    );
    final sessionController = buildSessionController(role: 'MEMBER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('dashboard-hero-new-expense-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('new-expense-page'), findsOneWidget);
  });

  testWidgets('quick action de reports leva para /reports', (tester) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'MEMBER'),
    );
    final sessionController = buildSessionController(role: 'MEMBER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dashboard-quick-action-OPEN_REPORTS')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('dashboard-quick-action-OPEN_REPORTS')),
    );
    await tester.pumpAndSettle();

    expect(find.text('reports-page'), findsOneWidget);
  });

  testWidgets('item de precisa da sua ação leva para pagamento direto', (
    tester,
  ) async {
    final repository = FakeDashboardRepository(
      summary: fakeDashboardSummary(role: 'OWNER'),
    );
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Internet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Internet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('pay-page-10'), findsOneWidget);
  });

  testWidgets('mostra loading enquanto o dashboard ainda não chegou', (
    tester,
  ) async {
    final completer = Completer<DashboardSummary>();
    final repository = FakeDashboardRepository(onFetch: () => completer.future);
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pump();

    expect(find.text('Carregando seu dashboard...'), findsOneWidget);

    completer.complete(fakeDashboardSummary(role: 'OWNER'));
    await tester.pumpAndSettle();
  });

  testWidgets('mostra erro quando o repository falha', (tester) async {
    final repository = FakeDashboardRepository(
      error: const FormatException('Falha simulada'),
    );
    final sessionController = buildSessionController(role: 'OWNER');

    await pumpDashboard(
      tester,
      repository: repository,
      sessionController: sessionController,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar seu painel agora.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
