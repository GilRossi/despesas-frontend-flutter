import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/config/app_environment.dart';
import 'package:despesas_frontend/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureSmallViewport(WidgetTester tester, {double bottomInset = 0}) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 640);
    tester.view.viewInsets = FakeViewPadding(bottom: bottomInset);
    addTearDown(tester.view.reset);
  }

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
    expect(find.textContaining('cadastro', findRichText: true), findsNothing);
  });

  testWidgets('stays usable with keyboard open on small heights', (
    tester,
  ) async {
    configureSmallViewport(tester, bottomInset: 320);

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

    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows auth error on small heights without overflow', (
    tester,
  ) async {
    configureSmallViewport(tester, bottomInset: 320);

    final controller = SessionController(
      authRepository: FakeAuthRepository(
        loginError: fakeApiException(
          statusCode: 401,
          message: 'Credenciais invalidas.',
        ),
      ),
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

    await tester.enterText(find.byType(TextFormField).first, 'gil@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'Senha123!');
    final loginButton = find.widgetWithText(FilledButton, 'Entrar');
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(loginButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Credenciais invalidas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
