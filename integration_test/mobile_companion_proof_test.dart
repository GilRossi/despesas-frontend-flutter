import 'package:despesas_frontend/main.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _ownerEmail = String.fromEnvironment('PROOF_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('PROOF_OWNER_PASSWORD');
const _proofRunId = String.fromEnvironment(
  'PROOF_RUN_ID',
  defaultValue: 'mobile-proof',
);
const _proofPhase = String.fromEnvironment(
  'PROOF_PHASE',
  defaultValue: 'login-flow',
);
const _proofTextScaleFactorRaw = String.fromEnvironment(
  'PROOF_TEXT_SCALE_FACTOR',
  defaultValue: '1.3',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('executa a prova local do companion mobile', (tester) async {
    _assertDefines();
    final proofTextScaleFactor =
        double.tryParse(_proofTextScaleFactorRaw) ?? 1.3;

    addTearDown(tester.platformDispatcher.clearAllTestValues);
    tester.platformDispatcher.textScaleFactorTestValue = proofTextScaleFactor;

    app.main();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
    }

    await tester.pumpAndSettle();

    final startupState = await _waitForStartupState(tester);
    if (_proofPhase == 'login-flow') {
      await _runLoginFlow(tester, binding, startupState);
    } else if (_proofPhase == 'restore-session') {
      await _runRestoreSessionFlow(tester, binding, startupState);
    } else {
      throw StateError('Unsupported PROOF_PHASE: $_proofPhase');
    }

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!.addAll(<String, dynamic>{
      'phase': _proofPhase,
      'runId': _proofRunId,
      'startupState': startupState.name,
      'textScaleFactor': proofTextScaleFactor,
      'device': <String, dynamic>{
        'platform': defaultTargetPlatform.name,
        'logicalWidth':
            tester.view.physicalSize.width / tester.view.devicePixelRatio,
        'logicalHeight':
            tester.view.physicalSize.height / tester.view.devicePixelRatio,
        'devicePixelRatio': tester.view.devicePixelRatio,
      },
    });
  });
}

Future<void> _runLoginFlow(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  _StartupState startupState,
) async {
  if (startupState == _StartupState.home ||
      startupState == _StartupState.platformAdmin) {
    await _logoutFromAuthenticatedSurface(tester);
  }

  await _login(tester, email: _ownerEmail, password: _ownerPassword);
  await _waitForHomeScreen(tester);
  await _expectNoFlutterErrors(tester);
  await binding.takeScreenshot('01-mobile-home-after-login');

  final expenseDescription = 'Despesa mobile $_proofRunId';

  await _tap(tester, find.byKey(const ValueKey('expenses-new-expense-button')));
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
    'Criada na prova mobile $_proofRunId',
  );
  await _expectNoFlutterErrors(tester);
  await binding.takeScreenshot('02-mobile-expense-form');
  await _tap(tester, find.byKey(const ValueKey('expense-form-submit-button')));
  await _pumpUntilVisible(tester, find.text(expenseDescription));
  await _expectNoFlutterErrors(tester);
  await binding.takeScreenshot('03-mobile-expense-created');

  await _tap(tester, find.text(expenseDescription));
  await _pumpUntilVisible(tester, find.text('Detalhe da despesa'));
  await tester.enterText(
    find.byKey(const ValueKey('expense-payment-amount-field')),
    '49,90',
  );
  await tester.enterText(
    find.byKey(const ValueKey('expense-payment-notes-field')),
    'Pagamento mobile $_proofRunId',
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
  await binding.takeScreenshot('04-mobile-expense-payment');
  await tester.pageBack();
  await tester.pumpAndSettle();

  await _tap(tester, find.byKey(const ValueKey('expenses-reports-button')));
  await _pumpUntilVisible(tester, find.text('Leitura clara do mes financeiro'));
  await tester.pumpAndSettle();
  await _expectNoFlutterErrors(tester);
  await binding.takeScreenshot('05-mobile-reports');
  await tester.pageBack();
  await tester.pumpAndSettle();

  await _tap(tester, find.byTooltip('Assistente financeiro'));
  final assistantQuestionField = find.byKey(
    const ValueKey('assistant-question-field'),
  );
  await _pumpUntilVisible(tester, assistantQuestionField);
  await tester.ensureVisible(assistantQuestionField);
  await tester.pumpAndSettle();
  await tester.enterText(
    assistantQuestionField,
    'Onde estou gastando mais neste mes?',
  );
  await _tap(tester, find.byKey(const ValueKey('assistant-submit-button')));
  await _pumpUntilVisible(tester, find.text('Resposta do assistente'));
  await _expectNoFlutterErrors(tester);
  await binding.takeScreenshot('06-mobile-assistant');
}

Future<void> _runRestoreSessionFlow(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  _StartupState startupState,
) async {
  if (startupState == _StartupState.home) {
    await _waitForHomeScreen(tester);
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('07-mobile-restored-session');
    return;
  }

  if (startupState == _StartupState.login) {
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('login-submit-button')),
    );
    await _expectNoFlutterErrors(tester);
    await binding.takeScreenshot('07-mobile-session-restart-login');
    return;
  }

  throw TestFailure(
    'Unexpected startup state during mobile restore phase: $startupState.',
  );
}

void _assertDefines() {
  final requiredValues = <String, String>{
    'PROOF_OWNER_EMAIL': _ownerEmail,
    'PROOF_OWNER_PASSWORD': _ownerPassword,
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

Future<void> _logoutFromAuthenticatedSurface(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('Sair'));
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('login-submit-button')),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _pumpUntilVisible(tester, finder);
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
}

Future<void> _waitForHomeScreen(WidgetTester tester) async {
  await _pumpUntilVisible(
    tester,
    find.byKey(const ValueKey('expenses-new-expense-button')),
    timeout: const Duration(seconds: 30),
  );
}

Future<_StartupState> _waitForStartupState(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find
        .byKey(const ValueKey('login-submit-button'))
        .evaluate()
        .isNotEmpty) {
      return _StartupState.login;
    }
    if (find
        .byKey(const ValueKey('expenses-new-expense-button'))
        .evaluate()
        .isNotEmpty) {
      return _StartupState.home;
    }
    if (find
        .byKey(const ValueKey('platform-admin-submit-button'))
        .evaluate()
        .isNotEmpty) {
      return _StartupState.platformAdmin;
    }
    final exception = tester.takeException();
    if (exception != null) {
      throw exception;
    }
  }

  throw TestFailure('Timed out waiting for mobile startup state.');
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

Future<void> _expectNoFlutterErrors(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  final exception = tester.takeException();
  expect(exception, isNull);
}

enum _StartupState { login, home, platformAdmin }
