package com.example.despesas_frontend.driver

import android.content.Intent
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
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
        private const val METHOD_OPEN_ACCESSIBILITY_SETTINGS = "openAccessibilitySettings"
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_FOUNDATION_STATUS -> {
                result.success(buildSnapshot().toMap())
                return
            }
            METHOD_OPEN_ACCESSIBILITY_SETTINGS -> {
                result.success(openAccessibilitySettings())
                return
            }
        }
        result.notImplemented()
    }

    private fun buildSnapshot(): DriverModuleNativeSnapshot {
        val accessibilityServiceDeclared = isAccessibilityServiceDeclared()
        val accessibilityServiceEnabled = isAccessibilityServiceEnabled()
        val canOpenAccessibilitySettings = canOpenAccessibilitySettings()
        val missingCapabilities = buildMissingCapabilities(
            accessibilityServiceDeclared = accessibilityServiceDeclared,
            accessibilityServiceEnabled = accessibilityServiceEnabled,
            canOpenAccessibilitySettings = canOpenAccessibilitySettings,
        )
        return DriverModuleNativeSnapshot(
            packageName = context.packageName,
            methodChannel = CHANNEL_NAME,
            nativeBridgeAvailable = true,
            methodChannelReady = true,
            accessibilityServiceDeclared = accessibilityServiceDeclared,
            accessibilityServiceEnabled = accessibilityServiceEnabled,
            canOpenAccessibilitySettings = canOpenAccessibilitySettings,
            moduleReady = missingCapabilities.isEmpty(),
            missingCapabilities = missingCapabilities,
            androidAutoPrepared = false,
        )
    }

    private fun buildMissingCapabilities(
        accessibilityServiceDeclared: Boolean,
        accessibilityServiceEnabled: Boolean,
        canOpenAccessibilitySettings: Boolean,
    ): List<String> {
        val missing = mutableListOf<String>()
        if (!accessibilityServiceDeclared) {
            missing += "ACCESSIBILITY_SERVICE_NOT_DECLARED"
        }
        if (!accessibilityServiceEnabled) {
            missing += "ACCESSIBILITY_SERVICE_DISABLED"
        }
        if (!canOpenAccessibilitySettings) {
            missing += "ACCESSIBILITY_SETTINGS_UNAVAILABLE"
        }
        return missing
    }

    private fun isAccessibilityServiceDeclared(): Boolean {
        val componentName = ComponentName(
            context,
            DriverAccessibilityService::class.java,
        )
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getServiceInfo(
                    componentName,
                    PackageManager.ComponentInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getServiceInfo(
                    componentName,
                    PackageManager.GET_META_DATA,
                )
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
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

    private fun canOpenAccessibilitySettings(): Boolean {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return intent.resolveActivity(context.packageManager) != null
    }

    private fun openAccessibilitySettings(): Boolean {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        if (intent.resolveActivity(context.packageManager) == null) {
            return false
        }
        context.startActivity(intent)
        return true
    }
}
