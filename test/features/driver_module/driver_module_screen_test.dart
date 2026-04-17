import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
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

  Future<void> scrollToKey(WidgetTester tester, Key key) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(key),
      300,
      scrollable: scrollable,
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
    expect(find.text('Readiness do módulo'), findsOneWidget);
    expect(find.text('Inventário operacional por app'), findsOneWidget);
    expect(find.text('Abrir acessibilidade'), findsOneWidget);
    await scrollToKey(
      tester,
      const ValueKey('driver-module-provider-context-section'),
    );
    expect(find.text('Contexto local monitorado'), findsOneWidget);
    expect(find.text('Uber Driver · Ausente'), findsOneWidget);
    expect(find.text('Package: com.ubercab.driver'), findsOneWidget);
    expect(
      find.text(
        'App não instalado: O package aprovado ainda não foi encontrado neste device.',
      ),
      findsWidgets,
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

    expect(find.text('Readiness do módulo'), findsOneWidget);
    expect(repository.bootstrapCalls, 2);
  });

  testWidgets('permite abrir a tela de acessibilidade quando o readiness esta pendente', (
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

    await tester.tap(find.text('Abrir acessibilidade'));
    await tester.pumpAndSettle();

    expect(nativeBridge.openAccessibilitySettingsCalls, 1);
    expect(
      find.text(
        'Abra o Driver Module na acessibilidade, habilite o serviço e volte para o app.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('mostra estado apto quando o readiness nativo fecha', (tester) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
      ),
    );

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Driver Module apto'), findsOneWidget);
    expect(find.text('Base pronta para a próxima fase técnica.'), findsOneWidget);
    expect(find.text('Abrir acessibilidade'), findsNothing);
  });

  testWidgets('mostra inventario pendente quando app esta presente mas ainda nao apto', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
        targetApps: const [
          DriverTargetAppStatus(
            key: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            installed: true,
            enabledInSystem: true,
            launchIntentAvailable: false,
            appReady: false,
            missingCapabilities: ['LAUNCH_INTENT_UNAVAILABLE'],
            detectedPackageName: 'com.ubercab.driver',
          ),
          DriverTargetAppStatus(
            key: 'IFOOD_DRIVER',
            label: 'iFood Entregador',
            packageName: 'br.com.ifood.driver.app',
            installed: false,
            enabledInSystem: false,
            launchIntentAvailable: false,
            appReady: false,
            missingCapabilities: ['PACKAGE_NOT_INSTALLED'],
          ),
        ],
      ),
    );

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Driver Module em inventário'), findsOneWidget);
    expect(find.text('Uber Driver · Pendente'), findsOneWidget);
    expect(
      find.text(
        'Launch intent indisponível: O Android não encontrou uma activity principal para abrir este app.',
      ),
      findsOneWidget,
    );
    expect(find.text('iFood Entregador · Ausente'), findsOneWidget);
  });

  testWidgets('mostra app apto quando o Android reporta capability matrix completa', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
        targetApps: const [
          DriverTargetAppStatus(
            key: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            installed: true,
            enabledInSystem: true,
            launchIntentAvailable: true,
            appReady: true,
            missingCapabilities: [],
            detectedPackageName: 'com.ubercab.driver',
          ),
        ],
      ),
    );

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Driver Module apto'), findsOneWidget);
    expect(find.text('Uber Driver · Apto'), findsOneWidget);
    expect(find.text('Nenhuma capability pendente para este app.'), findsOneWidget);
  });

  testWidgets('mostra contexto local capturado para Uber Driver e 99 Motorista', (
    tester,
  ) async {
    configureLargeViewport(tester);
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository(
      bootstrap: fakeDriverModuleBootstrap(),
    );
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
        targetApps: const [
          DriverTargetAppStatus(
            key: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            installed: true,
            enabledInSystem: true,
            launchIntentAvailable: true,
            appReady: true,
            missingCapabilities: [],
            detectedPackageName: 'com.ubercab.driver',
          ),
          DriverTargetAppStatus(
            key: 'APP99_DRIVER',
            label: '99 Motorista',
            packageName: 'com.app99.driver',
            installed: true,
            enabledInSystem: true,
            launchIntentAvailable: true,
            appReady: true,
            missingCapabilities: [],
            detectedPackageName: 'com.app99.driver',
          ),
        ],
        providerContexts: const [
          DriverProviderContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_STATE_CHANGED',
            capturedAt: '2026-04-17T18:10:00Z',
            texts: ['Você está online', 'Promoções'],
          ),
          DriverProviderContextStatus(
            providerKey: 'APP99_DRIVER',
            label: '99 Motorista',
            packageName: 'com.app99.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-17T18:11:00Z',
            texts: ['Aceite corridas', 'Dinâmico'],
          ),
        ],
      ),
    );

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    await scrollToKey(
      tester,
      const ValueKey('driver-module-provider-context-section'),
    );

    expect(find.text('Contexto local monitorado'), findsOneWidget);
    expect(find.text('Uber Driver · Contexto capturado'), findsOneWidget);
    expect(find.text('99 Motorista · Contexto capturado'), findsOneWidget);
    expect(find.textContaining('Você está online'), findsOneWidget);
    expect(find.textContaining('Aceite corridas'), findsOneWidget);
  });
}
