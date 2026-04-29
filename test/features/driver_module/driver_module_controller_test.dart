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
    expect(controller.state.nativeStatus?.missingCapabilities, [
      'ACCESSIBILITY_SERVICE_DISABLED',
    ]);
    expect(
      controller.describeMissingCapabilities().single.title,
      'Serviço central desabilitado',
    );
  });

  test(
    'load marca o modulo como pronto quando o readiness nativo fecha',
    () async {
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
      expect(controller.signalLabel(), 'Vermelho');
    },
  );

  test(
    'load marca contexto como capturado quando Uber ou 99 ja foram lidos',
    () async {
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'GREEN',
            label: 'Verde',
            reason: 'FOCUSED_CONTEXT_READY',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_STATE_CHANGED',
            capturedAt: '2026-04-17T18:10:00Z',
            texts: ['Você está online', 'Promoções'],
            inFocus: true,
            validity: 'VALID',
            validUntil: '2026-04-17T18:10:15Z',
            semanticState: DriverSemanticStateStatus(
              code: 'RELEVANT_CONTEXT',
              label: 'Contexto relevante',
              summary:
                  'Há um sinal local relevante para a próxima fase do módulo.',
              contextRelevant: true,
            ),
          ),
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
      expect(controller.signalLabel(), 'Verde');
      expect(controller.contextValidityLabel(), 'Válido');
      expect(controller.currentProviderLabel(), 'Uber Driver');
      expect(controller.currentSemanticStateLabel(), 'Contexto relevante');
      expect(
        controller.currentSemanticSummary(),
        'Há um sinal local relevante para a próxima fase do módulo.',
      );
      expect(
        controller.state.nativeStatus
            ?.contextForProvider('UBER_DRIVER')
            ?.texts
            .first,
        'Você está online',
      );
    },
  );

  test(
    'load expõe estado semântico local mais estável para login ou consentimento',
    () async {
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
            texts: ['Política de privacidade e uso 99 Motorista', 'Concordo'],
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
        ),
      );
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();

      expect(controller.currentProviderLabel(), '99 Motorista');
      expect(controller.currentSemanticStateCode(), 'LOGIN_OR_CONSENT');
      expect(controller.currentSemanticStateLabel(), 'Login ou consentimento');
      expect(
        controller.currentSemanticSummary(),
        'O app pede login, consentimento ou permissão antes de seguir.',
      );
      expect(controller.signalLabel(), 'Amarelo');
    },
  );

  test(
    'load expõe sinais e confiança do Uber online aguardando corrida',
    () async {
      final sessionController = await loginAsDriverOwner();
      final repository = FakeDriverModuleRepository();
      final nativeBridge = FakeDriverNativeBridge(
        status: fakeDriverNativeFoundationStatus(
          accessibilityServiceEnabled: true,
          moduleReady: true,
          missingCapabilities: const [],
          signal: const DriverOperationalSignalStatus(
            color: 'GREEN',
            label: 'Verde',
            reason: 'ONLINE_IDLE',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-24T19:02:00Z',
            texts: ['Tudo pronto para fazer entregas', 'Página inicial'],
            inFocus: true,
            validity: 'VALID',
            validUntil: '2026-04-24T19:02:15Z',
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
        ),
      );
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();

      expect(controller.currentSemanticStateCode(), 'ONLINE_IDLE');
      expect(
        controller.currentSemanticStateLabel(),
        'Online aguardando corrida',
      );
      expect(controller.currentSemanticConfidenceLabel(), 'HIGH');
      expect(
        controller.currentSemanticDetectedSignalsLabel(),
        'Tudo pronto para fazer entregas | Página inicial',
      );
    },
  );

  test(
    'load expõe última oferta recente do Uber quando o snapshot nativo traz retenção ativa',
    () async {
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
          structuredOfferPresent: true,
          structuredOffer: const DriverStructuredOfferStatus(
            providerKey: 'UBER_DRIVER',
            classification: 'ACTIONABLE_OFFER',
            isActionable: true,
            productName: 'UberX',
            fareAmountText: 'R\$ 18,50',
            fareAmountCents: 1850,
            pickupEtaText: '5 min',
            pickupDistanceText: '2.1 km',
            tripDurationText: '18 minutos',
            tripDistanceText: '8.4 km',
            primaryLocationText: 'Rua Exemplo, Praia Grande',
            secondaryLocationText: 'Av. Destino, Santos',
            ctaText: 'Selecionar',
            confidence: 'HIGH',
            missingFields: [],
            rawTexts: ['UberX', 'R\$ 18,50', 'Selecionar'],
            parsedAt: '2026-04-25T12:00:01Z',
          ),
          offerClassification: 'ACTIONABLE_OFFER',
          offerActionable: true,
          offerMissingFields: const [],
          offerParsingConfidence: 'HIGH',
          offerSignalPresent: true,
          offerSignal: const DriverOfferSignalStatus(
            color: 'YELLOW',
            label: 'Amarelo',
            reason:
                'Oferta acionável, mas abaixo do patamar verde da regra v1.',
            warnings: [],
            farePerKmText: 'R\$ 1,76/km',
            farePerMinuteText: 'R\$ 0,80/min',
            estimatedTotalDistanceKm: 10.5,
            estimatedTotalDurationMin: 23,
            estimatedTotalDistanceText: '10,5 km',
            estimatedTotalDurationText: '23 min',
            ruleVersion: 'UBER_SIGNAL_V1',
            computedAt: '2026-04-25T12:00:02Z',
          ),
          offerSignalColor: 'YELLOW',
          offerSignalReason:
              'Oferta acionável, mas abaixo do patamar verde da regra v1.',
          offerSignalWarnings: const [],
          farePerKmText: 'R\$ 1,76/km',
          farePerMinuteText: 'R\$ 0,80/min',
          estimatedTotalDistanceText: '10,5 km',
          estimatedTotalDurationText: '23 min',
          signalRuleVersion: 'UBER_SIGNAL_V1',
        ),
      );
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();

      expect(controller.lastOfferStatusLabel(), 'Detectada há 4,2s');
      expect(
        controller.lastOfferSummary(),
        'Oferta acionável do Uber detectada com valor, CTA e contexto de rota completos.',
      );
      expect(controller.lastOfferSignalsLabel(), 'R\$ 18,50 | Selecionar');
      expect(controller.lastOfferClassificationLabel(), 'ACTIONABLE_OFFER');
      expect(controller.lastOfferActionabilityLabel(), 'Sim');
      expect(
        controller.lastOfferMissingRequirementsLabel(),
        'Nenhum requisito pendente.',
      );
      expect(
        controller.structuredOfferStatusLabel(),
        'Oferta estruturada acionável disponível.',
      );
      expect(controller.structuredOfferValueLabel(), 'R\$ 18,50');
      expect(controller.structuredOfferProductLabel(), 'UberX');
      expect(controller.structuredOfferPickupLabel(), '5 min | 2.1 km');
      expect(controller.structuredOfferTripLabel(), '18 minutos | 8.4 km');
      expect(
        controller.structuredOfferPrimaryLocationLabel(),
        'Rua Exemplo, Praia Grande',
      );
      expect(controller.structuredOfferCtaLabel(), 'Selecionar');
      expect(
        controller.structuredOfferMissingFieldsLabel(),
        'Nenhum campo ausente.',
      );
      expect(controller.offerSignalStatusLabel(), 'Amarelo');
      expect(
        controller.offerSignalReasonLabel(),
        'Oferta acionável, mas abaixo do patamar verde da regra v1.',
      );
      expect(controller.offerSignalFarePerKmLabel(), 'R\$ 1,76/km');
      expect(controller.offerSignalFarePerMinuteLabel(), 'R\$ 0,80/min');
      expect(controller.offerSignalEstimatedDistanceLabel(), '10,5 km');
      expect(controller.offerSignalEstimatedDurationLabel(), '23 min');
      expect(controller.offerSignalWarningsLabel(), 'Nenhum aviso.');
      expect(controller.offerSignalRuleVersionLabel(), 'UBER_SIGNAL_V1');
    },
  );

  test(
    'load expõe requisitos faltantes quando o Uber fica em OFFER_CANDIDATE',
    () async {
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
          structuredOfferPresent: true,
          structuredOffer: const DriverStructuredOfferStatus(
            providerKey: 'UBER_DRIVER',
            classification: 'OFFER_CANDIDATE',
            isActionable: false,
            productName: 'UberX',
            fareAmountText: 'R\$ 37,37',
            fareAmountCents: 3737,
            pickupEtaText: '5 min',
            pickupDistanceText: '2.0 km',
            tripDurationText: '33 minutos',
            tripDistanceText: '22.0 km',
            primaryLocationText:
                'Rua Antônio Monteiro, Balneário Maracanã, Praia Grande',
            secondaryLocationText:
                'Avenida Washington Luís, 483, Boqueirão, Santos',
            confidence: 'MEDIUM',
            missingFields: ['cta'],
            rawTexts: ['UberX', 'R\$ 37,37', '5 min (2.0 km)'],
            parsedAt: '2026-04-29T01:05:00Z',
          ),
          offerClassification: 'OFFER_CANDIDATE',
          offerActionable: false,
          offerMissingFields: const ['cta'],
          offerParsingConfidence: 'MEDIUM',
          offerSignalPresent: true,
          offerSignal: const DriverOfferSignalStatus(
            color: 'RED',
            label: 'Vermelho',
            reason: 'Oferta incompleta: falta requisito crítico para ação.',
            warnings: ['CTA ausente.'],
            farePerKmText: 'R\$ 1,56/km',
            farePerMinuteText: 'R\$ 0,98/min',
            estimatedTotalDistanceKm: 24.0,
            estimatedTotalDurationMin: 38,
            estimatedTotalDistanceText: '24,0 km',
            estimatedTotalDurationText: '38 min',
            ruleVersion: 'UBER_SIGNAL_V1',
            computedAt: '2026-04-29T01:05:01Z',
          ),
          offerSignalColor: 'RED',
          offerSignalReason:
              'Oferta incompleta: falta requisito crítico para ação.',
          offerSignalWarnings: const ['CTA ausente.'],
          farePerKmText: 'R\$ 1,56/km',
          farePerMinuteText: 'R\$ 0,98/min',
          estimatedTotalDistanceText: '24,0 km',
          estimatedTotalDurationText: '38 min',
          signalRuleVersion: 'UBER_SIGNAL_V1',
        ),
      );
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();

      expect(controller.currentSemanticStateCode(), 'OFFER_CANDIDATE');
      expect(controller.currentSemanticMissingRequirementsLabel(), 'cta_forte');
      expect(
        controller.structuredOfferStatusLabel(),
        'Oferta estruturada parcial disponível.',
      );
      expect(
        controller.structuredOfferClassificationLabel(),
        'OFFER_CANDIDATE',
      );
      expect(controller.structuredOfferActionabilityLabel(), 'Não');
      expect(controller.structuredOfferValueLabel(), 'R\$ 37,37');
      expect(controller.structuredOfferCtaLabel(), 'Não identificado');
      expect(controller.structuredOfferMissingFieldsLabel(), 'cta');
      expect(controller.offerSignalStatusLabel(), 'Vermelho');
      expect(
        controller.offerSignalReasonLabel(),
        'Oferta incompleta: falta requisito crítico para ação.',
      );
      expect(controller.offerSignalWarningsLabel(), 'CTA ausente.');
      expect(controller.canRequestAcceptCommand(), isFalse);
    },
  );

  test(
    'load não expõe oferta estruturada acionável para OFFER_EXPIRED_OR_MISSED',
    () async {
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
            reason: 'OFFER_EXPIRED_OR_MISSED',
          ),
          currentContext: const DriverCurrentContextStatus(
            providerKey: 'UBER_DRIVER',
            label: 'Uber Driver',
            packageName: 'com.ubercab.driver',
            eventType: 'TYPE_WINDOW_CONTENT_CHANGED',
            capturedAt: '2026-04-29T01:06:00Z',
            texts: ['-R\$ 0,01', 'Procurando viagens', '1-4 min'],
            inFocus: true,
            validity: 'VALID',
            validUntil: '2026-04-29T01:06:15Z',
            semanticState: DriverSemanticStateStatus(
              code: 'OFFER_EXPIRED_OR_MISSED',
              label: 'Oferta expirada ou perdida',
              summary: 'O cartão completo já não estava íntegro.',
              contextRelevant: false,
              confidence: 'MEDIUM',
              detectedSignals: ['-R\$ 0,01', 'Procurando viagens'],
            ),
          ),
        ),
      );
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();

      expect(
        controller.structuredOfferStatusLabel(),
        'Nenhuma oferta estruturada no contexto atual.',
      );
      expect(controller.structuredOfferActionabilityLabel(), 'Não');
      expect(controller.structuredOfferValueLabel(), 'Não identificado');
      expect(
        controller.offerSignalStatusLabel(),
        'Nenhum farol calculado para a oferta atual.',
      );
      expect(controller.canRequestAcceptCommand(), isFalse);
    },
  );

  test(
    'requestAcceptCommand atualiza o estado agregado com o comando centralizado',
    () async {
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
          ),
          acceptCommand: const DriverAcceptCommandStatus(state: 'IDLE'),
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
      final controller = DriverModuleController(
        sessionController: sessionController,
        driverModuleRepository: repository,
        driverNativeBridge: nativeBridge,
      );

      await controller.load();
      await controller.requestAcceptCommand();

      expect(nativeBridge.requestAcceptCommandCalls, 1);
      expect(controller.state.kind, DriverModuleStateKind.ready);
      expect(controller.acceptCommandLabel(), 'Pendente no executor');
      expect(
        controller.state.message,
        'Comando registrado no núcleo nativo. O executor real continua restrito ao AccessibilityService.',
      );
    },
  );

  test(
    'load marca inventario bloqueado quando nenhum app-alvo esta apto',
    () async {
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
    },
  );

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

  test(
    'retorno da acessibilidade reavalia o readiness automaticamente',
    () async {
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
    },
  );
}
