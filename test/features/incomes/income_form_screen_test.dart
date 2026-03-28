import 'package:despesas_frontend/features/incomes/presentation/income_form_screen.dart';
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
    FakeIncomesRepository? incomesRepository,
    FakeSpaceReferencesRepository? spaceReferencesRepository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomeFormScreen(
          incomesRepository: incomesRepository ?? FakeIncomesRepository(),
          spaceReferencesRepository:
              spaceReferencesRepository ?? FakeSpaceReferencesRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredFields(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('income-form-description-field')),
      'Freelance de marco',
    );
    await tester.enterText(
      find.byKey(const ValueKey('income-form-amount-field')),
      '1800,00',
    );
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
      find.byKey(const ValueKey('income-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('income-review-panel')), findsOneWidget);
    expect(find.text('Revise antes de confirmar.'), findsOneWidget);
    expect(find.text('Freelance de marco'), findsOneWidget);
    expect(find.text('R\$ 1.800,00'), findsOneWidget);
  });

  testWidgets('POST bem-sucedido mostra o estado final de sucesso', (
    tester,
  ) async {
    final repository = FakeIncomesRepository(
      createResult: fakeIncomeRecord(
        description: 'Freelance de marco',
        amount: 1800,
        spaceReference: fakeIncomeReference(name: 'Projeto Horizonte'),
      ),
    );

    await pumpScreen(
      tester,
      incomesRepository: repository,
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(id: 7, name: 'Projeto Horizonte')],
      ),
    );

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastCreatedInput?.description, 'Freelance de marco');
    expect(repository.lastCreatedInput?.amount, 1800);
    expect(find.byKey(const ValueKey('income-success-card')), findsOneWidget);
    expect(find.text('Ganho registrado'), findsOneWidget);
    expect(find.text('Cadastrar outro ganho'), findsOneWidget);
  });

  testWidgets('fieldErrors do backend voltam para a etapa de coleta', (
    tester,
  ) async {
    final repository = FakeIncomesRepository(
      createError: fakeApiException(
        message: 'Request validation failed',
        fieldErrors: const {'description': 'Use uma descricao mais clara.'},
      ),
    );

    await pumpScreen(tester, incomesRepository: repository);

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('income-form-description-field')),
      findsOneWidget,
    );
    expect(find.text('Request validation failed'), findsOneWidget);
    expect(find.text('Use uma descricao mais clara.'), findsOneWidget);
  });

  testWidgets('referencia opcional invalida mostra erro de campo do backend', (
    tester,
  ) async {
    final repository = FakeIncomesRepository(
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
      incomesRepository: repository,
      spaceReferencesRepository: FakeSpaceReferencesRepository(
        references: [fakeSpaceReferenceItem(id: 99, name: 'Projeto Acme')],
      ),
    );

    await fillRequiredFields(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-form-space-reference-field-none')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-form-space-reference-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projeto Acme').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('income-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('income-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('spaceReferenceId must belong to the active household'),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('income-form-space-reference-field-99')),
      findsOneWidget,
    );
  });
}
