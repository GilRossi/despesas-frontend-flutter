package com.example.despesas_frontend.driver

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DriverModuleMethodChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.gilrossi.despesas/driver_module"
        private const val METHOD_GET_FOUNDATION_STATUS = "getFoundationStatus"
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == METHOD_GET_FOUNDATION_STATUS) {
            result.success(buildSnapshot().toMap())
            return
        }
        result.notImplemented()
    }

    private fun buildSnapshot(): DriverModuleNativeSnapshot {
        return DriverModuleNativeSnapshot(
            packageName = context.packageName,
            methodChannel = CHANNEL_NAME,
            methodChannelReady = true,
            accessibilityServiceDeclared = true,
            accessibilityServiceEnabled = isAccessibilityServiceEnabled(),
            androidAutoPrepared = false,
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedService = ComponentName(
            context,
            DriverAccessibilityService::class.java,
        ).flattenToString()
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabledServices
            .split(':')
            .any { candidate -> candidate.equals(expectedService, ignoreCase = true) }
    }
}
