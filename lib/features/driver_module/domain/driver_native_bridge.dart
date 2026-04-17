class DriverNativeFoundationStatus {
  const DriverNativeFoundationStatus({
    required this.packageName,
    required this.methodChannel,
    required this.nativeBridgeAvailable,
    required this.methodChannelReady,
    required this.accessibilityServiceDeclared,
    required this.accessibilityServiceEnabled,
    required this.canOpenAccessibilitySettings,
    required this.moduleReady,
    required this.missingCapabilities,
    required this.androidAutoPrepared,
  });

  final String packageName;
  final String methodChannel;
  final bool nativeBridgeAvailable;
  final bool methodChannelReady;
  final bool accessibilityServiceDeclared;
  final bool accessibilityServiceEnabled;
  final bool canOpenAccessibilitySettings;
  final bool moduleReady;
  final List<String> missingCapabilities;
  final bool androidAutoPrepared;

  factory DriverNativeFoundationStatus.fromJson(Map<Object?, Object?> json) {
    return DriverNativeFoundationStatus(
      packageName: json['packageName'] as String? ?? '',
      methodChannel: json['methodChannel'] as String? ?? '',
      nativeBridgeAvailable: json['nativeBridgeAvailable'] as bool? ?? false,
      methodChannelReady: json['methodChannelReady'] as bool? ?? false,
      accessibilityServiceDeclared:
          json['accessibilityServiceDeclared'] as bool? ?? false,
      accessibilityServiceEnabled:
          json['accessibilityServiceEnabled'] as bool? ?? false,
      canOpenAccessibilitySettings:
          json['canOpenAccessibilitySettings'] as bool? ?? false,
      moduleReady: json['moduleReady'] as bool? ?? false,
      missingCapabilities:
          (json['missingCapabilities'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      androidAutoPrepared: json['androidAutoPrepared'] as bool? ?? false,
    );
  }
}

abstract interface class DriverNativeBridge {
  Future<DriverNativeFoundationStatus> getFoundationStatus();

  Future<bool> openAccessibilitySettings();
}
