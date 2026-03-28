import 'package:despesas_frontend/app/despesas_app.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/domain/auth_onboarding.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:despesas_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_doubles.dart';

void main() {
  testWidgets('auth gate shows login screen when user is unauthenticated', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
    await controller.restoreSession();

    await tester.pumpWidget(
      DespesasApp(
        environment: AppEnvironment(
          name: 'test',
          apiBaseUrl: Uri.parse('http://localhost:8080'),
        ),
        sessionController: controller,
        expensesRepository: FakeExpensesRepository(),
        fixedBillsRepository: FakeFixedBillsRepository(),
        financialAssistantRepository: FakeFinancialAssistantRepository(),
        householdMembersRepository: FakeHouseholdMembersRepository(),
        incomesRepository: FakeIncomesRepository(),
        platformAdminRepository: FakePlatformAdminRepository(),
        reportsRepository: FakeReportsRepository(),
        reviewOperationsRepository: FakeReviewOperationsRepository(),
        dashboardRepository: FakeDashboardRepository(),
        spaceReferencesRepository: FakeSpaceReferencesRepository(),
        autoRestoreSession: false,
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('auth gate shows dashboard when user is authenticated', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          onboarding: AuthOnboarding(
            completed: true,
            completedAt: DateTime.utc(2026, 3, 28, 12),
          ),
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      DespesasApp(
        environment: AppEnvironment(
          name: 'test',
          apiBaseUrl: Uri.parse('http://localhost:8080'),
        ),
        sessionController: controller,
        expensesRepository: FakeExpensesRepository(),
        fixedBillsRepository: FakeFixedBillsRepository(),
        financialAssistantRepository: FakeFinancialAssistantRepository(),
        householdMembersRepository: FakeHouseholdMembersRepository(),
        incomesRepository: FakeIncomesRepository(),
        platformAdminRepository: FakePlatformAdminRepository(),
        reportsRepository: FakeReportsRepository(),
        reviewOperationsRepository: FakeReviewOperationsRepository(),
        dashboardRepository: FakeDashboardRepository(),
        spaceReferencesRepository: FakeSpaceReferencesRepository(),
        autoRestoreSession: false,
      ),
    );
    await tester.pump();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('auth gate shows admin screen for platform admin', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          role: 'PLATFORM_ADMIN',
          householdId: null,
          email: 'admin@local.invalid',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'admin@local.invalid', password: 'Senha123!');

    await tester.pumpWidget(
      DespesasApp(
        environment: AppEnvironment(
          name: 'test',
          apiBaseUrl: Uri.parse('http://localhost:8080'),
        ),
        sessionController: controller,
        expensesRepository: FakeExpensesRepository(),
        fixedBillsRepository: FakeFixedBillsRepository(),
        financialAssistantRepository: FakeFinancialAssistantRepository(),
        householdMembersRepository: FakeHouseholdMembersRepository(),
        incomesRepository: FakeIncomesRepository(),
        platformAdminRepository: FakePlatformAdminRepository(),
        reportsRepository: FakeReportsRepository(),
        reviewOperationsRepository: FakeReviewOperationsRepository(),
        dashboardRepository: FakeDashboardRepository(),
        spaceReferencesRepository: FakeSpaceReferencesRepository(),
        autoRestoreSession: false,
      ),
    );
    await tester.pump();

    expect(find.byType(PlatformAdminScreen), findsOneWidget);
  });
}
