import 'package:despesas_frontend/features/expenses/presentation/expense_detail_screen.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
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
    await tester.scrollUntilVisible(
      find.text('Historico de pagamentos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Historico de pagamentos'), findsOneWidget);
    expect(find.text('20/03/2026'), findsOneWidget);
    expect(find.text('Pix'), findsOneWidget);
    expect(find.text('Pagamento parcial'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Observacoes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Observacoes'), findsOneWidget);
    expect(find.text('Cobrar no cartao.'), findsOneWidget);
  });

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

    await tester.scrollUntilVisible(
      find.text('Historico de pagamentos'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Historico de pagamentos'), findsOneWidget);
    expect(
      find.text('Nenhum pagamento registrado para esta despesa.'),
      findsOneWidget,
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
    await tester.scrollUntilVisible(
      find.text('Observacoes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Observacoes'), findsOneWidget);
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

    expect(find.text('Despesa nao encontrada'), findsOneWidget);
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

    expect(find.text('Nao foi possivel carregar a despesa.'), findsOneWidget);
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
}
