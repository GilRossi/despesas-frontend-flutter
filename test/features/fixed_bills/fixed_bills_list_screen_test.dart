import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bills_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_doubles.dart';

void main() {
  Future<void> pumpRouter(
    WidgetTester tester, {
    required FakeFixedBillsRepository repository,
    String initialLocation = '/fixed-bills',
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/fixed-bills',
          builder: (context, state) =>
              FixedBillsListScreen(fixedBillsRepository: repository),
        ),
        GoRoute(
          path: '/fixed-bills/new',
          builder: (context, state) => FixedBillFormScreen(
            fixedBillsRepository: repository,
            expensesRepository: FakeExpensesRepository(),
            spaceReferencesRepository: FakeSpaceReferencesRepository(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('carrega e exibe as contas fixas ja cadastradas', (tester) async {
    final repository = FakeFixedBillsRepository(
      listResult: [
        fakeFixedBillRecord(
          id: 10,
          description: 'Internet fibra',
          amount: 129.9,
          spaceReference: fakeFixedBillReference(
            id: 7,
            name: 'Apartamento Centro',
          ),
        ),
        fakeFixedBillRecord(
          id: 11,
          description: 'Faxina semanal',
          amount: 90,
        ),
      ],
    );

    await pumpRouter(tester, repository: repository);

    expect(repository.listCalls, 1);
    expect(find.byKey(const ValueKey('fixed-bills-list-item-10')), findsOneWidget);
    expect(find.text('Internet fibra'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
    expect(find.text('Mensal'), findsWidgets);
    expect(find.text('Referencia Apartamento Centro'), findsOneWidget);
    expect(find.text('Faxina semanal'), findsOneWidget);
  });

  testWidgets('estado vazio orienta para cadastrar a primeira conta fixa', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(listResult: const []);

    await pumpRouter(tester, repository: repository);

    expect(
      find.byKey(const ValueKey('fixed-bills-list-empty-card')),
      findsOneWidget,
    );
    expect(find.text('Nenhuma conta fixa cadastrada ainda'), findsOneWidget);

    await tester.tap(find.text('Cadastrar conta fixa'));
    await tester.pumpAndSettle();

    expect(find.byType(FixedBillFormScreen), findsOneWidget);
    expect(find.text('Cadastrar minhas contas fixas'), findsWidgets);
  });
}
