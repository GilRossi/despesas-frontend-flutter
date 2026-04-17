import 'package:despesas_frontend/features/driver_module/data/method_channel_driver_native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    MethodChannelDriverNativeBridge.channelName,
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getFoundationStatus consome o contrato nativo do Driver Module', () async {
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
              },
            ],
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
    expect(result.targetApps.last.missingCapabilities, ['PACKAGE_NOT_INSTALLED']);
    expect(result.providerContexts, hasLength(1));
    expect(result.providerContexts.single.providerKey, 'UBER_DRIVER');
    expect(result.providerContexts.single.texts, ['Você está online', 'Promoções']);
    expect(result.androidAutoPrepared, isFalse);
  });

  test('openAccessibilitySettings dispara a acao nativa do Driver Module', () async {
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
  });
}
