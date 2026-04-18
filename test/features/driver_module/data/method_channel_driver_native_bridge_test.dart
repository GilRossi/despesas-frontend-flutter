import 'package:despesas_frontend/features/driver_module/data/method_channel_driver_native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelDriverNativeBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'getFoundationStatus consome o contrato nativo do Driver Module',
    () async {
      late MethodCall capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return {
              'packageName': 'com.example.despesas_frontend',
              'methodChannel': MethodChannelDriverNativeBridge.channelName,
              'nativeBridgeAvailable': true,
              'methodChannelReady': true,
              'accessibilityServiceDeclared': true,
              'accessibilityServiceEnabled': false,
              'canOpenAccessibilitySettings': true,
              'moduleReady': false,
              'missingCapabilities': ['ACCESSIBILITY_SERVICE_DISABLED'],
              'targetApps': [
                {
                  'key': 'UBER_DRIVER',
                  'label': 'Uber Driver',
                  'packageName': 'com.ubercab.driver',
                  'installed': true,
                  'enabledInSystem': true,
                  'launchIntentAvailable': true,
                  'appReady': true,
                  'missingCapabilities': [],
                  'detectedPackageName': 'com.ubercab.driver',
                },
                {
                  'key': 'APP99_DRIVER',
                  'label': '99 Motorista',
                  'packageName': 'com.app99.driver',
                  'installed': false,
                  'enabledInSystem': false,
                  'launchIntentAvailable': false,
                  'appReady': false,
                  'missingCapabilities': ['PACKAGE_NOT_INSTALLED'],
                  'detectedPackageName': null,
                },
              ],
              'providerContexts': [
                {
                  'providerKey': 'UBER_DRIVER',
                  'label': 'Uber Driver',
                  'packageName': 'com.ubercab.driver',
                  'eventType': 'TYPE_WINDOW_STATE_CHANGED',
                  'capturedAt': '2026-04-17T18:10:00Z',
                  'texts': ['Você está online', 'Promoções'],
                  'semanticState': {
                    'code': 'WAITING',
                    'label': 'Aguardando',
                    'summary': 'O app está aberto e aguardando novas corridas.',
                    'contextRelevant': false,
                  },
                },
              ],
              'signal': {
                'color': 'YELLOW',
                'label': 'Amarelo',
                'reason': 'RECENT_CONTEXT_OUT_OF_FOCUS',
              },
              'currentContext': {
                'providerKey': 'UBER_DRIVER',
                'label': 'Uber Driver',
                'packageName': 'com.ubercab.driver',
                'eventType': 'TYPE_WINDOW_STATE_CHANGED',
                'capturedAt': '2026-04-17T18:10:00Z',
                'texts': ['Você está online', 'Promoções'],
                'inFocus': false,
                'validity': 'STALE',
                'validUntil': '2026-04-17T18:10:15Z',
                'invalidationReason': 'PROVIDER_OUT_OF_FOCUS',
                'semanticState': {
                  'code': 'OUT_OF_FOCUS',
                  'label': 'Fora de foco',
                  'summary':
                      'O app foi visto há pouco, mas não está em foco agora.',
                  'contextRelevant': false,
                },
              },
              'acceptCommand': {
                'state': 'PENDING_EXECUTOR',
                'source': 'FLUTTER_HANDSET',
                'targetProviderKey': 'UBER_DRIVER',
                'targetPackageName': 'com.ubercab.driver',
                'requestedAt': '2026-04-17T18:10:12Z',
                'lastUpdatedAt': '2026-04-17T18:10:12Z',
              },
              'contextTtlSeconds': 15,
              'androidAutoPrepared': false,
            };
          });

      final bridge = MethodChannelDriverNativeBridge();
      final result = await bridge.getFoundationStatus();

      expect(capturedCall.method, 'getFoundationStatus');
      expect(result.packageName, 'com.example.despesas_frontend');
      expect(result.nativeBridgeAvailable, isTrue);
      expect(result.methodChannelReady, isTrue);
      expect(result.accessibilityServiceDeclared, isTrue);
      expect(result.accessibilityServiceEnabled, isFalse);
      expect(result.canOpenAccessibilitySettings, isTrue);
      expect(result.moduleReady, isFalse);
      expect(result.missingCapabilities, ['ACCESSIBILITY_SERVICE_DISABLED']);
      expect(result.targetApps, hasLength(2));
      expect(result.targetApps.first.label, 'Uber Driver');
      expect(result.targetApps.first.packageName, 'com.ubercab.driver');
      expect(result.targetApps.first.installed, isTrue);
      expect(result.targetApps.first.enabledInSystem, isTrue);
      expect(result.targetApps.first.launchIntentAvailable, isTrue);
      expect(result.targetApps.first.appReady, isTrue);
      expect(result.targetApps.first.detectedPackageName, 'com.ubercab.driver');
      expect(result.targetApps.last.missingCapabilities, [
        'PACKAGE_NOT_INSTALLED',
      ]);
      expect(result.providerContexts, hasLength(1));
      expect(result.providerContexts.single.providerKey, 'UBER_DRIVER');
      expect(result.providerContexts.single.texts, [
        'Você está online',
        'Promoções',
      ]);
      expect(result.providerContexts.single.semanticState.code, 'WAITING');
      expect(result.signal.color, 'YELLOW');
      expect(result.signal.reason, 'RECENT_CONTEXT_OUT_OF_FOCUS');
      expect(result.currentContext.providerKey, 'UBER_DRIVER');
      expect(result.currentContext.validity, 'STALE');
      expect(result.currentContext.invalidationReason, 'PROVIDER_OUT_OF_FOCUS');
      expect(result.currentContext.semanticState.code, 'OUT_OF_FOCUS');
      expect(result.acceptCommand.state, 'PENDING_EXECUTOR');
      expect(result.acceptCommand.targetProviderKey, 'UBER_DRIVER');
      expect(result.contextTtlSeconds, 15);
      expect(result.androidAutoPrepared, isFalse);
    },
  );

  test(
    'openAccessibilitySettings dispara a acao nativa do Driver Module',
    () async {
      late MethodCall capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return true;
          });

      final bridge = MethodChannelDriverNativeBridge();
      final opened = await bridge.openAccessibilitySettings();

      expect(capturedCall.method, 'openAccessibilitySettings');
      expect(opened, isTrue);
    },
  );

  test(
    'requestAcceptCommand dispara o caminho unificado de comando no nativo',
    () async {
      late MethodCall capturedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            capturedCall = call;
            return {
              'packageName': 'com.example.despesas_frontend',
              'methodChannel': MethodChannelDriverNativeBridge.channelName,
              'nativeBridgeAvailable': true,
              'methodChannelReady': true,
              'accessibilityServiceDeclared': true,
              'accessibilityServiceEnabled': true,
              'canOpenAccessibilitySettings': true,
              'moduleReady': true,
              'missingCapabilities': const [],
              'targetApps': const [],
              'providerContexts': const [],
              'signal': {
                'color': 'YELLOW',
                'label': 'Amarelo',
                'reason': 'RECENT_CONTEXT_OUT_OF_FOCUS',
              },
              'currentContext': {
                'providerKey': 'UBER_DRIVER',
                'label': 'Uber Driver',
                'packageName': 'com.ubercab.driver',
                'eventType': 'TYPE_WINDOW_STATE_CHANGED',
                'capturedAt': '2026-04-17T18:10:00Z',
                'texts': ['Você está online'],
                'inFocus': false,
                'validity': 'STALE',
                'validUntil': '2026-04-17T18:10:15Z',
                'invalidationReason': 'PROVIDER_OUT_OF_FOCUS',
                'semanticState': {
                  'code': 'OUT_OF_FOCUS',
                  'label': 'Fora de foco',
                  'summary':
                      'O app foi visto há pouco, mas não está em foco agora.',
                  'contextRelevant': false,
                },
              },
              'acceptCommand': {
                'state': 'PENDING_EXECUTOR',
                'source': 'FLUTTER_HANDSET',
                'targetProviderKey': 'UBER_DRIVER',
                'targetPackageName': 'com.ubercab.driver',
                'requestedAt': '2026-04-17T18:10:12Z',
                'lastUpdatedAt': '2026-04-17T18:10:12Z',
              },
              'contextTtlSeconds': 15,
              'androidAutoPrepared': true,
            };
          });

      final bridge = MethodChannelDriverNativeBridge();
      final result = await bridge.requestAcceptCommand();

      expect(capturedCall.method, 'requestAcceptCommand');
      expect(capturedCall.arguments, {'source': 'FLUTTER_HANDSET'});
      expect(result.acceptCommand.state, 'PENDING_EXECUTOR');
      expect(result.androidAutoPrepared, isTrue);
    },
  );
}
