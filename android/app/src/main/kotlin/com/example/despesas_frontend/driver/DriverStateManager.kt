package com.example.despesas_frontend.driver

import java.time.Duration
import java.time.Instant

object DriverStateManager {
    private const val CONTEXT_TTL_SECONDS = 15L

    private var packageName: String = ""
    private var methodChannel: String = ""
    private var nativeBridgeAvailable: Boolean = false
    private var methodChannelReady: Boolean = false
    private var accessibilityServiceDeclared: Boolean = false
    private var accessibilityServiceEnabled: Boolean = false
    private var canOpenAccessibilitySettings: Boolean = false
    private var missingCapabilities: List<String> = emptyList()
    private var targetApps: List<DriverTargetAppSnapshot> = emptyList()
    private var androidAutoPrepared: Boolean = false

    private val providerContextsByKey = linkedMapOf<String, DriverProviderContextSnapshot>()

    private var focusedProviderKey: String? = null
    private var focusedProviderLabel: String? = null
    private var focusedPackageName: String? = null
    private var lastInvalidationReason: String? = "NO_CONTEXT"

    private var acceptCommand = DriverAcceptCommandSnapshot.idle()

    @Synchronized
    fun updateFoundation(
        packageName: String,
        methodChannel: String,
        nativeBridgeAvailable: Boolean,
        methodChannelReady: Boolean,
        accessibilityServiceDeclared: Boolean,
        accessibilityServiceEnabled: Boolean,
        canOpenAccessibilitySettings: Boolean,
        missingCapabilities: List<String>,
        targetApps: List<DriverTargetAppSnapshot>,
        androidAutoPrepared: Boolean,
    ) {
        this.packageName = packageName
        this.methodChannel = methodChannel
        this.nativeBridgeAvailable = nativeBridgeAvailable
        this.methodChannelReady = methodChannelReady
        this.accessibilityServiceDeclared = accessibilityServiceDeclared
        this.accessibilityServiceEnabled = accessibilityServiceEnabled
        this.canOpenAccessibilitySettings = canOpenAccessibilitySettings
        this.missingCapabilities = missingCapabilities
        this.targetApps = targetApps
        this.androidAutoPrepared = androidAutoPrepared
    }

    @Synchronized
    fun recordProviderEvent(
        providerKey: String,
        providerLabel: String,
        packageName: String,
        eventType: String,
        texts: List<String>,
    ) {
        val now = Instant.now()
        val previousProviderKey = focusedProviderKey
        focusedProviderKey = providerKey
        focusedProviderLabel = providerLabel
        focusedPackageName = packageName
        lastInvalidationReason = null

        if (texts.isNotEmpty()) {
            providerContextsByKey[providerKey] = DriverProviderContextSnapshot(
                providerKey = providerKey,
                label = providerLabel,
                packageName = packageName,
                eventType = eventType,
                capturedAt = now.toString(),
                texts = texts,
            )
        }

        if (acceptCommand.state == "PENDING_EXECUTOR" &&
            previousProviderKey != null &&
            previousProviderKey != providerKey &&
            acceptCommand.targetProviderKey != providerKey
        ) {
            acceptCommand = acceptCommand.invalidated(
                reason = "PROVIDER_CHANGED",
                updatedAt = now,
            )
        }

        advanceAcceptCommandIfPossible(now)
    }

    @Synchronized
    fun markProviderOutOfFocus(packageName: String) {
        if (focusedProviderKey == null) {
            return
        }
        if (packageName.equals(focusedPackageName, ignoreCase = true)) {
            return
        }
        focusedProviderKey = null
        focusedProviderLabel = null
        focusedPackageName = null
        lastInvalidationReason = "PROVIDER_OUT_OF_FOCUS"
    }

    @Synchronized
    fun requestAcceptCommand(source: String): DriverModuleNativeSnapshot {
        val now = Instant.now()
        val currentContext = resolveCurrentContext(now)
        val targetProviderKey = currentContext.providerKey.takeIf { it.isNotBlank() }
        val targetPackageName = currentContext.packageName.takeIf { it.isNotBlank() }
        val canQueue = moduleOperationallyReady() &&
            targetProviderKey != null &&
            targetAppReady(targetProviderKey) &&
            currentContext.isActionable

        acceptCommand = if (canQueue) {
            DriverAcceptCommandSnapshot.pending(
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                updatedAt = now,
            )
        } else {
            DriverAcceptCommandSnapshot.blocked(
                source = source,
                targetProviderKey = targetProviderKey,
                targetPackageName = targetPackageName,
                updatedAt = now,
                reason = commandBlockReason(currentContext, targetProviderKey),
            )
        }

        advanceAcceptCommandIfPossible(now)
        return buildSnapshot(now)
    }

