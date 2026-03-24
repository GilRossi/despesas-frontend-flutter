import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/features/auth/presentation/change_password_screen.dart';
import 'package:despesas_frontend/features/platform_admin/presentation/platform_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1600);
    addTearDown(tester.view.reset);
  }

  testWidgets('submits household and owner provisioning successfully', (
    tester,
  ) async {
    configureLargeViewport(tester);

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
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );
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
    await tester.scrollUntilVisible(
      submitButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.text('Household e owner criados com sucesso.'), findsOneWidget);
  });

  testWidgets('shows backend error when provisioning fails', (tester) async {
    configureLargeViewport(tester);

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
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );
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
    await tester.scrollUntilVisible(
      submitButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('E-mail ja esta em uso.'), findsOneWidget);
    expect(repository.createCalls, 1);
  });

  testWidgets('opens self password change for platform admin', (tester) async {
    configureLargeViewport(tester);

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
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: FakePlatformAdminRepository(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-open-change-password-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('resets user password from the admin shell', (tester) async {
    configureLargeViewport(tester);

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
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );
    final repository = FakePlatformAdminRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformAdminScreen(
          sessionController: sessionController,
          platformAdminRepository: repository,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      'owner@local.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-new-password-field')),
      'NovaSenha456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-confirm-password-field')),
      'NovaSenha456',
    );

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-reset-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    expect(find.text('Senha resetada com sucesso.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('platform-admin-last-reset-card')),
      findsOneWidget,
    );
  });

  testWidgets('shows backend error when password reset fails', (tester) async {
    configureLargeViewport(tester);

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
    await sessionController.login(
      email: 'admin@local.invalid',
      password: 'senha123',
    );
    final repository = FakePlatformAdminRepository(
      resetError: fakeApiException(
        statusCode: 400,
        message: 'Platform admins must use self-service password change',
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-target-email-field')),
      'admin@local.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-new-password-field')),
      'NovaSenha456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('platform-admin-reset-confirm-password-field')),
      'NovaSenha456',
    );

    await tester.tap(
      find.byKey(const ValueKey('platform-admin-reset-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Platform admins must use self-service password change'),
      findsOneWidget,
    );
  });
}
