import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  testWidgets('submits household and owner provisioning successfully', (
    tester,
  ) async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          role: 'PLATFORM_ADMIN',
          householdId: null,
          email: 'admin@local.invalid',
          name: 'Platform Admin',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(email: 'admin@local.invalid', password: 'senha123');
    final repository = FakePlatformAdminRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do household'),
      'Casa Controlada',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do owner'),
      'Owner Controlado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email do owner'),
      'owner@local.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha inicial do owner'),
      'senha123',
    );
    final submitButton = find.widgetWithText(
      FilledButton,
      'Criar household + owner',
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
      find.text('Household e owner criados com sucesso.'),
      findsOneWidget,
    );
  });

  testWidgets('shows backend error when provisioning fails', (tester) async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          role: 'PLATFORM_ADMIN',
          householdId: null,
          email: 'admin@local.invalid',
          name: 'Platform Admin',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(email: 'admin@local.invalid', password: 'senha123');
    final repository = FakePlatformAdminRepository(
      error: fakeApiException(
        statusCode: 409,
        message: 'E-mail ja esta em uso.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do household'),
      'Casa Controlada',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do owner'),
      'Owner Controlado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email do owner'),
      'owner@local.invalid',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha inicial do owner'),
      'senha123',
    );
    final submitButton = find.widgetWithText(
      FilledButton,
      'Criar household + owner',
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('E-mail ja esta em uso.'), findsOneWidget);
  });
}