    @Synchronized
    fun snapshot(): DriverModuleNativeSnapshot {
        return buildSnapshot(Instant.now())
    }

    private fun buildSnapshot(now: Instant): DriverModuleNativeSnapshot {
        reconcileAcceptCommand(now)
        val currentContext = resolveCurrentContext(now)
        return DriverModuleNativeSnapshot(
            packageName = packageName,
            methodChannel = methodChannel,
            nativeBridgeAvailable = nativeBridgeAvailable,
            methodChannelReady = methodChannelReady,
            accessibilityServiceDeclared = accessibilityServiceDeclared,
            accessibilityServiceEnabled = accessibilityServiceEnabled,
            canOpenAccessibilitySettings = canOpenAccessibilitySettings,
            moduleReady = missingCapabilities.isEmpty(),
            missingCapabilities = missingCapabilities,
            targetApps = targetApps,
            providerContexts = providerContextsByKey.values.toList(),
            signal = buildSignal(currentContext),
            currentContext = currentContext,
            acceptCommand = acceptCommand,
            contextTtlSeconds = CONTEXT_TTL_SECONDS.toInt(),
            androidAutoPrepared = androidAutoPrepared,
        )
    }

    private fun buildSignal(currentContext: DriverCurrentContextSnapshot): DriverOperationalSignalSnapshot {
        if (!moduleOperationallyReady()) {
            return DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = "MODULE_BLOCKED",
            )
        }

