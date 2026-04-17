import 'package:despesas_frontend/features/driver_module/domain/driver_native_bridge.dart';
import 'package:flutter/services.dart';

class MethodChannelDriverNativeBridge implements DriverNativeBridge {
  MethodChannelDriverNativeBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gilrossi.despesas/driver_module';

  final MethodChannel _channel;

  @override
  Future<DriverNativeFoundationStatus> getFoundationStatus() async {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getFoundationStatus',
    );
    return DriverNativeFoundationStatus.fromJson(response ?? const {});
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    return await _channel.invokeMethod<bool>('openAccessibilitySettings') ??
        false;
  }
}
