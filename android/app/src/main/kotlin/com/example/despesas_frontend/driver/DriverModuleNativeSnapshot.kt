package com.example.despesas_frontend.driver

data class DriverTargetAppSnapshot(
    val key: String,
    val label: String,
    val packageName: String,
    val installed: Boolean,
    val enabledInSystem: Boolean,
    val launchIntentAvailable: Boolean,
    val appReady: Boolean,
    val missingCapabilities: List<String>,
    val detectedPackageName: String?,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "key" to key,
            "label" to label,
            "packageName" to packageName,
            "installed" to installed,
            "enabledInSystem" to enabledInSystem,
            "launchIntentAvailable" to launchIntentAvailable,
            "appReady" to appReady,
            "missingCapabilities" to missingCapabilities,
            "detectedPackageName" to detectedPackageName,
        )
    }
}

data class DriverProviderContextSnapshot(
    val providerKey: String,
    val label: String,
    val packageName: String,
    val eventType: String,
    val capturedAt: String,
    val texts: List<String>,
    val semanticState: DriverSemanticStateSnapshot,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "providerKey" to providerKey,
            "label" to label,
            "packageName" to packageName,
            "eventType" to eventType,
            "capturedAt" to capturedAt,
            "texts" to texts,
            "semanticState" to semanticState.toMap(),
        )
    }
}

data class DriverSemanticStateSnapshot(
    val code: String,
    val label: String,
    val summary: String,
    val contextRelevant: Boolean,
    val confidence: String,
    val detectedSignals: List<String>,
    val missingRequirements: List<String> = emptyList(),
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "label" to label,
            "summary" to summary,
            "contextRelevant" to contextRelevant,
            "confidence" to confidence,
            "detectedSignals" to detectedSignals,
            "missingRequirements" to missingRequirements,
        )
    }
}

data class DriverOfferSnapshot(
    val timestamp: String,
    val providerKey: String,
    val providerLabel: String,
    val packageName: String,
    val rawTexts: List<String>,
    val detectedSignals: List<String>,
    val summary: String,
    val confidence: String,
    val classification: String,
    val isActionable: Boolean,
    val missingRequirements: List<String>,
    val structuredOffer: DriverStructuredOffer?,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "timestamp" to timestamp,
            "providerKey" to providerKey,
            "providerLabel" to providerLabel,
            "packageName" to packageName,
            "rawTexts" to rawTexts,
            "detectedSignals" to detectedSignals,
            "summary" to summary,
            "confidence" to confidence,
            "classification" to classification,
            "isActionable" to isActionable,
            "missingRequirements" to missingRequirements,
            "structuredOffer" to structuredOffer?.toMap(),
        )
    }
}

data class DriverOperationalSignalSnapshot(
    val color: String,
    val label: String,
    val reason: String,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "color" to color,
            "label" to label,
            "reason" to reason,
        )
    }
}

data class DriverCurrentContextSnapshot(
    val providerKey: String,
    val label: String,
    val packageName: String,
    val eventType: String,
    val capturedAt: String,
    val texts: List<String>,
    val inFocus: Boolean,
    val validity: String,
    val validUntil: String,
    val invalidationReason: String?,
    val semanticState: DriverSemanticStateSnapshot,
) {
    val isActionable: Boolean
        get() = (validity == "VALID" || validity == "STALE") && semanticState.contextRelevant

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "providerKey" to providerKey,
            "label" to label,
            "packageName" to packageName,
            "eventType" to eventType,
            "capturedAt" to capturedAt,
            "texts" to texts,
            "inFocus" to inFocus,
            "validity" to validity,
            "validUntil" to validUntil,
            "invalidationReason" to invalidationReason,
            "semanticState" to semanticState.toMap(),
        )
    }
}

data class DriverAcceptCommandSnapshot(
    val state: String,
    val source: String?,
    val targetProviderKey: String?,
    val targetPackageName: String?,
    val requestedAt: String?,
    val lastUpdatedAt: String?,
    val reason: String?,
) {
    val hasPendingOrReady: Boolean
        get() = state == "PENDING_EXECUTOR" || state == "EXECUTOR_READY"

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "state" to state,
            "source" to source,
            "targetProviderKey" to targetProviderKey,
            "targetPackageName" to targetPackageName,
            "requestedAt" to requestedAt,
            "lastUpdatedAt" to lastUpdatedAt,
            "reason" to reason,
        )
    }

    fun executorReady(updatedAt: java.time.Instant): DriverAcceptCommandSnapshot {
        return copy(
            state = "EXECUTOR_READY",
            lastUpdatedAt = updatedAt.toString(),
            reason = null,
        )
    }

    fun invalidated(
        reason: String,
        updatedAt: java.time.Instant,
    ): DriverAcceptCommandSnapshot {
        return copy(
            state = "INVALIDATED",
            lastUpdatedAt = updatedAt.toString(),
            reason = reason,
        )
    }

    companion object {
        fun idle(): DriverAcceptCommandSnapshot {
            return DriverAcceptCommandSnapshot(
                state = "IDLE",
                source = null,
                targetProviderKey = null,
                targetPackageName = null,
                requestedAt = null,
                lastUpdatedAt = null,
                reason = null,
            )
        }

        fun pending(
            source: String,
            targetProviderKey: String?,
            targetPackageName: String?,
            updatedAt: java.time.Instant,
        ): DriverAcceptCommandSnapshot {
            return DriverAcceptCommandSnapshot(
                state = "PENDING_EXECUTOR",
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                requestedAt = updatedAt.toString(),
                lastUpdatedAt = updatedAt.toString(),
                reason = null,
            )
        }

        fun blocked(
            source: String,
            targetProviderKey: String?,
            targetPackageName: String?,
            updatedAt: java.time.Instant,
            reason: String,
        ): DriverAcceptCommandSnapshot {
            return DriverAcceptCommandSnapshot(
                state = "BLOCKED",
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                requestedAt = updatedAt.toString(),
                lastUpdatedAt = updatedAt.toString(),
                reason = reason,
            )
        }
    }
}

