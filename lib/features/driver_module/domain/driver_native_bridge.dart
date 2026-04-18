class DriverSemanticStateStatus {
  const DriverSemanticStateStatus({
    required this.code,
    required this.label,
    required this.summary,
    required this.contextRelevant,
  });

  final String code;
  final String label;
  final String summary;
  final bool contextRelevant;

  factory DriverSemanticStateStatus.fromJson(Map<Object?, Object?> json) {
    return DriverSemanticStateStatus(
      code: json['code'] as String? ?? 'NO_ACTIVE_PROVIDER',
      label: json['label'] as String? ?? 'Sem provider ativo',
      summary:
          json['summary'] as String? ??
          'Abra Uber Driver ou 99 Motorista para iniciar a leitura local.',
      contextRelevant: json['contextRelevant'] as bool? ?? false,
    );
  }
}

class DriverTargetAppStatus {
  const DriverTargetAppStatus({
    required this.key,
    required this.label,
    required this.packageName,
    required this.installed,
    required this.enabledInSystem,
    required this.launchIntentAvailable,
    required this.appReady,
    required this.missingCapabilities,
    this.detectedPackageName,
  });

  final String key;
  final String label;
  final String packageName;
  final bool installed;
  final bool enabledInSystem;
  final bool launchIntentAvailable;
  final bool appReady;
  final List<String> missingCapabilities;
  final String? detectedPackageName;

