import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:despesas_frontend/features/review_operations/presentation/review_operations_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

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
          reviewOperationsRepository: FakeReviewOperationsRepository(),
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
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Conta de Luz'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
  });

  testWidgets('remains stable on small heights', (tester) async {
    configureSmallViewport(tester);

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
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Conta de Luz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens expense detail when tapping a list item', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    final repository = FakeExpensesRepository(
      result: PagedResult(
        items: [fakeExpense(id: 7, description: 'Conta de Agua')],
        page: 0,
        size: 20,
        totalElements: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      ),
      detailResult: fakeExpenseDetail(
        id: 7,
        description: 'Conta de Agua',
        notes: 'Leitura do mes.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesListScreen(
          sessionController: controller,
          expensesRepository: repository,
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Conta de Agua'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseDetailScreen), findsOneWidget);
    expect(find.text('Detalhe da despesa'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(repository.detailCalls, 1);
  });

  testWidgets('opens expense form when tapping new expense action', (
    tester,
  ) async {
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
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Nova despesa').first);
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseFormScreen), findsOneWidget);
    expect(find.text('Nova despesa'), findsWidgets);
  });

  testWidgets('opens review operations for owner', (tester) async {
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
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Review operations'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewOperationsListScreen), findsOneWidget);
  });
}
