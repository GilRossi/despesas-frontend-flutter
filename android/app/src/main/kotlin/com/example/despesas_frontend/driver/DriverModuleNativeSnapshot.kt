package com.example.despesas_frontend.driver

data class DriverModuleNativeSnapshot(
    val packageName: String,
    val methodChannel: String,
    val methodChannelReady: Boolean,
    val accessibilityServiceDeclared: Boolean,
    val accessibilityServiceEnabled: Boolean,
    val androidAutoPrepared: Boolean,
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "packageName" to packageName,
            "methodChannel" to methodChannel,
            "methodChannelReady" to methodChannelReady,
            "accessibilityServiceDeclared" to accessibilityServiceDeclared,
            "accessibilityServiceEnabled" to accessibilityServiceEnabled,
            "androidAutoPrepared" to androidAutoPrepared,
        )
    }
}
