import 'package:despesas_frontend/app/despesas_app.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
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
        autoRestoreSession: false,
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('auth gate shows expenses list when user is authenticated', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
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
        autoRestoreSession: false,
      ),
    );
    await tester.pump();

    expect(find.byType(ExpensesListScreen), findsOneWidget);
  });
}
