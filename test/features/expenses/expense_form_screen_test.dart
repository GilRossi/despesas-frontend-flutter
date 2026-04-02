import 'dart:async';

import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:despesas_frontend/app/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    addTearDown(tester.view.reset);
  }

  testWidgets('creates expense and returns reload result', (tester) async {
    final repository = FakeExpensesRepository();
    Future<ExpenseFlowResult?>? resultFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    resultFuture = Navigator.of(context)
                        .push<ExpenseFlowResult>(
                          MaterialPageRoute(
                            builder: (_) => ExpenseFormScreen(
                              expensesRepository: repository,
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Plano de celular',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '89,90');
    await tester.scrollUntilVisible(
      find.text('Criar despesa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar despesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar despesa'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.description, 'Plano de celular');
    expect(repository.lastCreatedInput?.amount, 89.9);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Despesa criada com sucesso.');
  });

  testWidgets('editing an expense updates it and returns reload result', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        id: 7,
        description: 'Plano antigo',
        amount: 89.9,
        notes: 'Antiga observação',
      ),
    );
    Future<ExpenseFlowResult?>? resultFuture;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    resultFuture = Navigator.of(context)
                        .push<ExpenseFlowResult>(
                          MaterialPageRoute(
                            builder: (_) => ExpenseFormScreen(
                              expensesRepository: repository,
                              initialExpense: fakeExpenseDetail(
                                id: 7,
                                description: 'Plano antigo',
                                amount: 89.9,
                                notes: 'Antiga observação',
                              ),
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Plano atualizado',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '99,90',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.updateCalls, 1);
    expect(repository.lastUpdatedExpenseId, 7);
    expect(repository.lastUpdatedInput?.description, 'Plano atualizado');
    expect(repository.lastUpdatedInput?.amount, 99.9);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Despesa atualizada com sucesso.');
  });

  testWidgets('create flow can mark the expense as already paid', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      createResult: fakeExpense(
        description: 'Plano de celular',
        amount: 89.9,
        status: 'PAGA',
        paidAmount: 89.9,
        remainingAmount: 0,
      ),
    );
    late final GoRouter router;

    router = GoRouter(
      initialLocation: '/expenses/new',
      routes: [
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => ExpenseFormScreen(
            expensesRepository: repository,
            standalone: true,
          ),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Scaffold(body: Text('Despesas')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Plano de celular',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '89,90',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-form-initial-payment-toggle')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-form-initial-payment-toggle')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('expense-form-submit-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.initialPayment, isNotNull);
    expect(repository.lastCreatedInput?.initialPayment?.method, 'PIX');
    expect(find.text('Despesa lançada e quitada'), findsOneWidget);
  });

  testWidgets('standalone flow shows success state with clear CTAs', (
    tester,
  ) async {
    final repository = FakeExpensesRepository();
    late final GoRouter router;

    router = GoRouter(
      initialLocation: '/expenses/new',
      routes: [
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => ExpenseFormScreen(
            expensesRepository: repository,
            standalone: true,
          ),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Scaffold(body: Text('Despesas')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Café da tarde',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '28,50',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.text('Despesa lançada com sucesso'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expense-form-success-create-another-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('expense-form-success-open-expenses-button')),
      findsOneWidget,
    );
  });

  testWidgets('standalone success lets user start another expense quickly', (
    tester,
  ) async {
    final repository = FakeExpensesRepository();
    late final GoRouter router;

    router = GoRouter(
      initialLocation: '/expenses/new',
      routes: [
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => ExpenseFormScreen(
            expensesRepository: repository,
            standalone: true,
          ),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Scaffold(body: Text('Despesas')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Mercado',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '120,00',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('expense-form-success-create-another-button')),
    );
    await tester.pumpAndSettle();

    final descriptionField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('expense-form-description-field')),
    );
    final amountField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('expense-form-amount-field')),
    );
    final occurredOnField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('expense-form-occurred-on-field')),
    );

    expect(find.text('Despesa lançada com sucesso'), findsNothing);
    expect(descriptionField.controller?.text, isEmpty);
    expect(amountField.controller?.text, isEmpty);
    expect(occurredOnField.controller?.text, isNotEmpty);
  });

  testWidgets('standalone success secondary CTA goes to expenses list', (
    tester,
  ) async {
    final repository = FakeExpensesRepository();
    late final GoRouter router;

    router = GoRouter(
      initialLocation: '/expenses/new',
      routes: [
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => ExpenseFormScreen(
            expensesRepository: repository,
            standalone: true,
          ),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const Scaffold(body: Text('Despesas')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Lanche',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '18,90',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('expense-form-success-open-expenses-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despesas'), findsOneWidget);
  });

  testWidgets('shows backend validation feedback on form', (tester) async {
    final repository = FakeExpensesRepository(
      createError: fakeApiException(
        message: 'Request validation failed',
        fieldErrors: const {'description': 'Descrição já utilizada.'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ExpenseFormScreen(expensesRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Plano de celular',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '89,90');
    await tester.scrollUntilVisible(
      find.text('Criar despesa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar despesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar despesa'));
    await tester.pumpAndSettle();

    expect(find.text('Request validation failed'), findsOneWidget);
    expect(find.text('Descrição já utilizada.'), findsOneWidget);
  });

  testWidgets('shows generic submit error when request fails unexpectedly', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(createError: Exception('boom'));

    await tester.pumpWidget(
      MaterialApp(home: ExpenseFormScreen(expensesRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Internet',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '89,90',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível salvar a despesa.'), findsOneWidget);
  });

  testWidgets('atalho de conta fixa entra primeiro no formulario', (
    tester,
  ) async {
    late final GoRouter router;
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(email: 'gil@example.com', password: 'Senha123!');

    router = GoRouter(
      initialLocation: '/expenses/new',
      routes: [
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => ExpenseFormScreen(
            expensesRepository: FakeExpensesRepository(),
            standalone: true,
          ),
        ),
        GoRoute(
          path: '/fixed-bills/new',
          builder: (context, state) => FixedBillFormScreen(
            sessionController: sessionController,
            fixedBillsRepository: FakeFixedBillsRepository(),
            expensesRepository: FakeExpensesRepository(),
            spaceReferencesRepository: FakeSpaceReferencesRepository(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Conta fixa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conta fixa').first);
    await tester.pumpAndSettle();

    expect(find.byType(FixedBillFormScreen), findsOneWidget);
    expect(find.text('Cadastrar conta fixa'), findsWidgets);
  });

  testWidgets('shows submit loading state while create request is pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = FakeExpensesRepository(
      onCreateAsync: (_) => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseFormScreen(
          expensesRepository: repository,
          standalone: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      'Conta de água',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '75,40',
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
    await tester.tap(find.byKey(const ValueKey('expense-form-submit-button')));
    await tester.pump();

    expect(repository.createCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Criar despesa'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Despesa lançada com sucesso'), findsOneWidget);
  });

  testWidgets('stays usable on small heights with keyboard inset', (
    tester,
  ) async {
    configureSmallViewport(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseFormScreen(expensesRepository: FakeExpensesRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('expense-form-description-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('expense-form-description-field')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Criar despesa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Criar despesa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows catalog load error and retry action', (tester) async {
    final repository = FakeExpensesRepository(
      catalogError: fakeApiException(
        message: 'Não foi possível carregar categorias agora.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: ExpenseFormScreen(expensesRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o catálogo.'), findsOneWidget);
    expect(
      find.text('Não foi possível carregar categorias agora.'),
      findsOneWidget,
    );

    repository.catalogError = null;

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repository.catalogCalls, 2);
    expect(find.text('Não foi possível carregar o catálogo.'), findsNothing);
    expect(find.text('Criar despesa'), findsOneWidget);
  });
}
