import 'dart:async';

import 'package:despesas_frontend/features/expenses/presentation/expense_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_doubles.dart';

void main() {
  Future<void> pumpPaymentFlow(
    WidgetTester tester, {
    required FakeExpensesRepository repository,
    String initialLocation = '/expenses/1/pay',
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('dashboard-page')),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) =>
              const Scaffold(body: Text('expenses-page')),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) =>
              const Scaffold(body: Text('assistant-page')),
        ),
        GoRoute(
          path: '/expenses/:expenseId/pay',
          builder: (context, state) => ExpensePaymentScreen(
            expenseId: int.parse(state.pathParameters['expenseId']!),
            expensesRepository: repository,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('prefills amount with remaining balance and submits quickly', (
    tester,
  ) async {
    late final FakeExpensesRepository repository;
    repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 89.9,
        paymentsCount: 1,
      ),
      onRegisterPayment: (input) {
        repository.detailResult = fakeExpenseDetail(
          paidAmount: 129.9,
          remainingAmount: 0,
          paymentsCount: 2,
          payments: [
            fakeExpensePayment(id: 9, amount: input.amount, notes: input.notes),
            fakeExpensePayment(),
          ],
        );
      },
    );

    await pumpPaymentFlow(tester, repository: repository);

    final amountField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('expense-payment-amount-field')),
    );
    expect(amountField.controller?.text, '89,90');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.registerPaymentCalls, 1);
    expect(repository.lastPaymentInput?.amount, 89.9);
    expect(find.text('Despesa quitada com sucesso'), findsOneWidget);
  });

  testWidgets('allows editing the amount up to the remaining balance', (
    tester,
  ) async {
    late final FakeExpensesRepository repository;
    repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 89.9,
        paymentsCount: 1,
      ),
      onRegisterPayment: (input) {
        repository.detailResult = fakeExpenseDetail(
          paidAmount: 89.9,
          remainingAmount: 40,
          paymentsCount: 2,
          payments: [
            fakeExpensePayment(id: 9, amount: input.amount, notes: input.notes),
            fakeExpensePayment(),
          ],
        );
      },
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('expense-payment-amount-field')),
      '49,90',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.lastPaymentInput?.amount, 49.9);
    expect(find.text('Pagamento registrado com sucesso'), findsOneWidget);
    expect(find.textContaining('Restam R\$ 40,00 em aberto.'), findsOneWidget);
  });

  testWidgets('shows validation when amount exceeds remaining balance', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 20,
        paymentsCount: 1,
      ),
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('expense-payment-amount-field')),
      '25',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('O valor nao pode ser maior que o saldo restante.'),
      findsOneWidget,
    );
    expect(repository.registerPaymentCalls, 0);
  });

  testWidgets('success CTA can return to expenses management', (tester) async {
    late final FakeExpensesRepository repository;
    repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 89.9,
        paymentsCount: 1,
      ),
      onRegisterPayment: (input) {
        repository.detailResult = fakeExpenseDetail(
          paidAmount: 129.9,
          remainingAmount: 0,
          paymentsCount: 2,
        );
      },
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-success-open-expenses')),
    );
    await tester.pumpAndSettle();

    expect(find.text('expenses-page'), findsOneWidget);
  });

  testWidgets('success CTA can return to dashboard', (tester) async {
    late final FakeExpensesRepository repository;
    repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 40,
        remainingAmount: 89.9,
        paymentsCount: 1,
      ),
      onRegisterPayment: (input) {
        repository.detailResult = fakeExpenseDetail(
          paidAmount: 129.9,
          remainingAmount: 0,
          paymentsCount: 2,
        );
      },
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-success-open-dashboard')),
    );
    await tester.pumpAndSettle();

    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('shows not found state when the expense does not exist', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailError: fakeApiException(
        statusCode: 404,
        message: 'Despesa nao encontrada',
      ),
    );

    await pumpPaymentFlow(tester, repository: repository);

    expect(find.text('Despesa nao encontrada'), findsOneWidget);
    expect(find.text('Ver despesas'), findsOneWidget);
    expect(find.text('Voltar ao dashboard'), findsOneWidget);
    expect(
      find.textContaining('Nao foi possivel abrir este pagamento'),
      findsOneWidget,
    );
  });

  testWidgets('not found state can return to expenses list', (tester) async {
    final repository = FakeExpensesRepository(
      detailError: fakeApiException(
        statusCode: 404,
        message: 'Despesa nao encontrada',
      ),
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.tap(find.text('Ver despesas'));
    await tester.pumpAndSettle();

    expect(find.text('expenses-page'), findsOneWidget);
  });

  testWidgets('already paid state keeps exit actions visible', (tester) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 129.9,
        remainingAmount: 0,
        paymentsCount: 2,
      ),
    );

    await pumpPaymentFlow(tester, repository: repository);

    expect(find.text('Despesa ja quitada'), findsOneWidget);
    expect(find.text('Ver despesas'), findsOneWidget);
    expect(find.text('Voltar ao dashboard'), findsOneWidget);
  });

  testWidgets('already paid state can return to dashboard', (tester) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(
        paidAmount: 129.9,
        remainingAmount: 0,
        paymentsCount: 2,
      ),
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.tap(find.text('Voltar ao dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('shows retry state when loading the payment flow fails', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailError: fakeApiException(message: 'Falha simulada'),
    );

    await pumpPaymentFlow(tester, repository: repository);

    expect(
      find.text('Nao foi possivel abrir o fluxo de pagamento.'),
      findsOneWidget,
    );
    expect(find.text('Falha simulada'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('shows generic submit error when payment fails unexpectedly', (
    tester,
  ) async {
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(remainingAmount: 89.9),
      registerPaymentError: Exception('falha inesperada'),
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nao foi possivel registrar o pagamento.'),
      findsOneWidget,
    );
    expect(find.text('Despesa quitada com sucesso'), findsNothing);
  });

  testWidgets('shows loading feedback while submit is still pending', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = FakeExpensesRepository(
      detailResult: fakeExpenseDetail(remainingAmount: 89.9),
      onRegisterPaymentAsync: (_) => completer.future,
    );

    await pumpPaymentFlow(tester, repository: repository);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('expense-payment-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('expense-payment-submit-button')),
          )
          .onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();
  });
}
