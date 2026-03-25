import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('shows summary and action section', (tester) async {
    final dashboardRepository = FakeDashboardRepository();
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          dashboardRepository: dashboardRepository,
          sessionController: sessionController,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Precisa da sua ação'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-open-assistant-button')), findsOneWidget);
    expect(dashboardRepository.calls, 1);
  });
}
