import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
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

  void configureKeyboardViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
  }

  testWidgets('shows expense detail content when load succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailResult: fakeExpenseDetail(
              description: 'Plano de Internet',
              notes: 'Cobrar no cartao.',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Plano de Internet'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    final registerPaymentButton = find.widgetWithText(
      FilledButton,
      'Registrar pagamento',
    );
    await tester.ensureVisible(registerPaymentButton);
    await tester.pumpAndSettle();
    expect(registerPaymentButton, findsOneWidget);
    await tester.ensureVisible(find.text('Histórico de pagamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de pagamentos'), findsOneWidget);
    expect(find.text('20/03/2026'), findsOneWidget);
    expect(find.text('Pix'), findsAtLeastNWidgets(1));
    expect(find.text('Pagamento parcial'), findsOneWidget);
    await tester.ensureVisible(find.text('Observações'));
    await tester.pumpAndSettle();
    expect(find.text('Observações'), findsOneWidget);
    expect(find.text('Cobrar no cartao.'), findsOneWidget);
  });

  testWidgets('submits a new payment and refreshes payment history', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 0,
        remainingAmount: 129.9,
        paymentsCount: 0,
        payments: const [],
      ),
    );
    repository.onRegisterPayment = (input) {
      repository.detailResult = fakeExpenseDetail(
        paidAmount: input.amount,
        remainingAmount: 80,
        status: 'PARCIALMENTE_PAGA',
        paymentsCount: 1,
        payments: [
          fakeExpensePayment(
            id: 7,
            amount: input.amount,
            notes: input.notes,
            method: input.method,
          ),
        ],
      );
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(expenseId: 1, expensesRepository: repository),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor pago'),
      '49,90',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Observações do pagamento'),
      'Pagamento avulso',
    );
    final submitButton = find.widgetWithText(
      FilledButton,
      'Registrar pagamento',
    );
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.registerPaymentCalls, 1);
    expect(find.text('Pagamento registrado com sucesso.'), findsOneWidget);
    await tester.ensureVisible(find.text('Histórico de pagamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Parcialmente Paga'), findsOneWidget);
    expect(find.text('R\$ 80,00'), findsAtLeastNWidgets(1));
    expect(find.text('Pagamento avulso'), findsOneWidget);
    expect(find.text('49,90'), findsNothing);
    expect(find.text('R\$ 49,90'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'shows validation when payment amount exceeds remaining balance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseDetailScreen(
            expenseId: 1,
            expensesRepository: FakeExpensesRepository(
              detailResult: fakeExpenseDetail(
                paidAmount: 40,
                remainingAmount: 20,
                paymentsCount: 1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor pago'),
        '25',
      );
      final submitButton = find.widgetWithText(
        FilledButton,
        'Registrar pagamento',
      );
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('O valor não pode ser maior que o saldo restante.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows empty payments state when expense has no payments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailResult: fakeExpenseDetail(
              payments: const [],
              paymentsCount: 0,
              paidAmount: 0,
              remainingAmount: 129.9,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Histórico de pagamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de pagamentos'), findsOneWidget);
    expect(
      find.text('Nenhum pagamento registrado para esta despesa.'),
      findsOneWidget,
    );
  });

  testWidgets('not found and error states expose a clear exit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailError: fakeApiException(
              statusCode: 404,
              message: 'Despesa nao encontrada',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Despesa não encontrada'), findsOneWidget);
    expect(find.text('Voltar às despesas'), findsOneWidget);
  });

  testWidgets('shows paid off message without payment form action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailResult: fakeExpenseDetail(
              paidAmount: 129.9,
              remainingAmount: 0,
              paymentsCount: 2,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Esta despesa já foi quitada.'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Registrar pagamento'),
      findsNothing,
    );
  });

  testWidgets('stays scrollable on small heights', (tester) async {
    configureSmallViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailResult: fakeExpenseDetail(
              description: 'Plano de Internet',
              notes: 'Cobrar no cartao.',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Observações'));
    await tester.pumpAndSettle();

    expect(find.text('Observações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps payment form usable with keyboard open on small heights', (
    tester,
  ) async {
    configureKeyboardViewport(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 1,
          expensesRepository: FakeExpensesRepository(
            detailResult: fakeExpenseDetail(
              paidAmount: 0,
              remainingAmount: 129.9,
              paymentsCount: 0,
              payments: const [],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    final notesField = find.widgetWithText(
      TextFormField,
      'Observações do pagamento',
    );
    await tester.ensureVisible(notesField);
    await tester.pumpAndSettle();
    await tester.tap(notesField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Registrar pagamento'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Registrar pagamento'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows not found state when expense does not exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 99,
          expensesRepository: FakeExpensesRepository(
            detailError: fakeApiException(
              statusCode: 404,
              message: 'Despesa nao encontrada',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Despesa não encontrada'), findsOneWidget);
  });

  testWidgets('shows retry state when loading detail fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(
          expenseId: 42,
          expensesRepository: FakeExpensesRepository(
            detailError: fakeApiException(message: 'Falha simulada'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar a despesa.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('edits expense and reloads detail after save', (tester) async {
    late final FakeExpensesRepository repository;
    repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(description: 'Internet Fibra'),
      onUpdate: (_, input) {
        repository.detailResult = fakeExpenseDetail(
          description: input.description,
          amount: input.amount,
          notes: input.notes,
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseDetailScreen(expenseId: 1, expensesRepository: repository),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Internet Premium',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '159,90');
    await tester.scrollUntilVisible(
      find.text('Salvar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(find.text('Despesa atualizada com sucesso.'), findsOneWidget);
    expect(find.text('Internet Premium'), findsOneWidget);
  });

  testWidgets('deletes expense and returns reload result to parent', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(description: 'Internet Fibra'),
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
                            builder: (_) => ExpenseDetailScreen(
                              expenseId: 1,
                              expensesRepository: repository,
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir detalhe'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.deleteCalls, 1);
    expect(repository.lastDeletedExpenseId, 1);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Despesa excluida com sucesso.');
  });

  testWidgets('deletes expense opened as root route and redirects safely', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(description: 'Internet Fibra'),
    );
    final router = GoRouter(
      initialLocation: '/expenses/1',
      routes: [
        GoRoute(
          path: '/expenses',
          builder: (context, state) =>
              const Scaffold(body: Text('expenses-root-page')),
        ),
        GoRoute(
          path: '/expenses/:expenseId',
          builder: (context, state) => ExpenseDetailScreen(
            expenseId: int.parse(state.pathParameters['expenseId']!),
            expensesRepository: repository,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(find.text('expenses-root-page'), findsOneWidget);
  });
}
