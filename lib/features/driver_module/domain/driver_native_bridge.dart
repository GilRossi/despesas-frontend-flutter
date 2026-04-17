class DriverTargetAppStatus {
  const DriverTargetAppStatus({
    required this.key,
    required this.label,
    required this.installed,
    this.detectedPackageName,
  });

  final String key;
  final String label;
  final bool installed;
  final String? detectedPackageName;

  factory DriverTargetAppStatus.fromJson(Map<Object?, Object?> json) {
    return DriverTargetAppStatus(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      installed: json['installed'] as bool? ?? false,
      detectedPackageName: json['detectedPackageName'] as String?,
    );
  }
}

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
    required this.targetApps,
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
  final List<DriverTargetAppStatus> targetApps;
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
      targetApps:
          (json['targetApps'] as List<Object?>? ?? const [])
              .whereType<Map<Object?, Object?>>()
              .map(DriverTargetAppStatus.fromJson)
              .toList(),
      androidAutoPrepared: json['androidAutoPrepared'] as bool? ?? false,
    );
  }
}

abstract interface class DriverNativeBridge {
  Future<DriverNativeFoundationStatus> getFoundationStatus();

  Future<bool> openAccessibilitySettings();
}
