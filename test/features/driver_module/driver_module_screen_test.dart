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

  testWidgets(
    'renderiza a fundacao do Driver Module com bootstrap e bridge nativa',
    (tester) async {
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
      expect(find.text('Núcleo nativo compartilhado'), findsOneWidget);
      expect(find.text('Abrir acessibilidade'), findsOneWidget);
      expect(find.text('Registrar comando base'), findsOneWidget);
      await scrollToKey(
        tester,
        const ValueKey('driver-module-app-inventory-section'),
      );
      expect(find.text('Inventário operacional por app'), findsOneWidget);
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
    },
  );

  testWidgets(
    'mostra indisponibilidade quando o DRIVER nao esta habilitado no Espaco',
    (tester) async {
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
    },
  );

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

  testWidgets(
    'permite abrir a tela de acessibilidade quando o readiness esta pendente',
    (tester) async {
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
    },
  );

  testWidgets('mostra estado apto quando o readiness nativo fecha', (
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
      ),
    );

    await pumpScreen(
      tester,
      sessionController: sessionController,
      repository: repository,
      nativeBridge: nativeBridge,
    );

    expect(find.text('Driver Module apto'), findsOneWidget);
    expect(
      find.text('Base pronta para a próxima fase técnica.'),
      findsOneWidget,
    );
    expect(find.text('Abrir acessibilidade'), findsNothing);
  });

  testWidgets(
    'mostra farol nativo e comando unificado quando ha contexto recente',
    (tester) async {
      configureLargeViewport(tester);
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'YELLOW',
            label: 'Amarelo',
            reason: 'RECENT_CONTEXT_OUT_OF_FOCUS',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_STATE_CHANGED',
            capturedAt: '2026-04-17T18:10:00Z',
            texts: ['Você está online'],
            inFocus: false,
            validity: 'STALE',
            validUntil: '2026-04-17T18:10:15Z',
            invalidationReason: 'PROVIDER_OUT_OF_FOCUS',
            semanticState: DriverSemanticStateStatus(
              code: 'ONLINE_IDLE',
              label: 'Online aguardando corrida',
              summary: 'O motorista está online e aguardando corrida no Uber.',
              contextRelevant: false,
              confidence: 'HIGH',
              detectedSignals: [
                'Tudo pronto para fazer entregas',
                'Página inicial',
              ],
            ),
          ),
          acceptCommand: const DriverAcceptCommandStatus(
            state: 'PENDING_EXECUTOR',
            source: 'FLUTTER_HANDSET',
            targetProviderKey: 'UBER_DRIVER',
            targetPackageName: 'com.ubercab.driver',
            requestedAt: '2026-04-17T18:10:12Z',
            lastUpdatedAt: '2026-04-17T18:10:12Z',
          ),
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

      await scrollToKey(
        tester,
        const ValueKey('driver-module-shared-state-section'),
      );
      expect(find.textContaining('Farol', findRichText: true), findsWidgets);
      expect(find.textContaining('Amarelo', findRichText: true), findsWidgets);
      expect(
        find.textContaining(
          'Estado semântico atual: ONLINE_IDLE',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Leitura normalizada: Online aguardando corrida',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Resumo do contexto: O motorista está online e aguardando corrida no Uber.',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining('Confiança: HIGH', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Caminho unificado de comando'), findsOneWidget);
      expect(
        find.textContaining('Pendente no executor', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Registrar comando base'), findsOneWidget);
    },
  );

  testWidgets(
    'mostra a última oferta detectada do Uber quando o snapshot ainda está retido',
    (tester) async {
      configureLargeViewport(tester);
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'YELLOW',
            label: 'Amarelo',
            reason: 'ACTIONABLE_OFFER',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-25T12:00:01Z',
            texts: ['Página inicial', 'Ganhos'],
            inFocus: false,
            validity: 'STALE',
            validUntil: '2026-04-25T12:00:16Z',
            invalidationReason: 'PROVIDER_OUT_OF_FOCUS',
            semanticState: DriverSemanticStateStatus(
              code: 'ACTIONABLE_OFFER',
              label: 'Oferta acionável',
              summary: 'Última oferta recente do Uber ainda está preservada.',
              contextRelevant: true,
              confidence: 'HIGH',
              detectedSignals: ['R\$ 18,50', 'Selecionar'],
            ),
          ),
          lastOffer: const DriverOfferStatus(
            detected: true,
            ageMs: 4200,
            summary:
                'Oferta acionável do Uber detectada com valor, CTA e contexto de rota completos.',
            signals: ['R\$ 18,50', 'Selecionar'],
            classification: 'ACTIONABLE_OFFER',
            isActionable: true,
          ),
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
        const ValueKey('driver-module-shared-state-section'),
      );
      expect(
        find.textContaining('Detectada há 4,2s', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('R\$ 18,50 | Selecionar', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Classificação da oferta: ACTIONABLE_OFFER',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining('Oferta acionável: Sim', findRichText: true),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'mostra requisitos faltantes quando o Uber está em OFFER_CANDIDATE',
    (tester) async {
      configureLargeViewport(tester);
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'YELLOW',
            label: 'Amarelo',
            reason: 'OFFER_CANDIDATE',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-29T01:05:00Z',
            texts: ['UberX', 'R\$ 37,37', '5 min (2.0 km)'],
            inFocus: true,
            validity: 'VALID',
            validUntil: '2026-04-29T01:05:15Z',
            semanticState: DriverSemanticStateStatus(
              code: 'OFFER_CANDIDATE',
              label: 'Oferta candidata',
              summary: 'Há indício forte de oferta, mas ainda falta CTA.',
              contextRelevant: false,
              confidence: 'HIGH',
              detectedSignals: ['R\$ 37,37', 'UberX', '5 min (2.0 km)'],
              missingRequirements: ['cta_forte'],
            ),
          ),
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
        const ValueKey('driver-module-shared-state-section'),
      );
      expect(
        find.textContaining(
          'Requisitos faltantes: cta_forte',
          findRichText: true,
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'mostra estado normalizado por provider quando ha leitura semantica local',
    (tester) async {
      configureLargeViewport(tester);
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'YELLOW',
            label: 'Amarelo',
            reason: 'LOGIN_OR_CONSENT',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'APP99_DRIVER',
            label: '99 Motorista',
            packageName: 'com.app99.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-18T10:00:00Z',
            texts: ['Política de privacidade', 'Concordo'],
            inFocus: true,
            validity: 'VALID',
            validUntil: '2026-04-18T10:00:15Z',
            semanticState: DriverSemanticStateStatus(
              code: 'LOGIN_OR_CONSENT',
              label: 'Login ou consentimento',
              summary:
                  'O app pede login, consentimento ou permissão antes de seguir.',
              contextRelevant: false,
            ),
          ),
          providerContexts: const [
            DriverProviderContextStatus(
              providerKey: 'APP99_DRIVER',
              label: '99 Motorista',
              packageName: 'com.app99.driver',
              eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
              capturedAt: '2026-04-18T10:00:00Z',
              texts: ['Política de privacidade', 'Concordo'],
              semanticState: DriverSemanticStateStatus(
                code: 'LOGIN_OR_CONSENT',
                label: 'Login ou consentimento',
                summary:
                    'O app pede login, consentimento ou permissão antes de seguir.',
                contextRelevant: false,
              ),
            ),
          ],
          targetApps: const [
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

      expect(find.text('99 Motorista · LOGIN_OR_CONSENT'), findsOneWidget);
      expect(
        find.textContaining(
          'Estado normalizado: LOGIN_OR_CONSENT',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Leitura: Login ou consentimento',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          'Resumo local: O app pede login, consentimento ou permissão antes de seguir.',
          findRichText: true,
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'mostra inventario pendente quando app esta presente mas ainda nao apto',
    (tester) async {
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
      await scrollToKey(
        tester,
        const ValueKey('driver-module-app-inventory-section'),
      );
      expect(find.text('Uber Driver · Pendente'), findsOneWidget);
      expect(
        find.text(
          'Launch intent indisponível: O Android não encontrou uma activity principal para abrir este app.',
        ),
        findsOneWidget,
      );
      expect(find.text('iFood Entregador · Ausente'), findsOneWidget);
    },
  );

  testWidgets(
    'mostra app apto quando o Android reporta capability matrix completa',
    (tester) async {
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
      await scrollToKey(
        tester,
        const ValueKey('driver-module-app-inventory-section'),
      );
      expect(find.text('Uber Driver · Apto'), findsOneWidget);
      expect(
        find.text('Nenhuma capability pendente para este app.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mostra contexto local capturado para Uber Driver e 99 Motorista',
    (tester) async {
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
              texts: ['Tudo pronto para fazer entregas', 'Página inicial'],
              semanticState: DriverSemanticStateStatus(
                code: 'ONLINE_IDLE',
                label: 'Online aguardando corrida',
                summary:
                    'O motorista está online e aguardando corrida no Uber.',
                contextRelevant: false,
                confidence: 'HIGH',
                detectedSignals: [
                  'Tudo pronto para fazer entregas',
                  'Página inicial',
                ],
              ),
            ),
            DriverProviderContextStatus(
              providerKey: 'APP99_DRIVER',
              label: '99 Motorista',
              packageName: 'com.app99.driver',
              eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
              capturedAt: '2026-04-17T18:11:00Z',
              texts: ['Aceite corridas', 'Dinâmico'],
              semanticState: DriverSemanticStateStatus(
                code: 'RELEVANT_CONTEXT',
                label: 'Contexto relevante',
                summary:
                    'Há um sinal local relevante para a próxima fase do módulo.',
                contextRelevant: true,
              ),
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
      expect(find.text('Uber Driver · ONLINE_IDLE'), findsOneWidget);
      expect(find.text('99 Motorista · RELEVANT_CONTEXT'), findsOneWidget);
      expect(
        find.textContaining('Tudo pronto para fazer entregas'),
        findsOneWidget,
      );
      expect(find.textContaining('Aceite corridas'), findsOneWidget);
    },
  );

  testWidgets('registra o comando base pelo caminho unificado', (tester) async {
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
        signal: const DriverOperationalSignalStatus(
          color: 'YELLOW',
          label: 'Amarelo',
          reason: 'RECENT_CONTEXT_OUT_OF_FOCUS',
        ),
        currentContext: const DriverCurrentContextStatus(
          providerKey: 'UBER_DRIVER',
          label: 'Uber Driver',
          packageName: 'com.ubercab.driver',
          eventType: 'TYPE_WINDOW_STATE_CHANGED',
          capturedAt: '2026-04-17T18:10:00Z',
          texts: ['Você está online'],
          inFocus: false,
          validity: 'STALE',
          validUntil: '2026-04-17T18:10:15Z',
          invalidationReason: 'PROVIDER_OUT_OF_FOCUS',
        ),
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
      acceptCommandResult: fakeDriverNativeFoundationStatus(
        accessibilityServiceEnabled: true,
        moduleReady: true,
        missingCapabilities: const [],
        signal: const DriverOperationalSignalStatus(
          color: 'YELLOW',
          label: 'Amarelo',
          reason: 'RECENT_CONTEXT_OUT_OF_FOCUS',
        ),
        currentContext: const DriverCurrentContextStatus(
          providerKey: 'UBER_DRIVER',
          label: 'Uber Driver',
          packageName: 'com.ubercab.driver',
          eventType: 'TYPE_WINDOW_STATE_CHANGED',
          capturedAt: '2026-04-17T18:10:00Z',
          texts: ['Você está online'],
          inFocus: false,
          validity: 'STALE',
          validUntil: '2026-04-17T18:10:15Z',
          invalidationReason: 'PROVIDER_OUT_OF_FOCUS',
        ),
        acceptCommand: const DriverAcceptCommandStatus(
          state: 'PENDING_EXECUTOR',
          source: 'FLUTTER_HANDSET',
          targetProviderKey: 'UBER_DRIVER',
          targetPackageName: 'com.ubercab.driver',
          requestedAt: '2026-04-17T18:10:12Z',
          lastUpdatedAt: '2026-04-17T18:10:12Z',
        ),
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

    await scrollToKey(tester, const ValueKey('driver-module-command-section'));
    await tester.tap(find.text('Registrar comando base'));
    await tester.pumpAndSettle();

    expect(nativeBridge.requestAcceptCommandCalls, 1);
    expect(
      find.textContaining('Pendente no executor', findRichText: true),
      findsWidgets,
    );
  });
}
