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
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
