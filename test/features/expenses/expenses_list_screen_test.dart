import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/domain/paged_result.dart';
import 'package:despesas_frontend/features/expenses/domain/save_expense_input.dart';
import 'package:despesas_frontend/features/expenses/presentation/expenses_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

  void configureLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1400);
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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Conta de Luz'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
    expect(
      find.text(
        'Cada card destaca status, vencimento e saldo restante para reduzir leitura desnecessaria.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('highlights the recently created expense at the top of the list', (
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
          initialHighlightedExpenseId: 77,
          sessionController: controller,
          expensesRepository: FakeExpensesRepository(
            result: PagedResult(
              items: [
                fakeExpense(
                  id: 77,
                  description: 'Recem criada',
                  createdAt: DateTime.utc(2026, 3, 30, 15, 20),
                ),
                fakeExpense(
                  id: 10,
                  description: 'Mais antiga',
                  createdAt: DateTime.utc(2026, 3, 28, 10, 0),
                ),
              ],
              page: 0,
              size: 20,
              totalElements: 2,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          ),
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Recem criada'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('Mais antiga'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final recemCriadaTop = tester.getTopLeft(find.text('Recem criada').first).dy;
    final maisAntigaTop = tester.getTopLeft(find.text('Mais antiga')).dy;
    expect(recemCriadaTop, lessThan(maisAntigaTop));
  });

  testWidgets(
    'shows the newly created expense immediately even before the refreshed list finishes',
    (tester) async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(loginResult: fakeSession()),
        sessionStore: MemorySessionStore(),
      );
      await controller.login(email: 'gil@example.com', password: 'Senha123!');

      final repository = FakeExpensesRepository(
        result: emptyPage(),
        listDelay: const Duration(milliseconds: 300),
      );
      await repository.createExpense(
        SaveExpenseInput(
          description: 'Despesa imediata',
          amount: 89.9,
          occurredOn: DateTime.utc(2026, 3, 30),
          dueDate: null,
          categoryId: 1,
          subcategoryId: 10,
          spaceReferenceId: null,
          notes: '',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpensesListScreen(
            sessionController: controller,
            expensesRepository: repository,
            financialAssistantRepository: FakeFinancialAssistantRepository(),
            householdMembersRepository: FakeHouseholdMembersRepository(),
            reportsRepository: FakeReportsRepository(),
            reviewOperationsRepository: FakeReviewOperationsRepository(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Despesa imediata'), findsOneWidget);
      expect(find.text('Recem criada'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Despesa imediata'), findsOneWidget);
    },
  );

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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Conta de Luz'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Conta de Luz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens expense detail when tapping a list item', (tester) async {
    configureLargeViewport(tester);

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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final expenseCard = find.ancestor(
      of: find.text('Conta de Agua'),
      matching: find.byType(InkWell),
    );

    await tester.scrollUntilVisible(
      expenseCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(expenseCard);
    await tester.tap(expenseCard);
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseDetailScreen), findsOneWidget);
    expect(find.text('Detalhe da despesa'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(repository.detailCalls, 1);
  });

  testWidgets(
    'registers payment from detail and reloads the management list on return',
    (tester) async {
      configureLargeViewport(tester);

      final controller = SessionController(
        authRepository: FakeAuthRepository(loginResult: fakeSession()),
        sessionStore: MemorySessionStore(),
      );
      await controller.login(email: 'gil@example.com', password: 'Senha123!');

      late final FakeExpensesRepository repository;
      repository = FakeExpensesRepository(
        result: PagedResult(
          items: [
            fakeExpense(id: 7, description: 'Conta de Agua', status: 'ABERTA'),
          ],
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
          paidAmount: 0,
          remainingAmount: 129.9,
          paymentsCount: 0,
          payments: const [],
        ),
        onRegisterPayment: (input) {
          repository.detailResult = fakeExpenseDetail(
            id: 7,
            description: 'Conta de Agua',
            status: 'PARCIALMENTE_PAGA',
            paidAmount: input.amount,
            remainingAmount: 80,
            paymentsCount: 1,
            payments: [
              fakeExpensePayment(
                id: 11,
                expenseId: 7,
                amount: input.amount,
                notes: input.notes,
                method: input.method,
              ),
            ],
          );
          repository.result = PagedResult(
            items: [
              fakeExpense(
                id: 7,
                description: 'Conta de Agua',
                status: 'PARCIALMENTE_PAGA',
              ),
            ],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
            hasPrevious: false,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpensesListScreen(
            sessionController: controller,
            expensesRepository: repository,
            financialAssistantRepository: FakeFinancialAssistantRepository(),
            householdMembersRepository: FakeHouseholdMembersRepository(),
            reportsRepository: FakeReportsRepository(),
            reviewOperationsRepository: FakeReviewOperationsRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(
        find.ancestor(
          of: find.text('Conta de Agua'),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor pago'),
        '49,90',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Observacoes do pagamento'),
        'Pagamento parcial',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Registrar pagamento'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar pagamento'),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Pagamento registrado com sucesso.'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ExpensesListScreen), findsOneWidget);
      expect(find.text('Pagamento registrado com sucesso.'), findsOneWidget);
      expect(repository.listCalls, 2);
      expect(find.text('Parcialmente paga'), findsOneWidget);
    },
  );

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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
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

  testWidgets(
    'creates expense from /expenses and reloads the management list',
    (tester) async {
      final controller = SessionController(
        authRepository: FakeAuthRepository(loginResult: fakeSession()),
        sessionStore: MemorySessionStore(),
      );
      await controller.login(email: 'gil@example.com', password: 'Senha123!');

      late FakeExpensesRepository repository;
      repository = FakeExpensesRepository(
        result: emptyPage(),
        createResult: fakeExpense(
          id: 99,
          description: 'Farmacia',
          amount: 42.10,
          createdAt: DateTime.utc(2026, 3, 30, 15, 20),
        ),
        onCreate: (input) {
          repository.result = PagedResult(
            items: [
              fakeExpense(
                id: 99,
                description: input.description,
                amount: input.amount,
                createdAt: DateTime.utc(2026, 3, 30, 15, 20),
              ),
            ],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
            hasPrevious: false,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ExpensesListScreen(
            sessionController: controller,
            expensesRepository: repository,
            financialAssistantRepository: FakeFinancialAssistantRepository(),
            householdMembersRepository: FakeHouseholdMembersRepository(),
            reportsRepository: FakeReportsRepository(),
            reviewOperationsRepository: FakeReviewOperationsRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Nova despesa').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('expense-form-description-field')),
        'Farmacia',
      );
      await tester.enterText(
        find.byKey(const ValueKey('expense-form-amount-field')),
        '42,10',
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

      expect(find.text('Despesa criada com sucesso.'), findsOneWidget);
      expect(find.text('Farmacia'), findsOneWidget);
      expect(find.text('Recem criada'), findsOneWidget);
      expect(repository.createCalls, 1);
      expect(repository.listCalls, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('keeps the local header focused on the expense list flow', (
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
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Lista principal do household'), findsOneWidget);
    expect(find.byKey(const ValueKey('expenses-new-expense-button')), findsOneWidget);
    expect(find.text('Assistente financeiro'), findsNothing);
    expect(find.text('Relatorios'), findsNothing);
    expect(find.text('Minha senha'), findsNothing);
    expect(find.text('Membros do household'), findsNothing);
    expect(find.text('Review operations'), findsNothing);
  });

  testWidgets('hides household members flow for non-owner', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(role: 'MEMBER'),
      ),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'bia@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      MaterialApp(
        home: ExpensesListScreen(
          sessionController: controller,
          expensesRepository: FakeExpensesRepository(result: emptyPage()),
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Membros do household'), findsNothing);
  });

  testWidgets('shows clearer payment progress and status labels', (tester) async {
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
              items: [
                fakeExpense(
                  id: 1,
                  description: 'Streaming',
                  status: 'ABERTA',
                  dueDate: null,
                ),
                fakeExpense(
                  id: 2,
                  description: 'Celular',
                  status: 'PARCIALMENTE_PAGA',
                  amount: 59.9,
                  paidAmount: 20,
                  remainingAmount: 39.9,
                ),
                fakeExpense(
                  id: 3,
                  description: 'Internet',
                  status: 'PAGA',
                  paidAmount: 129.9,
                  remainingAmount: 0,
                ),
              ],
              page: 0,
              size: 20,
              totalElements: 3,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          ),
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Em aberto'), findsOneWidget);
    expect(find.text('Parcialmente paga'), findsOneWidget);
    expect(find.text('Restante R\$ 129,90'), findsOneWidget);
    expect(find.text('Pago R\$ 20,00 · Restam R\$ 39,90'), findsOneWidget);
  });

  testWidgets('remains stable with increased text scale in header', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);

    final controller = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          name: 'Nome com zoom alto no Android',
          email: 'email.muito.longo.para.validar.text.scale@example.com',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          );
        },
        home: ExpensesListScreen(
          sessionController: controller,
          expensesRepository: FakeExpensesRepository(result: emptyPage()),
          financialAssistantRepository: FakeFinancialAssistantRepository(),
          householdMembersRepository: FakeHouseholdMembersRepository(),
          reportsRepository: FakeReportsRepository(),
          reviewOperationsRepository: FakeReviewOperationsRepository(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Nome com zoom alto no Android'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
