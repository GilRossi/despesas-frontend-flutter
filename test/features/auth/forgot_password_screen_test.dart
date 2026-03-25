import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/domain/forgot_password_result.dart';
import 'package:despesas_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('submits forgot password and shows neutral confirmation', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(
        forgotPasswordResult: ForgotPasswordResult(
          maskedEmail: 'g***@example.com',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordScreen(sessionController: controller),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('forgot-email-field')),
      'gil@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('g***@example.com'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Se encontrarmos o e-mail'),
      findsOneWidget,
    );
  });
}
