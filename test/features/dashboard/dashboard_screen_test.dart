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
  SessionController buildSessionController({String role = 'OWNER'}) {
    final authRepository = FakeAuthRepository(
      loginResult: fakeSession(
        role: role,
        onboarding: AuthOnboarding(
          completed: true,
          completedAt: DateTime.utc(2026, 3, 28, 12),
        ),
      ),
    );
    final sessionController = SessionController(
      authRepository: authRepository,
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
    expect(find.byKey(const ValueKey('dashboard-open-assistant-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-owner-month-overview-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-owner-category-spending-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-owner-household-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-member-quick-actions-card')), findsNothing);
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
    expect(find.byKey(const ValueKey('dashboard-member-quick-actions-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-quick-action-OPEN_REPORTS')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-owner-month-overview-card')), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-owner-category-spending-card')), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-owner-household-summary-card')), findsNothing);
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

    await tester.tap(find.byKey(const ValueKey('dashboard-open-assistant-button')));
    await tester.pumpAndSettle();

    expect(find.text('assistant-page'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('dashboard-quick-action-OPEN_REPORTS')));
    await tester.pumpAndSettle();

    expect(find.text('reports-page'), findsOneWidget);
  });

  testWidgets('mostra loading enquanto o dashboard ainda nao chegou', (
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
      find.text('Nao foi possivel carregar seu dashboard agora.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