data class DriverModuleNativeSnapshot(
    val packageName: String,
    val methodChannel: String,
    val nativeBridgeAvailable: Boolean,
    val methodChannelReady: Boolean,
    val accessibilityServiceDeclared: Boolean,
    val accessibilityServiceEnabled: Boolean,
    val canOpenAccessibilitySettings: Boolean,
    val moduleReady: Boolean,
    val missingCapabilities: List<String>,
    val targetApps: List<DriverTargetAppSnapshot>,
    val providerContexts: List<DriverProviderContextSnapshot>,
    val signal: DriverOperationalSignalSnapshot,
    val currentContext: DriverCurrentContextSnapshot,
    val acceptCommand: DriverAcceptCommandSnapshot,
    val lastOfferDetected: Boolean,
    val lastOfferAgeMs: Long?,
    val lastOfferSummary: String?,
    val lastOfferSignals: List<String>,
    val lastOfferClassification: String?,
    val lastOfferActionable: Boolean,
    val lastOfferMissingRequirements: List<String>,
    val structuredOfferPresent: Boolean,
    val structuredOffer: DriverStructuredOffer?,
    val offerClassification: String?,
    val offerActionable: Boolean,
    val offerMissingFields: List<String>,
    val offerParsingConfidence: String?,
    val offerSignalPresent: Boolean,
    val offerSignal: DriverOfferSignal?,
    val offerSignalColor: String?,
    val offerSignalReason: String?,
    val offerSignalWarnings: List<String>,
    val farePerKmText: String?,
    val farePerMinuteText: String?,
    val estimatedTotalDistanceText: String?,
    val estimatedTotalDurationText: String?,
    val signalRuleVersion: String?,
    val contextTtlSeconds: Int,
    val androidAutoPrepared: Boolean,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "packageName" to packageName,
            "methodChannel" to methodChannel,
            "nativeBridgeAvailable" to nativeBridgeAvailable,
            "methodChannelReady" to methodChannelReady,
            "accessibilityServiceDeclared" to accessibilityServiceDeclared,
            "accessibilityServiceEnabled" to accessibilityServiceEnabled,
            "canOpenAccessibilitySettings" to canOpenAccessibilitySettings,
            "moduleReady" to moduleReady,
            "missingCapabilities" to missingCapabilities,
            "targetApps" to targetApps.map(DriverTargetAppSnapshot::toMap),
            "providerContexts" to providerContexts.map(DriverProviderContextSnapshot::toMap),
            "signal" to signal.toMap(),
            "currentContext" to currentContext.toMap(),
            "acceptCommand" to acceptCommand.toMap(),
            "lastOfferDetected" to lastOfferDetected,
            "lastOfferAgeMs" to lastOfferAgeMs,
            "lastOfferSummary" to lastOfferSummary,
            "lastOfferSignals" to lastOfferSignals,
            "lastOfferClassification" to lastOfferClassification,
            "lastOfferActionable" to lastOfferActionable,
            "lastOfferMissingRequirements" to lastOfferMissingRequirements,
            "structuredOfferPresent" to structuredOfferPresent,
            "structuredOffer" to structuredOffer?.toMap(),
            "offerClassification" to offerClassification,
            "isActionable" to offerActionable,
            "missingFields" to offerMissingFields,
            "parsingConfidence" to offerParsingConfidence,
            "offerSignalPresent" to offerSignalPresent,
            "offerSignal" to offerSignal?.toMap(),
            "offerSignalColor" to offerSignalColor,
            "offerSignalReason" to offerSignalReason,
            "offerSignalWarnings" to offerSignalWarnings,
            "farePerKmText" to farePerKmText,
            "farePerMinuteText" to farePerMinuteText,
            "estimatedTotalDistanceText" to estimatedTotalDistanceText,
            "estimatedTotalDurationText" to estimatedTotalDurationText,
            "signalRuleVersion" to signalRuleVersion,
            "contextTtlSeconds" to contextTtlSeconds,
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
