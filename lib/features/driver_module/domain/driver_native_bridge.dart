class DriverSemanticStateStatus {
  const DriverSemanticStateStatus({
    required this.code,
    required this.label,
    required this.summary,
    required this.contextRelevant,
    this.confidence = 'LOW',
    this.detectedSignals = const [],
    this.missingRequirements = const [],
  });

  final String code;
  final String label;
  final String summary;
  final bool contextRelevant;
  final String confidence;
  final List<String> detectedSignals;
  final List<String> missingRequirements;

  factory DriverSemanticStateStatus.fromJson(Map<Object?, Object?> json) {
    return DriverSemanticStateStatus(
      code: json['code'] as String? ?? 'NO_ACTIVE_PROVIDER',
      label: json['label'] as String? ?? 'Sem provider ativo',
      summary:
          json['summary'] as String? ??
          'Abra Uber Driver ou 99 Motorista para iniciar a leitura local.',
      contextRelevant: json['contextRelevant'] as bool? ?? false,
      confidence: json['confidence'] as String? ?? 'LOW',
      detectedSignals: (json['detectedSignals'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      missingRequirements:
          (json['missingRequirements'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
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

  bool get isActionable =>
      (validity == 'VALID' || validity == 'STALE') &&
      semanticState.contextRelevant;

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

class DriverOfferStatus {
  const DriverOfferStatus({
    required this.detected,
    this.ageMs,
    this.summary,
    this.signals = const [],
    this.classification,
    this.isActionable = false,
    this.missingRequirements = const [],
  });

  final bool detected;
  final int? ageMs;
  final String? summary;
  final List<String> signals;
  final String? classification;
  final bool isActionable;
  final List<String> missingRequirements;

  factory DriverOfferStatus.fromJson(Map<Object?, Object?> json) {
    return DriverOfferStatus(
      detected: json['lastOfferDetected'] as bool? ?? false,
      ageMs: json['lastOfferAgeMs'] as int?,
      summary: json['lastOfferSummary'] as String?,
      signals: (json['lastOfferSignals'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      classification: json['lastOfferClassification'] as String?,
      isActionable: json['lastOfferActionable'] as bool? ?? false,
      missingRequirements:
          (json['lastOfferMissingRequirements'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
    );
  }
}

class DriverStructuredOfferStatus {
  const DriverStructuredOfferStatus({
    required this.providerKey,
    required this.classification,
    required this.isActionable,
    this.productName,
    this.fareAmountText,
    this.fareAmountCents,
    this.pickupEtaText,
    this.pickupDistanceText,
    this.tripDurationText,
    this.tripDistanceText,
    this.primaryLocationText,
    this.secondaryLocationText,
    this.ctaText,
    this.confidence = 'LOW',
    this.missingFields = const [],
    this.rawTexts = const [],
    required this.parsedAt,
  });

  final String providerKey;
  final String classification;
  final bool isActionable;
  final String? productName;
  final String? fareAmountText;
  final int? fareAmountCents;
  final String? pickupEtaText;
  final String? pickupDistanceText;
  final String? tripDurationText;
  final String? tripDistanceText;
  final String? primaryLocationText;
  final String? secondaryLocationText;
  final String? ctaText;
  final String confidence;
  final List<String> missingFields;
  final List<String> rawTexts;
  final String parsedAt;

  factory DriverStructuredOfferStatus.fromJson(Map<Object?, Object?> json) {
    return DriverStructuredOfferStatus(
      providerKey: json['providerKey'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      isActionable: json['isActionable'] as bool? ?? false,
      productName: json['productName'] as String?,
      fareAmountText: json['fareAmountText'] as String?,
      fareAmountCents: json['fareAmountCents'] as int?,
      pickupEtaText: json['pickupEtaText'] as String?,
      pickupDistanceText: json['pickupDistanceText'] as String?,
      tripDurationText: json['tripDurationText'] as String?,
      tripDistanceText: json['tripDistanceText'] as String?,
      primaryLocationText: json['primaryLocationText'] as String?,
      secondaryLocationText: json['secondaryLocationText'] as String?,
      ctaText: json['ctaText'] as String?,
      confidence: json['confidence'] as String? ?? 'LOW',
      missingFields: (json['missingFields'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      rawTexts: (json['rawTexts'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      parsedAt: json['parsedAt'] as String? ?? '',
    );
  }
}

class DriverSignalPreferencesStatus {
  const DriverSignalPreferencesStatus({
    required this.minGreenFarePerKm,
    required this.minYellowFarePerKm,
    required this.minGreenFarePerHour,
    required this.minYellowFarePerHour,
    required this.minTotalFare,
    required this.maxTotalDistanceKm,
    required this.maxTotalDurationMin,
    required this.updatedAt,
    required this.source,
  });

  final double minGreenFarePerKm;
  final double minYellowFarePerKm;
  final double minGreenFarePerHour;
  final double minYellowFarePerHour;
  final double minTotalFare;
  final double maxTotalDistanceKm;
  final int maxTotalDurationMin;
  final String updatedAt;
  final String source;

  bool get isDefault => source == 'DEFAULT';

  factory DriverSignalPreferencesStatus.fromJson(Map<Object?, Object?> json) {
    return DriverSignalPreferencesStatus(
      minGreenFarePerKm: (json['minGreenFarePerKm'] as num?)?.toDouble() ?? 2.0,
      minYellowFarePerKm:
          (json['minYellowFarePerKm'] as num?)?.toDouble() ?? 1.5,
      minGreenFarePerHour:
          (json['minGreenFarePerHour'] as num?)?.toDouble() ?? 45.0,
      minYellowFarePerHour:
          (json['minYellowFarePerHour'] as num?)?.toDouble() ?? 30.0,
      minTotalFare: (json['minTotalFare'] as num?)?.toDouble() ?? 10.0,
      maxTotalDistanceKm:
          (json['maxTotalDistanceKm'] as num?)?.toDouble() ?? 25.0,
      maxTotalDurationMin: (json['maxTotalDurationMin'] as num?)?.toInt() ?? 60,
      updatedAt: json['updatedAt'] as String? ?? '',
      source: json['source'] as String? ?? 'DEFAULT',
    );
  }
}

class DriverSignalPreferencesInput {
  const DriverSignalPreferencesInput({
    required this.minGreenFarePerKm,
    required this.minYellowFarePerKm,
    required this.minGreenFarePerHour,
    required this.minYellowFarePerHour,
    required this.minTotalFare,
    required this.maxTotalDistanceKm,
    required this.maxTotalDurationMin,
  });

  final String minGreenFarePerKm;
  final String minYellowFarePerKm;
  final String minGreenFarePerHour;
  final String minYellowFarePerHour;
  final String minTotalFare;
  final String maxTotalDistanceKm;
  final String maxTotalDurationMin;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'minGreenFarePerKm': minGreenFarePerKm,
      'minYellowFarePerKm': minYellowFarePerKm,
      'minGreenFarePerHour': minGreenFarePerHour,
      'minYellowFarePerHour': minYellowFarePerHour,
      'minTotalFare': minTotalFare,
      'maxTotalDistanceKm': maxTotalDistanceKm,
      'maxTotalDurationMin': maxTotalDurationMin,
    };
  }
}

class DriverSignalPreferencesValidationException implements Exception {
  const DriverSignalPreferencesValidationException(this.validationErrors);

  final List<String> validationErrors;
}

class DriverOfferSignalStatus {
  const DriverOfferSignalStatus({
    required this.color,
    required this.label,
    required this.reason,
    this.warnings = const [],
    this.farePerKmText,
    this.farePerHourText,
    this.estimatedTotalDistanceKm,
    this.estimatedTotalDurationMin,
    this.estimatedTotalDistanceText,
    this.estimatedTotalDurationText,
    this.ruleVersion,
    this.computedAt,
    this.preferencesSource,
  });

  final String color;
  final String label;
  final String reason;
  final List<String> warnings;
  final String? farePerKmText;
  final String? farePerHourText;
  final double? estimatedTotalDistanceKm;
  final int? estimatedTotalDurationMin;
  final String? estimatedTotalDistanceText;
  final String? estimatedTotalDurationText;
  final String? ruleVersion;
  final String? computedAt;
  final String? preferencesSource;

  factory DriverOfferSignalStatus.fromJson(Map<Object?, Object?> json) {
    return DriverOfferSignalStatus(
      color: json['color'] as String? ?? 'RED',
      label: json['label'] as String? ?? 'Vermelho',
      reason: json['reason'] as String? ?? 'Farol indisponível.',
      warnings: (json['warnings'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      farePerKmText: json['farePerKmText'] as String?,
      farePerHourText: json['farePerHourText'] as String?,
      estimatedTotalDistanceKm: (json['estimatedTotalDistanceKm'] as num?)
          ?.toDouble(),
      estimatedTotalDurationMin: (json['estimatedTotalDurationMin'] as num?)
          ?.toInt(),
      estimatedTotalDistanceText: json['estimatedTotalDistanceText'] as String?,
      estimatedTotalDurationText: json['estimatedTotalDurationText'] as String?,
      ruleVersion: json['ruleVersion'] as String?,
      computedAt: json['computedAt'] as String?,
      preferencesSource: json['preferencesSource'] as String?,
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
    required this.lastOffer,
    required this.structuredOfferPresent,
    required this.structuredOffer,
    required this.offerClassification,
    required this.offerActionable,
    required this.offerMissingFields,
    required this.offerParsingConfidence,
    required this.offerSignalPresent,
    required this.offerSignal,
    required this.offerSignalColor,
    required this.offerSignalReason,
    required this.offerSignalWarnings,
    required this.farePerKmText,
    required this.farePerHourText,
    required this.estimatedTotalDistanceText,
    required this.estimatedTotalDurationText,
    required this.signalRuleVersion,
    required this.signalPreferences,
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
  final DriverOfferStatus lastOffer;
  final bool structuredOfferPresent;
  final DriverStructuredOfferStatus? structuredOffer;
  final String? offerClassification;
  final bool offerActionable;
  final List<String> offerMissingFields;
  final String? offerParsingConfidence;
  final bool offerSignalPresent;
  final DriverOfferSignalStatus? offerSignal;
  final String? offerSignalColor;
  final String? offerSignalReason;
  final List<String> offerSignalWarnings;
  final String? farePerKmText;
  final String? farePerHourText;
  final String? estimatedTotalDistanceText;
  final String? estimatedTotalDurationText;
  final String? signalRuleVersion;
  final DriverSignalPreferencesStatus signalPreferences;
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
      lastOffer: DriverOfferStatus.fromJson(json),
      structuredOfferPresent: json['structuredOfferPresent'] as bool? ?? false,
      structuredOffer:
          (json['structuredOffer'] as Map<Object?, Object?>?) != null
          ? DriverStructuredOfferStatus.fromJson(
              json['structuredOffer'] as Map<Object?, Object?>,
            )
          : null,
      offerClassification: json['offerClassification'] as String?,
      offerActionable: json['isActionable'] as bool? ?? false,
      offerMissingFields: (json['missingFields'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      offerParsingConfidence: json['parsingConfidence'] as String?,
      offerSignalPresent: json['offerSignalPresent'] as bool? ?? false,
      offerSignal: (json['offerSignal'] as Map<Object?, Object?>?) != null
          ? DriverOfferSignalStatus.fromJson(
              json['offerSignal'] as Map<Object?, Object?>,
            )
          : null,
      offerSignalColor: json['offerSignalColor'] as String?,
      offerSignalReason: json['offerSignalReason'] as String?,
      offerSignalWarnings:
          (json['offerSignalWarnings'] as List<Object?>? ?? const [])
              .whereType<String>()
              .toList(),
      farePerKmText: json['farePerKmText'] as String?,
      farePerHourText: json['farePerHourText'] as String?,
      estimatedTotalDistanceText: json['estimatedTotalDistanceText'] as String?,
      estimatedTotalDurationText: json['estimatedTotalDurationText'] as String?,
      signalRuleVersion: json['signalRuleVersion'] as String?,
      signalPreferences: DriverSignalPreferencesStatus.fromJson(
        json['signalPreferences'] as Map<Object?, Object?>? ?? const {},
      ),
      contextTtlSeconds: json['contextTtlSeconds'] as int? ?? 15,
      androidAutoPrepared: json['androidAutoPrepared'] as bool? ?? false,
    );
  }
}

abstract interface class DriverNativeBridge {
  Future<DriverNativeFoundationStatus> getFoundationStatus();

  Future<DriverSignalPreferencesStatus> getSignalPreferences();

  Future<DriverNativeFoundationStatus> saveSignalPreferences({
    required DriverSignalPreferencesInput input,
  });

  Future<DriverNativeFoundationStatus> resetSignalPreferences();

  Future<bool> openAccessibilitySettings();

  Future<DriverNativeFoundationStatus> requestAcceptCommand({
    String source = 'FLUTTER_HANDSET',
  });
}