  factory DriverTargetAppStatus.fromJson(Map<Object?, Object?> json) {
    return DriverTargetAppStatus(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      installed: json['installed'] as bool? ?? false,
      enabledInSystem: json['enabledInSystem'] as bool? ?? false,
      launchIntentAvailable: json['launchIntentAvailable'] as bool? ?? false,
      appReady: json['appReady'] as bool? ?? false,
      missingCapabilities:
          (json['missingCapabilities'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      detectedPackageName: json['detectedPackageName'] as String?,
    );
  }
}

class DriverProviderContextStatus {
  const DriverProviderContextStatus({
    required this.providerKey,
    required this.label,
    required this.packageName,
    required this.eventType,
    required this.capturedAt,
    required this.texts,
    this.semanticState = const DriverSemanticStateStatus(
      code: 'INSUFFICIENT_CONTEXT',
      label: 'Contexto insuficiente',
      summary: 'Ainda não há sinal local estável para este provider.',
      contextRelevant: false,
    ),
  });

  final String providerKey;
  final String label;
  final String packageName;
  final String eventType;
  final String capturedAt;
  final List<String> texts;
  final DriverSemanticStateStatus semanticState;

  factory DriverProviderContextStatus.fromJson(Map<Object?, Object?> json) {
    return DriverProviderContextStatus(
      providerKey: json['providerKey'] as String? ?? '',
      label: json['label'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      capturedAt: json['capturedAt'] as String? ?? '',
      texts: (json['texts'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      semanticState: DriverSemanticStateStatus.fromJson(
        json['semanticState'] as Map<Object?, Object?>? ?? const {},
      ),
    );
  }
}

class DriverOperationalSignalStatus {
  const DriverOperationalSignalStatus({
    required this.color,
    required this.label,
    required this.reason,
  });

  final String color;
  final String label;
  final String reason;

  factory DriverOperationalSignalStatus.fromJson(Map<Object?, Object?> json) {
    return DriverOperationalSignalStatus(
      color: json['color'] as String? ?? 'RED',
      label: json['label'] as String? ?? 'Vermelho',
      reason: json['reason'] as String? ?? 'MODULE_BLOCKED',
    );
  }
}

class DriverCurrentContextStatus {
  const DriverCurrentContextStatus({
    required this.providerKey,
    required this.label,
    required this.packageName,
    required this.eventType,
    required this.capturedAt,
    required this.texts,
    required this.inFocus,
    required this.validity,
    required this.validUntil,
    this.invalidationReason,
    this.semanticState = const DriverSemanticStateStatus(
      code: 'NO_ACTIVE_PROVIDER',
      label: 'Sem provider ativo',
      summary: 'Abra Uber Driver ou 99 Motorista para iniciar a leitura local.',
      contextRelevant: false,
    ),
  });

  final String providerKey;
  final String label;
  final String packageName;
  final String eventType;
  final String capturedAt;
  final List<String> texts;
  final bool inFocus;
  final String validity;
  final String validUntil;
  final String? invalidationReason;
  final DriverSemanticStateStatus semanticState;

  bool get hasProvider => providerKey.isNotEmpty;

  bool get isFresh =>
      validity == 'VALID' || validity == 'STALE' || validity == 'INCOMPLETE';

  factory DriverCurrentContextStatus.fromJson(Map<Object?, Object?> json) {
    return DriverCurrentContextStatus(
      providerKey: json['providerKey'] as String? ?? '',
      label: json['label'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      capturedAt: json['capturedAt'] as String? ?? '',
      texts: (json['texts'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      inFocus: json['inFocus'] as bool? ?? false,
      validity: json['validity'] as String? ?? 'INVALID',
      validUntil: json['validUntil'] as String? ?? '',
      invalidationReason: json['invalidationReason'] as String?,
      semanticState: DriverSemanticStateStatus.fromJson(
        json['semanticState'] as Map<Object?, Object?>? ?? const {},
      ),
    );
  }
}

class DriverAcceptCommandStatus {
  const DriverAcceptCommandStatus({
    required this.state,
    this.source,
    this.targetProviderKey,
    this.targetPackageName,
    this.requestedAt,
    this.lastUpdatedAt,
    this.reason,
  });

  final String state;
  final String? source;
  final String? targetProviderKey;
  final String? targetPackageName;
  final String? requestedAt;
  final String? lastUpdatedAt;
  final String? reason;

  bool get hasPendingWork =>
      state == 'PENDING_EXECUTOR' || state == 'EXECUTOR_READY';

  factory DriverAcceptCommandStatus.fromJson(Map<Object?, Object?> json) {
    return DriverAcceptCommandStatus(
      state: json['state'] as String? ?? 'IDLE',
      source: json['source'] as String?,
      targetProviderKey: json['targetProviderKey'] as String?,
      targetPackageName: json['targetPackageName'] as String?,
      requestedAt: json['requestedAt'] as String?,
      lastUpdatedAt: json['lastUpdatedAt'] as String?,
      reason: json['reason'] as String?,
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
    required this.providerContexts,
    required this.signal,
    required this.currentContext,
    required this.acceptCommand,
    required this.contextTtlSeconds,
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
  final List<DriverProviderContextStatus> providerContexts;
  final DriverOperationalSignalStatus signal;
  final DriverCurrentContextStatus currentContext;
  final DriverAcceptCommandStatus acceptCommand;
  final int contextTtlSeconds;
  final bool androidAutoPrepared;

  bool get hasReadyTargetApps => targetApps.any((target) => target.appReady);

  int get readyTargetAppsCount =>
      targetApps.where((target) => target.appReady).length;

  int get installedTargetAppsCount =>
      targetApps.where((target) => target.installed).length;

  bool get hasCapturedProviderContexts => providerContexts.isNotEmpty;

  bool get hasFreshCurrentContext =>
      currentContext.hasProvider && currentContext.isFresh;

  DriverProviderContextStatus? contextForProvider(String providerKey) {
    for (final context in providerContexts) {
      if (context.providerKey == providerKey) {
        return context;
      }
    }
    return null;
  }

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
      targetApps: (json['targetApps'] as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(DriverTargetAppStatus.fromJson)
          .toList(),
      providerContexts: (json['providerContexts'] as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(DriverProviderContextStatus.fromJson)
          .toList(),
      signal: DriverOperationalSignalStatus.fromJson(
        json['signal'] as Map<Object?, Object?>? ?? const {},
      ),
      currentContext: DriverCurrentContextStatus.fromJson(
        json['currentContext'] as Map<Object?, Object?>? ?? const {},
      ),
      acceptCommand: DriverAcceptCommandStatus.fromJson(
        json['acceptCommand'] as Map<Object?, Object?>? ?? const {},
      ),
      contextTtlSeconds: json['contextTtlSeconds'] as int? ?? 15,
      androidAutoPrepared: json['androidAutoPrepared'] as bool? ?? false,
    );
  }
}

abstract interface class DriverNativeBridge {
  Future<DriverNativeFoundationStatus> getFoundationStatus();

  Future<bool> openAccessibilitySettings();

  Future<DriverNativeFoundationStatus> requestAcceptCommand({
    String source = 'FLUTTER_HANDSET',
  });
}
