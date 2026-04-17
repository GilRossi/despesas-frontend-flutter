import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/network/api_exception.dart';
import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
import 'package:despesas_frontend/features/driver_module/presentation/driver_module_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_doubles.dart';

void main() {
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

  test('load combina bootstrap e readiness nativo bloqueado', () async {
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: false,
        moduleReady: false,
        missingCapabilities: const ['ACCESSIBILITY_SERVICE_DISABLED'],
      ),
    );
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();

    expect(controller.state.kind, DriverModuleStateKind.nativeReadinessBlocked);
    expect(controller.state.bootstrap?.spaceId, 10);
    expect(
      controller.state.nativeStatus?.missingCapabilities,
      ['ACCESSIBILITY_SERVICE_DISABLED'],
    );
    expect(
      controller.describeMissingCapabilities().single.title,
      'Serviço central desabilitado',
    );
  });

  test('load marca o modulo como pronto quando o readiness nativo fecha', () async {
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
      ),
    );
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();

    expect(controller.state.kind, DriverModuleStateKind.ready);
    expect(controller.state.canProceed, isTrue);
    expect(controller.contextSummaryLabel(), 'Pendente');
  });

  test('load marca contexto como capturado quando Uber ou 99 ja foram lidos', () async {
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
        providerContexts: const [
          DriverProviderContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_STATE_CHANGED',
            capturedAt: '2026-04-17T18:10:00Z',
            texts: ['Você está online', 'Promoções'],
          ),
        ],
      ),
    );
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();

    expect(controller.state.kind, DriverModuleStateKind.ready);
    expect(controller.contextSummaryLabel(), 'Capturado');
    expect(
      controller.state.nativeStatus?.contextForProvider('UBER_DRIVER')?.texts.first,
      'Você está online',
    );
  });

  test('load marca inventario bloqueado quando nenhum app-alvo esta apto', () async {
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
        ],
      ),
    );
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();

    expect(controller.state.kind, DriverModuleStateKind.appInventoryBlocked);
    expect(controller.inventorySummaryLabel(), 'Pendente');
    expect(
      controller
          .describeAppMissingCapabilities(
            controller.state.nativeStatus!.targetApps.first,
          )
          .single
          .title,
      'Launch intent indisponível',
    );
  });

  test('load respeita bloqueio backend e nao consulta bridge nativa', () async {
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository(
      bootstrapError: const ApiException(
        statusCode: 403,
        code: 'FORBIDDEN',
        message: 'Access denied',
      ),
    );
    final nativeBridge = FakeDriverNativeBridge();
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();

    expect(controller.state.kind, DriverModuleStateKind.backendBlocked);
    expect(nativeBridge.foundationStatusCalls, 0);
  });

  test('openAccessibilitySettings usa a bridge nativa', () async {
    final sessionController = await loginAsDriverOwner();
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: FakeDriverModuleRepository(),
      driverNativeBridge: FakeDriverNativeBridge(),
    );

    final opened = await controller.openAccessibilitySettings();

    expect(opened, isTrue);
  });

  test('retorno da acessibilidade reavalia o readiness automaticamente', () async {
    final sessionController = await loginAsDriverOwner();
    final repository = FakeDriverModuleRepository();
    final nativeBridge = FakeDriverNativeBridge(
      status: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: false,
        moduleReady: false,
        missingCapabilities: const ['ACCESSIBILITY_SERVICE_DISABLED'],
      ),
    );
    final controller = DriverModuleController(
      sessionController: sessionController,
      driverModuleRepository: repository,
      driverNativeBridge: nativeBridge,
    );

    await controller.load();
    await controller.openAccessibilitySettings();
    nativeBridge.status = fakeDriverNativeFoundationStatus(
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
    );

    await controller.handleAppResumed();

    expect(controller.state.kind, DriverModuleStateKind.ready);
    expect(
      controller.state.message,
      'AccessibilityService habilitado no retorno. O módulo já pode seguir.',
    );
    expect(nativeBridge.foundationStatusCalls, 2);
  });
}