        val providerKey = currentContext.providerKey.takeIf { it.isNotBlank() }
        if (providerKey != null && !targetAppReady(providerKey)) {
            return DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = "PROVIDER_NOT_READY",
            )
        }

        return when (currentContext.validity) {
            "VALID" -> DriverOperationalSignalSnapshot(
                color = "GREEN",
                label = "Verde",
                reason = "FOCUSED_CONTEXT_READY",
            )
            "STALE" -> DriverOperationalSignalSnapshot(
                color = "YELLOW",
                label = "Amarelo",
                reason = "RECENT_CONTEXT_OUT_OF_FOCUS",
            )
            "INCOMPLETE" -> DriverOperationalSignalSnapshot(
                color = "YELLOW",
                label = "Amarelo",
                reason = "FOCUSED_CONTEXT_INCOMPLETE",
            )
            else -> DriverOperationalSignalSnapshot(
                color = "RED",
                label = "Vermelho",
                reason = currentContext.invalidationReason ?: "NO_CONTEXT",
            )
        }
    }

    private fun resolveCurrentContext(now: Instant): DriverCurrentContextSnapshot {
        val focusedProviderKey = focusedProviderKey
        val focusedProviderLabel = focusedProviderLabel
        val focusedPackageName = focusedPackageName

        if (focusedProviderKey != null &&
            focusedProviderLabel != null &&
            focusedPackageName != null
        ) {
            val context = providerContextsByKey[focusedProviderKey]
            if (context == null) {
                return DriverCurrentContextSnapshot(
                    providerKey = focusedProviderKey,
                    label = focusedProviderLabel,
                    packageName = focusedPackageName,
                    eventType = "",
                    capturedAt = "",
                    texts = emptyList(),
                    inFocus = true,
                    validity = "INCOMPLETE",
                    validUntil = "",
                    invalidationReason = "CONTEXT_NOT_CAPTURED",
                )
            }
            return buildContextSnapshot(
                snapshot = context,
                inFocus = true,
                now = now,
                defaultInvalidationReason = null,
            )
        }

        val latestContext = providerContextsByKey.values.maxByOrNull { snapshot ->
            Instant.parse(snapshot.capturedAt)
        }
        if (latestContext != null) {
            return buildContextSnapshot(
                snapshot = latestContext,
                inFocus = false,
                now = now,
                defaultInvalidationReason = lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS",
            )
        }

        return DriverCurrentContextSnapshot(
            providerKey = "",
            label = "",
            packageName = "",
            eventType = "",
            capturedAt = "",
            texts = emptyList(),
            inFocus = false,
            validity = "INVALID",
            validUntil = "",
            invalidationReason = lastInvalidationReason ?: "NO_CONTEXT",
        )
    }

    private fun buildContextSnapshot(
        snapshot: DriverProviderContextSnapshot,
        inFocus: Boolean,
        now: Instant,
        defaultInvalidationReason: String?,
    ): DriverCurrentContextSnapshot {
        val capturedAt = Instant.parse(snapshot.capturedAt)
        val validUntil = capturedAt.plusSeconds(CONTEXT_TTL_SECONDS)
        val expired = now.isAfter(validUntil)
        return DriverCurrentContextSnapshot(
            providerKey = snapshot.providerKey,
            label = snapshot.label,
            packageName = snapshot.packageName,
            eventType = snapshot.eventType,
            capturedAt = snapshot.capturedAt,
            texts = snapshot.texts,
            inFocus = inFocus,
            validity = when {
                expired -> "EXPIRED"
                inFocus -> "VALID"
                else -> "STALE"
            },
            validUntil = validUntil.toString(),
            invalidationReason = when {
                expired -> "CONTEXT_TTL_EXPIRED"
                inFocus -> null
                else -> defaultInvalidationReason
            },
        )
    }

    private fun commandBlockReason(
        currentContext: DriverCurrentContextSnapshot,
        targetProviderKey: String?,
    ): String {
        return when {
            !moduleOperationallyReady() -> "MODULE_NOT_READY"
            targetProviderKey == null -> "NO_PROVIDER_CONTEXT"
            !targetAppReady(targetProviderKey) -> "TARGET_APP_NOT_READY"
            currentContext.validity == "EXPIRED" -> "CONTEXT_TTL_EXPIRED"
            currentContext.validity == "INVALID" -> currentContext.invalidationReason ?: "NO_PROVIDER_CONTEXT"
            currentContext.validity == "INCOMPLETE" -> "CONTEXT_NOT_CAPTURED"
            else -> "COMMAND_BLOCKED"
        }
    }

    private fun reconcileAcceptCommand(now: Instant) {
        if (!acceptCommand.hasPendingOrReady) {
            return
        }
        val targetProviderKey = acceptCommand.targetProviderKey ?: run {
            acceptCommand = acceptCommand.invalidated("NO_PROVIDER_CONTEXT", now)
            return
        }
        val targetContext = contextForProvider(targetProviderKey, now)
        if (targetContext == null || !targetContext.isActionable) {
            acceptCommand = acceptCommand.invalidated(
                reason = targetContext?.invalidationReason ?: "NO_PROVIDER_CONTEXT",
                updatedAt = now,
            )
        }
    }

    private fun advanceAcceptCommandIfPossible(now: Instant) {
        if (acceptCommand.state != "PENDING_EXECUTOR") {
            return
        }
        val targetProviderKey = acceptCommand.targetProviderKey ?: return
        val currentContext = resolveCurrentContext(now)
        if (currentContext.providerKey == targetProviderKey &&
            currentContext.validity == "VALID"
        ) {
            acceptCommand = acceptCommand.executorReady(updatedAt = now)
        }
    }

    private fun contextForProvider(
        providerKey: String,
        now: Instant,
    ): DriverCurrentContextSnapshot? {
        val providerSnapshot = providerContextsByKey[providerKey] ?: return null
        return buildContextSnapshot(
            snapshot = providerSnapshot,
            inFocus = focusedProviderKey == providerKey,
            now = now,
            defaultInvalidationReason = if (focusedProviderKey == providerKey) {
                null
            } else {
                lastInvalidationReason ?: "PROVIDER_OUT_OF_FOCUS"
            },
        )
    }

    private fun targetAppReady(providerKey: String): Boolean {
        return targetApps.firstOrNull { target -> target.key == providerKey }?.appReady == true
    }

    private fun moduleOperationallyReady(): Boolean {
        return accessibilityServiceDeclared &&
            accessibilityServiceEnabled &&
            canOpenAccessibilitySettings &&
            targetApps.any { target -> target.appReady }
    }
}
