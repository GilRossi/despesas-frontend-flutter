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
            'methodChannelReady': true,
            'accessibilityServiceDeclared': true,
            'accessibilityServiceEnabled': false,
            'androidAutoPrepared': false,
          };
        });

    final bridge = MethodChannelDriverNativeBridge();
    final result = await bridge.getFoundationStatus();

    expect(capturedCall.method, 'getFoundationStatus');
    expect(result.packageName, 'com.example.despesas_frontend');
    expect(result.methodChannelReady, isTrue);
    expect(result.accessibilityServiceDeclared, isTrue);
    expect(result.accessibilityServiceEnabled, isFalse);
    expect(result.androidAutoPrepared, isFalse);
  });
}
