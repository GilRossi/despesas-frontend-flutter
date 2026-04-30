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
  Future<DriverSignalPreferencesStatus> getSignalPreferences() async {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getSignalPreferences',
    );
    return DriverSignalPreferencesStatus.fromJson(response ?? const {});
  }

  @override
  Future<DriverNativeFoundationStatus> saveSignalPreferences({
    required DriverSignalPreferencesInput input,
  }) async {
    try {
      final response = await _channel.invokeMethod<Map<Object?, Object?>>(
        'saveSignalPreferences',
        input.toJson(),
      );
      return DriverNativeFoundationStatus.fromJson(response ?? const {});
    } on PlatformException catch (error) {
      if (error.code == 'INVALID_SIGNAL_PREFERENCES') {
        final details = error.details as Map<Object?, Object?>?;
        final validationErrors =
            (details?['validationErrors'] as List<Object?>? ?? const [])
                .whereType<String>()
                .toList();
        throw DriverSignalPreferencesValidationException(validationErrors);
      }
      rethrow;
    }
  }

  @override
  Future<DriverNativeFoundationStatus> resetSignalPreferences() async {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'resetSignalPreferences',
    );
    return DriverNativeFoundationStatus.fromJson(response ?? const {});
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    return await _channel.invokeMethod<bool>('openAccessibilitySettings') ??
        false;
  }

  @override
  Future<DriverNativeFoundationStatus> requestAcceptCommand({
    String source = 'FLUTTER_HANDSET',
  }) async {
    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'requestAcceptCommand',
      <String, Object?>{'source': source},
    );
    return DriverNativeFoundationStatus.fromJson(response ?? const {});
  }
}
