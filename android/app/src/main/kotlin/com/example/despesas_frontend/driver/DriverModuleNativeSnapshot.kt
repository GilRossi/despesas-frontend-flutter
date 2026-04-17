package com.example.despesas_frontend.driver

data class DriverTargetAppSnapshot(
    val key: String,
    val label: String,
    val installed: Boolean,
    val detectedPackageName: String?,
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "key" to key,
            "label" to label,
            "installed" to installed,
            "detectedPackageName" to detectedPackageName,
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
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
