package com.example.despesas_frontend.driver

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
    val androidAutoPrepared: Boolean,
) {
    fun toMap(): Map<String, Any> {
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
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
