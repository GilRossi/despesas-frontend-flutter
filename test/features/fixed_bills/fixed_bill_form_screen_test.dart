import 'package:despesas_frontend/features/fixed_bills/presentation/fixed_bill_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    FakeFixedBillsRepository? fixedBillsRepository,
    FakeExpensesRepository? expensesRepository,
    FakeSpaceReferencesRepository? spaceReferencesRepository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FixedBillFormScreen(
          fixedBillsRepository:
              fixedBillsRepository ?? FakeFixedBillsRepository(),
          expensesRepository: expensesRepository ?? FakeExpensesRepository(),
          spaceReferencesRepository:
              spaceReferencesRepository ?? FakeSpaceReferencesRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('fixed-bill-form-description-field')),
      'Internet fibra',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fixed-bill-form-amount-field')),
      '129,90',
    );
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-context-field-none')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-context-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-category-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-subcategory-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Internet').last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('coleta guiada avanca para a revisao local', (tester) async {
    await pumpScreen(
      tester,
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(name: 'Projeto Horizonte')],
      ),
    );

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fixed-bill-review-panel')),
      findsOneWidget,
    );
    expect(find.text('Revise antes de confirmar.'), findsOneWidget);
    expect(find.text('Internet fibra'), findsOneWidget);
    expect(find.text('R\$ 129,90'), findsOneWidget);
    expect(find.text('Mensal'), findsOneWidget);
  });

  testWidgets('POST bem-sucedido mostra o estado final de sucesso', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(
      createResult: fakeFixedBillRecord(
        description: 'Internet fibra',
        amount: 129.9,
        spaceReference: fakeFixedBillReference(name: 'Projeto Horizonte'),
      ),
    );

    await pumpScreen(
      tester,
      fixedBillsRepository: repository,
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(id: 7, name: 'Projeto Horizonte')],
      ),
    );

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-space-reference-field-none')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-space-reference-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projeto Horizonte').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.description, 'Internet fibra');
    expect(repository.lastCreatedInput?.amount, 129.9);
    expect(repository.lastCreatedInput?.frequency.apiValue, 'MONTHLY');
    expect(
      find.byKey(const ValueKey('fixed-bill-success-card')),
      findsOneWidget,
    );
    expect(find.text('Conta fixa registrada'), findsOneWidget);
    expect(find.text('Cadastrar outra conta fixa'), findsOneWidget);
  });

  testWidgets('fieldErrors do backend voltam para a etapa de coleta', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(
      createError: fakeApiException(
        message: 'Request validation failed',
        fieldErrors: const {'description': 'Use uma descricao mais clara.'},
      ),
    );

    await pumpScreen(tester, fixedBillsRepository: repository);

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fixed-bill-form-description-field')),
      findsOneWidget,
    );
    expect(find.text('Request validation failed'), findsOneWidget);
    expect(find.text('Use uma descricao mais clara.'), findsOneWidget);
  });

  testWidgets('referencia opcional invalida mostra erro de campo do backend', (
    tester,
  ) async {
    final repository = FakeFixedBillsRepository(
      createError: fakeApiException(
        message: 'spaceReferenceId must belong to the active household',
        fieldErrors: const {
          'spaceReferenceId':
              'spaceReferenceId must belong to the active household',
        },
      ),
    );

    await pumpScreen(
      tester,
      fixedBillsRepository: repository,
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(id: 99, name: 'Projeto Acme')],
      ),
    );

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-space-reference-field-none')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-space-reference-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projeto Acme').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('spaceReferenceId must belong to the active household'),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('fixed-bill-form-space-reference-field-99')),
      findsOneWidget,
    );
  });

  testWidgets(
    'incompatibilidade entre categoria e subcategoria volta para a coleta',
    (tester) async {
      final repository = FakeFixedBillsRepository(
        createError: fakeApiException(
          message: 'subcategoryId does not belong to categoryId',
          fieldErrors: const {
            'subcategoryId': 'subcategoryId does not belong to categoryId',
          },
        ),
      );

      await pumpScreen(tester, fixedBillsRepository: repository);

      await fillRequiredFields(tester);
      await scrollTo(
        tester,
        find.byKey(const ValueKey('fixed-bill-form-continue-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('fixed-bill-form-continue-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('fixed-bill-review-confirm-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fixed-bill-form-subcategory-field-11')),
        findsOneWidget,
      );
      expect(
        find.text('subcategoryId does not belong to categoryId'),
        findsWidgets,
      );
    },
  );
}
