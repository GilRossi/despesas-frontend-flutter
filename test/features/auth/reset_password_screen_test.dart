import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/auth/presentation/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('redefines password successfully with token', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          sessionController: controller,
          token: 'token-123',
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('reset-password-new-field')),
      'SenhaNova123!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password-confirm-field')),
      'SenhaNova123!',
    );

    await tester.tap(find.byKey(const ValueKey('reset-password-submit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Senha atualizada'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('reset-password-success-close-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('shows backend error when token is invalid', (tester) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(
        resetPasswordError: const ApiException(
          statusCode: 401,
          code: 'INVALID_TOKEN',
          message: 'Token invalido ou expirado.',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          sessionController: controller,
          token: 'token-123',
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('reset-password-new-field')),
      'SenhaNova123!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password-confirm-field')),
      'SenhaNova123!',
    );

    await tester.tap(find.byKey(const ValueKey('reset-password-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Token invalido ou expirado.'), findsOneWidget);
  });
}
