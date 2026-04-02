import 'package:despesas_frontend/app/session_controller.dart';
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
    final controller = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await controller.login(email: 'gil@example.com', password: 'Senha123!');
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/fixed-bills',
          builder: (context, state) => FixedBillsListScreen(
            fixedBillsRepository: repository,
            sessionController: controller,
          ),
        ),
        GoRoute(
          path: '/fixed-bills/new',
          builder: (context, state) => FixedBillFormScreen(
            fixedBillsRepository: repository,
            expensesRepository: FakeExpensesRepository(),
            spaceReferencesRepository: FakeSpaceReferencesRepository(),
          ),
        ),
        GoRoute(
          path: '/fixed-bills/:fixedBillId/edit',
          builder: (context, state) => FixedBillFormScreen(
            fixedBillId: int.tryParse(
              state.pathParameters['fixedBillId'] ?? '',
            ),
            fixedBillsRepository: repository,
            expensesRepository: FakeExpensesRepository(),
            spaceReferencesRepository: FakeSpaceReferencesRepository(),
          ),
        ),
        GoRoute(
          path: '/expenses/:expenseId',
          builder: (context, state) => Scaffold(
            body: Text('Despesa ${state.pathParameters['expenseId']}'),
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
          nextDueDate: DateTime.utc(2026, 4, 5),
          spaceReference: fakeFixedBillReference(
            id: 7,
            name: 'Apartamento Centro',
          ),
        ),
        fakeFixedBillRecord(
          id: 11,
          description: 'Faxina semanal',
          amount: 90,
          nextDueDate: DateTime.utc(2026, 4, 3),
        ),
      ],
    );

    await pumpRouter(tester, repository: repository);

    expect(repository.listCalls, 1);
    expect(
      find.byKey(const ValueKey('fixed-bills-list-item-10')),
      findsOneWidget,
    );
    expect(find.text('Internet fibra'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
    expect(find.text('Mensal'), findsWidgets);
    expect(find.text('Referência Apartamento Centro'), findsOneWidget);
    expect(find.text('Faxina semanal'), findsOneWidget);
    expect(find.text('Lançar despesa'), findsNWidgets(2));
    expect(find.text('Editar regra'), findsNWidgets(2));
    expect(find.text('Excluir regra'), findsNWidgets(2));
  });

  testWidgets('mantem o cabecalho local alinhado ao padrao de Despesas', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(
      listResult: [fakeFixedBillRecord(id: 10, description: 'Internet fibra')],
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpRouter(tester, repository: repository);

    expect(find.text('Contas fixas'), findsOneWidget);
    expect(find.text('Minhas contas fixas'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fixed-bills-list-create-button')),
      findsOneWidget,
    );
    expect(find.text('Contas fixas do espaço atual'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      findsOneWidget,
    );
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

    await tester.tap(
      find.widgetWithText(FilledButton, 'Cadastrar conta fixa').last,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(FixedBillFormScreen), findsOneWidget);
    expect(find.text('Cadastrar conta fixa'), findsWidgets);
  });

  testWidgets('lanca a proxima despesa operacional a partir da regra', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(
      listResult: [
        fakeFixedBillRecord(
          id: 10,
          description: 'Internet fibra',
          lastGeneratedExpense: null,
        ),
      ],
      launchResult: fakeExpense(id: 91, description: 'Internet fibra'),
    );

    await pumpRouter(tester, repository: repository);

    await tester.ensureVisible(
      find.byKey(const ValueKey('fixed-bills-launch-expense-10')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bills-launch-expense-10')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.launchCalls, 1);
    expect(repository.lastLaunchedFixedBillId, 10);
    expect(find.text('Despesa 91'), findsOneWidget);
  });

  testWidgets('abre a edicao da regra a partir da lista', (tester) async {
    final repository = FakeFixedBillsRepository(
      listResult: [fakeFixedBillRecord(id: 10, description: 'Internet fibra')],
      getResult: fakeFixedBillRecord(id: 10, description: 'Internet fibra'),
    );

    await pumpRouter(tester, repository: repository);

    await tester.ensureVisible(
      find.byKey(const ValueKey('fixed-bills-edit-10')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bills-edit-10')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.getCalls, 1);
    expect(find.byType(FixedBillFormScreen), findsOneWidget);
    expect(find.text('Editar conta fixa'), findsOneWidget);
  });
}
