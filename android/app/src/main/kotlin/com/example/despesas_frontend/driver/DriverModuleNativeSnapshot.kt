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
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "providerKey" to providerKey,
            "label" to label,
            "packageName" to packageName,
            "eventType" to eventType,
            "capturedAt" to capturedAt,
            "texts" to texts,
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
) {
    val isActionable: Boolean
        get() = validity == "VALID" || validity == "STALE"

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
            "contextTtlSeconds" to contextTtlSeconds,
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
