import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:despesas_frontend/main.dart' as app;

const _adminEmail = String.fromEnvironment('PROOF_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('PROOF_ADMIN_PASSWORD');
const _proofRunId = String.fromEnvironment(
  'PROOF_RUN_ID',
  defaultValue: 'password-proof',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('executa a prova fim a fim do fluxo oficial de senha', (
    tester,
  ) async {
    _assertDefines();

    final ownerEmail = 'password-proof-$_proofRunId@local.invalid';
    final initialPassword = 'Start-${_proofRunId.substring(0, 4)}-123';
    final changedPassword = 'Changed-${_proofRunId.substring(0, 4)}-456';
    final resetPassword = 'Reset-${_proofRunId.substring(0, 4)}-789';

    app.main();
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: _adminEmail, password: _adminPassword);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('platform-admin-open-change-password-button')),
    );
    await binding.takeScreenshot('01-admin-home');

    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-household-name-field')),
      'Casa Password $_proofRunId',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-owner-name-field')),
      'Owner Password Proof',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-owner-email-field')),
      ownerEmail,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-owner-password-field')),
      initialPassword,
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('platform-admin-submit-button')),
    );
    await _pumpUntilVisible(
      tester,
      find.text('Household e owner criados com sucesso.'),
    );
    await binding.takeScreenshot('02-admin-created-owner');

    await _tap(tester, find.byTooltip('Sair'));
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: ownerEmail, password: initialPassword);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('expenses-security-button')),
    );
    await binding.takeScreenshot('03-owner-home');

    await _tap(tester, find.byKey(const ValueKey('expenses-security-button')));
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('change-password-screen')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-current-field')),
      initialPassword,
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-new-field')),
      changedPassword,
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-confirmation-field')),
      changedPassword,
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('change-password-submit-button')),
    );
    await _pumpUntilVisible(tester, find.text('Senha atualizada'));
    await binding.takeScreenshot('04-owner-password-changed');
    await _tap(
      tester,
      find.byKey(const ValueKey('change-password-success-close-button')),
    );
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: ownerEmail, password: initialPassword);
    await _pumpUntilVisible(tester, find.text('Authentication failed'));
    await binding.takeScreenshot('05-old-password-rejected');

    await _login(tester, email: ownerEmail, password: changedPassword);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('expenses-security-button')),
    );
    await binding.takeScreenshot('06-owner-login-with-new-password');
    await _tap(tester, find.byTooltip('Sair'));
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: _adminEmail, password: _adminPassword);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      ownerEmail,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-new-password-field')),
      resetPassword,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-confirm-password-field')),
      resetPassword,
    );
    await _tap(
      tester,
      find.byKey(const ValueKey('platform-admin-reset-submit-button')),
    );
    await _pumpUntilVisible(tester, find.text('Senha resetada com sucesso.'));
    await binding.takeScreenshot('07-admin-reset-owner-password');

    await _tap(tester, find.byTooltip('Sair'));
    await _pumpUntilVisible(tester, find.text('Entrar'));

    await _login(tester, email: ownerEmail, password: changedPassword);
    await _pumpUntilVisible(tester, find.text('Authentication failed'));
    await binding.takeScreenshot('08-reset-invalidated-previous-password');

    await _login(tester, email: ownerEmail, password: resetPassword);
    await _pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('expenses-security-button')),
    );
    await binding.takeScreenshot('09-owner-login-after-admin-reset');
  });
}

void _assertDefines() {
  final requiredValues = <String, String>{
    'PROOF_ADMIN_EMAIL': _adminEmail,
    'PROOF_ADMIN_PASSWORD': _adminPassword,
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
  }

  throw TimeoutException(
    'Timed out waiting for ${finder.describeMatch(Plurality.many)} after ${timeout.inSeconds}s',
  );
}

class TimeoutException implements Exception {
  TimeoutException(this.message);

  final String message;

  @override
  String toString() => message;
}
