import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:despesas_frontend/main.dart' as app;

const _ownerEmail = String.fromEnvironment('PROOF_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('PROOF_OWNER_PASSWORD');
const _memberEmail = String.fromEnvironment('PROOF_MEMBER_EMAIL');
const _memberPassword = String.fromEnvironment('PROOF_MEMBER_PASSWORD');
const _proofRunId = String.fromEnvironment(
  'PROOF_RUN_ID',
  defaultValue: 'local-proof',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('executa a prova local web fim a fim', (tester) async {
    _assertDefines();

    app.main();
    await _pumpUntilVisible(tester, find.text('Entrar'));
    await _expectNoFlutterErrors(tester);

    const memberName = 'Member Prova';
    final expenseDescription = 'Despesa prova $_proofRunId';

    await _login(tester, email: _ownerEmail, password: _ownerPassword);
    await _waitForHomeScreen(
      tester,
      binding,
      screenshotName: 'owner-home-timeout',
    );
    await _pumpUntilVisible(
      tester,
      find.text('Nenhuma despesa encontrada'),
      timeout: const Duration(seconds: 20),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('01-owner-home-empty');

    await _tap(tester, find.byKey(const ValueKey('expenses-members-button')));
    await _pumpUntilVisible(tester, find.text('Fluxo minimo multiusuario'));
    await tester.enterText(
      find.byKey(const ValueKey('household-member-name-field')),
      memberName,
    );
    await tester.enterText(
      find.byKey(const ValueKey('household-member-email-field')),
      _memberEmail,
    );
    await tester.enterText(
      find.byKey(const ValueKey('household-member-password-field')),
      _memberPassword,
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('household-member-submit-button')),
    );
    await _pumpUntilVisible(tester, find.text(_memberEmail));
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('02-owner-member-created');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tap(
      tester,
      find.byKey(const ValueKey('expenses-new-expense-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.text('Antes de lancar, confirme o tipo certo'),
    );
    await _tap(tester, find.text('Historico'));
    await _pumpUntilVisible(tester, find.text('Trazer meu histórico'));
    await _tap(
      tester,
      find.byKey(
        const ValueKey('history-import-form-payment-method-field-none'),
      ),
    );
    await _tap(tester, find.text('PIX').last);
    await tester.enterText(
      find.byKey(const ValueKey('history-import-entry-0-description-field')),
      'Internet janeiro $_proofRunId',
    );
    await tester.enterText(
      find.byKey(const ValueKey('history-import-entry-0-amount-field')),
      '129,90',
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('history-import-entry-0-category-field-none')),
    );
    await _tap(tester, _historyCategoryFinder());
    await _tap(
      tester,
      find.byKey(
        const ValueKey('history-import-entry-0-subcategory-field-none'),
      ),
    );
    await _tap(tester, find.text('Internet').last);
    await _tap(
      tester,
      find.byKey(const ValueKey('history-import-duplicate-entry-button')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('history-import-entry-1-description-field')),
      'Internet fevereiro $_proofRunId',
    );
    await tester.enterText(
      find.byKey(const ValueKey('history-import-entry-1-amount-field')),
      '139,90',
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('history-import-form-continue-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('history-import-review-panel')),
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('history-import-review-confirm-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('history-import-success-card')),
      timeout: const Duration(seconds: 20),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('03-owner-history-import-success');
    await _tap(tester, find.text('Ver despesas importadas'));
    await _waitForHomeScreen(
      tester,
      binding,
      screenshotName: 'owner-home-after-history-timeout',
    );
    await _pumpUntilVisible(
      tester,
      find.text('Internet fevereiro $_proofRunId'),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('04-owner-home-after-history');

    await _tap(
      tester,
      find.byKey(const ValueKey('expenses-new-expense-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('expense-form-description-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-description-field')),
      expenseDescription,
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-amount-field')),
      '149,90',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-form-notes-field')),
      'Criada na prova local $_proofRunId',
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('expense-form-submit-button')),
    );
    await _pumpUntilVisible(tester, find.text(expenseDescription));
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('05-owner-expense-created');

    await _tap(tester, find.text(expenseDescription));
    await _pumpUntilVisible(tester, find.text('Detalhe da despesa'));
    await tester.enterText(
      find.byKey(const ValueKey('expense-payment-amount-field')),
      '49,90',
    );
    await tester.enterText(
      find.byKey(const ValueKey('expense-payment-notes-field')),
      'Pagamento parcial da prova',
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('expense-payment-submit-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.text('Pagamento registrado com sucesso.'),
      timeout: const Duration(seconds: 20),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('06-owner-payment-registered');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('expenses-reports-button')));
    await _pumpUntilVisible(
      tester,
      find.text('Leitura clara do mes financeiro'),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('07-owner-reports');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('expenses-assistant-button')));
    await _pumpUntilVisible(
      tester,
      find.text('Assistente financeiro do seu espaço'),
    );
    await tester.enterText(
      find.byKey(const ValueKey('assistant-question-field')),
      'Onde estou gastando mais neste mes?',
    );
    await _tap(tester, find.byKey(const ValueKey('assistant-submit-button')));
    await _pumpUntilVisible(tester, find.text('Resposta do assistente'));
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('08-owner-assistant');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tap(tester, find.byTooltip('Sair'));
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: _memberEmail, password: _memberPassword);
    await _waitForHomeScreen(
      tester,
      binding,
      screenshotName: 'member-home-timeout',
    );
    expect(find.byKey(const ValueKey('expenses-members-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('expenses-review-operations-button')),
      findsNothing,
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('09-member-home');
  });
}

void _assertDefines() {
  final requiredValues = <String, String>{
    'PROOF_OWNER_EMAIL': _ownerEmail,
    'PROOF_OWNER_PASSWORD': _ownerPassword,
    'PROOF_MEMBER_EMAIL': _memberEmail,
    'PROOF_MEMBER_PASSWORD': _memberPassword,
  };

  final missing = requiredValues.entries
      .where((entry) => entry.value.isEmpty)
      .map((entry) => entry.key)
      .toList(growable: false);

  if (missing.isNotEmpty) {
    throw StateError('Missing required dart defines: ${missing.join(', ')}');
  }
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('login-email-field')),
  );
  await tester.enterText(
    find.byKey(const ValueKey('login-email-field')),
    email,
  );
  await tester.enterText(
    find.byKey(const ValueKey('login-password-field')),
    password,
  );
  await _tap(tester, find.byKey(const ValueKey('login-submit-button')));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _pumpUntilVisible(tester, finder);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Finder _historyCategoryFinder() {
  final moradia = find.text('Moradia').last;
  if (moradia.evaluate().isNotEmpty) {
    return moradia;
  }
  return find.text('Casa').last;
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    final exception = tester.takeException();
    if (exception != null) {
      throw exception;
    }
  }
  throw TestFailure(
    'Timed out waiting for ${finder.describeMatch(Plurality.many)}',
  );
}

Future<void> _waitForHomeScreen(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  required String screenshotName,
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final homeFinder = find.byKey(const ValueKey('expenses-new-expense-button'));
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (homeFinder.evaluate().isNotEmpty) {
      return;
    }
    final exception = tester.takeException();
    if (exception != null) {
      throw exception;
    }
  }

  await binding.takeScreenshot(screenshotName);
  final visibleTexts = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget as Text)
      .map((widget) => widget.data?.trim() ?? '')
      .where((text) => text.isNotEmpty)
      .toSet()
      .toList(growable: false);

  throw TestFailure(
    'Timed out waiting for home screen. Visible texts: ${visibleTexts.join(' | ')}',
  );
}

Future<void> _expectNoFlutterErrors(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  final exception = tester.takeException();
  expect(exception, isNull);
}
