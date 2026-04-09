import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_shell_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_doubles.dart';

void main() {
  testWidgets('menu autenticado permanece utilizável em largura estreita', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sessionController = SessionController(
      authRepository: FakeAuthRepository(loginResult: fakeSession()),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'teste@teste.com',
      password: 'teste123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthenticatedShellScaffold(
          sessionController: sessionController,
          currentLocation: '/expenses/new',
          title: 'Lançar despesa',
          fallbackRoute: '/',
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('authenticated-top-bar-menu-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('authenticated-top-bar-menu-item-/expenses')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('authenticated-top-bar-menu-item-/reports')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
