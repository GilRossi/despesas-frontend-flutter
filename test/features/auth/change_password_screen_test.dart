import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('changes the current user password and logs out afterwards', (
    tester,
  ) async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'owner@local.invalid',
      password: 'SenhaAtual123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(sessionController: sessionController),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('change-password-current-field')),
      'SenhaAtual123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-new-field')),
      'SenhaNova456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-confirmation-field')),
      'SenhaNova456',
    );

    await tester.tap(
      find.byKey(const ValueKey('change-password-submit-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Senha atualizada'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('change-password-success-close-button')),
    );
    await tester.pumpAndSettle();

    expect(sessionController.status, SessionStatus.unauthenticated);
  });

  testWidgets('shows backend validation error when password change fails', (
    tester,
  ) async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        changePasswordError: fakeApiException(
          statusCode: 401,
          message: 'Authentication failed',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'owner@local.invalid',
      password: 'SenhaAtual123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(sessionController: sessionController),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('change-password-current-field')),
      'SenhaAtual123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-new-field')),
      'SenhaNova456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-confirmation-field')),
      'SenhaNova456',
    );

    await tester.tap(
      find.byKey(const ValueKey('change-password-submit-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Authentication failed'), findsOneWidget);
    expect(sessionController.status, SessionStatus.authenticated);
  });
}
