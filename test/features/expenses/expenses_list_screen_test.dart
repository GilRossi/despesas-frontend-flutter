import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('shows empty state when there are no expenses', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesListScreen(
          sessionController: controller,
          expensesRepository: FakeExpensesRepository(result: emptyPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Nenhuma despesa encontrada'), findsOneWidget);
  });

  testWidgets('shows loaded expenses from the repository', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesListScreen(
          sessionController: controller,
          expensesRepository: FakeExpensesRepository(
            result: PagedResult(
              items: [fakeExpense(description: 'Conta de Luz')],
              page: 0,
              size: 20,
              totalElements: 1,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Conta de Luz'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
  });
}
