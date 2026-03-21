import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('shows validation messages for invalid credentials', (
    tester,
  ) async {
    final controller = SessionController(
      authRepository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          sessionController: controller,
          environment: AppEnvironment(
            name: 'test',
            apiBaseUrl: Uri.parse('http://localhost:8080'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'email-invalido');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail valido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });
}
