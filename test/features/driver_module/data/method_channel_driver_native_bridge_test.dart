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
