import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/driver_module/presentation/driver_module_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
  void configureLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1800);
    addTearDown(tester.view.reset);
  }

  Future<SessionController> loginAsDriverOwner() async {
    final sessionController = SessionController(
      authRepository: FakeAuthRepository(
        loginResult: fakeSession(
          householdId: 10,
          email: 'driver-owner@local.invalid',
          name: 'Driver Owner',
        ),
      ),
      sessionStore: MemorySessionStore(),
    );
    await sessionController.login(
      email: 'driver-owner@local.invalid',
      password: 'senha123',
    );
    return sessionController;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required SessionController sessionController,
    required FakeDriverModuleRepository repository,
    required FakeDriverNativeBridge nativeBridge,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverModuleScreen(
          sessionController: sessionController,
          driverModuleRepository: repository,
          driverNativeBridge: nativeBridge,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza a fundacao do Driver Module com bootstrap e bridge nativa', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge();

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Driver Module'), findsOneWidget);
    expect(find.text('Base do módulo'), findsOneWidget);
    expect(find.text('Bridge Android'), findsOneWidget);
    expect(find.text('Espaço atual: 10'), findsOneWidget);
    expect(find.text('Praia Grande, SP, BR'), findsOneWidget);
    expect(find.text('Uber Driver'), findsOneWidget);
    expect(find.text('99 Motorista'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('driver-module-native-section')),
      findsOneWidget,
    );
    expect(repository.bootstrapCalls, 1);
    expect(nativeBridge.foundationStatusCalls, 1);
  });

  testWidgets('mostra indisponibilidade quando o DRIVER nao esta habilitado no Espaco', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository(
      bootstrapError: const ApiException(
        statusCode: 403,
        code: 'FORBIDDEN',
        message: 'Access denied',
      ),
    );
    final nativeBridge = FakeDriverNativeBridge();

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(
      find.text('O módulo Motorista não está habilitado neste Espaço.'),
      findsOneWidget,
    );
    expect(nativeBridge.foundationStatusCalls, 0);
  });

  testWidgets('mostra erro tecnico e permite tentar novamente', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository(
      bootstrapError: const ApiException(
        statusCode: 503,
        message: 'Falha temporária no bootstrap.',
      ),
    );
    final nativeBridge = FakeDriverNativeBridge();

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.text('Falha temporária no bootstrap.'), findsOneWidget);

    repository.bootstrapError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Base do módulo'), findsOneWidget);
    expect(repository.bootstrapCalls, 2);
  });
}
