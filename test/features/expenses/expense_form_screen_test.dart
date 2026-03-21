import 'package:despesas_frontend/features/expenses/presentation/expense_flow_result.dart';
import 'package:despesas_frontend/features/expenses/presentation/expense_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.text('Criar despesa'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.description, 'Plano de celular');
    expect(repository.lastCreatedInput?.amount, 89.9);
    expect(result?.shouldReload, isTrue);
    expect(result?.message, 'Despesa criada com sucesso.');
  });

  testWidgets('shows backend validation feedback on form', (tester) async {
    final repository = FakeExpensesRepository(
      createError: fakeApiException(
        message: 'Request validation failed',
        fieldErrors: const {'description': 'Descricao ja utilizada.'},
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
    await tester.tap(find.text('Criar despesa'));
    await tester.pumpAndSettle();

    expect(find.text('Request validation failed'), findsOneWidget);
    expect(find.text('Descricao ja utilizada.'), findsOneWidget);
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

    await tester.tap(find.byType(TextFormField).at(0));
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
}
