import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/history_imports/domain/history_import_payment_method.dart';
import 'package:despesas_frontend/features/history_imports/presentation/history_import_form_screen.dart';
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
    FakeHistoryImportsRepository? historyImportsRepository,
    FakeExpensesRepository? expensesRepository,
    SessionController? sessionController,
    Size? logicalSize,
    double devicePixelRatio = 1,
    double? textScaleFactor,
  }) async {
    if (logicalSize != null) {
      tester.view.physicalSize = Size(
        logicalSize.width * devicePixelRatio,
        logicalSize.height * devicePixelRatio,
      );
      tester.view.devicePixelRatio = devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    if (textScaleFactor != null) {
      tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
    }

    final controller =
        sessionController ??
        SessionController(
          authRepository: FakeAuthRepository(loginResult: fakeSession()),
          sessionStore: MemorySessionStore(),
        );
    await controller.login(email: 'user@example.com', password: 'password');

    await tester.pumpWidget(
      MaterialApp(
        home: HistoryImportFormScreen(
          historyImportsRepository:
              historyImportsRepository ?? FakeHistoryImportsRepository(),
          expensesRepository: expensesRepository ?? FakeExpensesRepository(),
          sessionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectPaymentMethod(
    WidgetTester tester, {
    String label = 'PIX',
  }) async {
    await scrollTo(
      tester,
      find.byKey(
        const ValueKey('history-import-form-payment-method-field-none'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('history-import-form-payment-method-field-none'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> fillEntry(
    WidgetTester tester,
    int index, {
    required String description,
    required String amount,
    String category = 'Casa',
    String subcategory = 'Internet',
    String? notes,
  }) async {
    await scrollTo(
      tester,
      find.byKey(ValueKey('history-import-entry-$index-description-field')),
    );
    await tester.enterText(
      find.byKey(ValueKey('history-import-entry-$index-description-field')),
      description,
    );
    await tester.enterText(
      find.byKey(ValueKey('history-import-entry-$index-amount-field')),
      amount,
    );

    await tester.tap(
      find.byKey(ValueKey('history-import-entry-$index-category-field-none')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(category).last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        ValueKey('history-import-entry-$index-subcategory-field-none'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(subcategory).last, warnIfMissed: false);
    await tester.pumpAndSettle();

    if (notes != null) {
      await tester.enterText(
        find.byKey(ValueKey('history-import-entry-$index-notes-field')),
        notes,
      );
    }
  }

  testWidgets('nao estoura layout na coleta guiada em largura mobile', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      logicalSize: const Size(360, 800),
      textScaleFactor: 1.2,
    );

    expect(
      find.byKey(
        const ValueKey('history-import-form-payment-method-field-none'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'coleta guiada permite adicionar e remover itens antes da revisao',
    (tester) async {
      await pumpScreen(tester);

      await selectPaymentMethod(tester);
      await fillEntry(
        tester,
        0,
        description: 'Mercado de fevereiro',
        amount: '189,90',
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-add-entry-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-add-entry-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('history-import-entry-1-description-field')),
        findsOneWidget,
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-entry-1-remove-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-entry-1-remove-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('history-import-entry-1-description-field')),
        findsNothing,
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-form-continue-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-form-continue-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('history-import-review-panel')),
        findsOneWidget,
      );
      expect(find.text('Revise antes de confirmar.'), findsOneWidget);
      expect(find.text('Mercado de fevereiro'), findsOneWidget);
      expect(find.text('PIX'), findsWidgets);
    },
  );

  testWidgets(
    'duplicar ultimo item reaproveita a serie simples e avanca um mes',
    (tester) async {
      await pumpScreen(tester);

      await selectPaymentMethod(tester, label: 'Credito');
      await fillEntry(
        tester,
        0,
        description: 'Internet janeiro',
        amount: '129,90',
        notes: 'serie simples',
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-duplicate-entry-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-duplicate-entry-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('history-import-entry-1-description-field')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(
                const ValueKey('history-import-entry-1-description-field'),
              ),
            )
            .controller
            ?.text,
        'Internet janeiro',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('history-import-entry-1-amount-field')),
            )
            .controller
            ?.text,
        '129,90',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('history-import-entry-1-notes-field')),
            )
            .controller
            ?.text,
        'serie simples',
      );
      expect(
        find.byKey(const ValueKey('history-import-entry-1-category-field-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('history-import-entry-1-subcategory-field-11'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('paymentMethod ausente impede avancar para a revisao', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fillEntry(
      tester,
      0,
      description: 'Mercado de fevereiro',
      amount: '189,90',
    );

    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione a forma de pagamento do lote.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('history-import-review-panel')),
      findsNothing,
    );
  });

  testWidgets('POST bem-sucedido mostra o estado final de sucesso', (
    tester,
  ) async {
    final repository = FakeHistoryImportsRepository(
      importResult: fakeHistoryImportResult(
        importedCount: 2,
        entries: [
          fakeHistoryImportEntryRecord(
            expenseId: 10,
            paymentId: 100,
            description: 'Mercado de fevereiro',
            amount: 189.9,
            date: DateTime.utc(2026, 2, 14),
          ),
          fakeHistoryImportEntryRecord(
            expenseId: 11,
            paymentId: 101,
            description: 'Combustivel de fevereiro',
            amount: 240,
            date: DateTime.utc(2026, 2, 15),
          ),
        ],
      ),
    );

    await pumpScreen(tester, historyImportsRepository: repository);

    await selectPaymentMethod(tester, label: 'Transferencia');
    await fillEntry(
      tester,
      0,
      description: 'Mercado de fevereiro',
      amount: '189,90',
    );

    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-add-entry-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-add-entry-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    await fillEntry(
      tester,
      1,
      description: 'Combustivel de fevereiro',
      amount: '240,00',
      category: 'Veiculo',
      subcategory: 'Combustivel',
      notes: 'abastecimento do inicio do mes',
    );

    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(repository.importCalls, 1);
    expect(
      repository.lastImportInput?.paymentMethod,
      HistoryImportPaymentMethod.transferencia,
    );
    expect(repository.lastImportInput?.entries.length, 2);
    expect(
      repository.lastImportInput?.entries[1].notes,
      'abastecimento do inicio do mes',
    );
    expect(
      find.byKey(const ValueKey('history-import-success-card')),
      findsOneWidget,
    );
    expect(find.text('Histórico importado'), findsOneWidget);
    expect(find.text('Importar outro lote'), findsOneWidget);
  });

  testWidgets('fieldErrors indexados do backend voltam para a coleta', (
    tester,
  ) async {
    final repository = FakeHistoryImportsRepository(
      importError: fakeApiException(
        message: 'History import validation failed',
        fieldErrors: const {
          'entries[1].description': 'Use uma descricao mais clara.',
        },
      ),
    );

    await pumpScreen(tester, historyImportsRepository: repository);

    await selectPaymentMethod(tester);
    await fillEntry(
      tester,
      0,
      description: 'Mercado de fevereiro',
      amount: '189,90',
    );
    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-add-entry-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-add-entry-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await fillEntry(tester, 1, description: 'Despesa confusa', amount: '50,00');

    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-form-continue-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-form-continue-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await scrollTo(
      tester,
      find.byKey(const ValueKey('history-import-review-confirm-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('history-import-review-confirm-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history-import-entry-1-description-field')),
      findsOneWidget,
    );
    expect(find.text('History import validation failed'), findsOneWidget);
    expect(find.text('Use uma descricao mais clara.'), findsOneWidget);
  });

  testWidgets(
    'incompatibilidade entre categoria e subcategoria volta para a coleta',
    (tester) async {
      final repository = FakeHistoryImportsRepository(
        importError: fakeApiException(
          message: 'subcategoryId must belong to the informed category',
          fieldErrors: const {
            'entries[0].subcategoryId':
                'subcategoryId must belong to the informed category',
          },
        ),
      );

      await pumpScreen(tester, historyImportsRepository: repository);

      await selectPaymentMethod(tester, label: 'Credito');
      await fillEntry(
        tester,
        0,
        description: 'Mercado de fevereiro',
        amount: '189,90',
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-form-continue-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-form-continue-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.byKey(const ValueKey('history-import-review-confirm-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('history-import-review-confirm-button')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('history-import-entry-0-subcategory-field-11'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('subcategoryId must belong to the informed category'),
        findsWidgets,
      );
    },
  );
}
