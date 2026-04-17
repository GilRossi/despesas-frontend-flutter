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
    data class DriverTargetApp(
        val key: String,
        val label: String,
        val packageCandidates: List<String>,
    )

    companion object {
        const val CHANNEL_NAME = "com.gilrossi.despesas/driver_module"
        private const val METHOD_GET_FOUNDATION_STATUS = "getFoundationStatus"
        private const val METHOD_OPEN_ACCESSIBILITY_SETTINGS = "openAccessibilitySettings"
        private val TARGET_APPS = listOf(
            DriverTargetApp(
                key = "UBER_DRIVER",
                label = "Uber Driver",
                packageCandidates = listOf("com.ubercab.driver"),
            ),
            DriverTargetApp(
                key = "APP99_DRIVER",
                label = "99 Motorista",
                packageCandidates = listOf("com.app99.driver"),
            ),
            DriverTargetApp(
                key = "INDRIVE_DRIVER",
                label = "inDrive",
                packageCandidates = listOf("sinet.startup.inDriver"),
            ),
            DriverTargetApp(
                key = "MOBIZAP_DRIVER",
                label = "MobizapSP Motorista",
                packageCandidates = listOf("br.com.csxinovacao.motorista.mobizapsp"),
            ),
            DriverTargetApp(
                key = "IFOOD_DRIVER",
                label = "iFood Entregador",
                packageCandidates = listOf("br.com.ifood.driver.app"),
            ),
            DriverTargetApp(
                key = "LALAMOVE_DRIVER",
                label = "Lalamove Driver",
                packageCandidates = listOf("com.lalamove.global.driver.sea"),
            ),
            DriverTargetApp(
                key = "RAPPI_DRIVER",
                label = "Rappi Entregador",
                packageCandidates = listOf("com.rappi.storekeeper"),
            ),
        )
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
        val targetApps = buildTargetApps(
            accessibilityServiceDeclared = accessibilityServiceDeclared,
            accessibilityServiceEnabled = accessibilityServiceEnabled,
        )
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
            targetApps = targetApps,
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

    private fun buildTargetApps(
        accessibilityServiceDeclared: Boolean,
        accessibilityServiceEnabled: Boolean,
    ): List<DriverTargetAppSnapshot> {
        return TARGET_APPS.map { target ->
            val detectedPackageName = target.packageCandidates.firstOrNull(::isPackageInstalled)
            val packageName = detectedPackageName ?: target.packageCandidates.first()
            val enabledInSystem = detectedPackageName?.let(::isApplicationEnabled) ?: false
            val launchIntentAvailable = detectedPackageName?.let(::hasLaunchIntent) ?: false
            val missingCapabilities = buildTargetAppMissingCapabilities(
                installed = detectedPackageName != null,
                enabledInSystem = enabledInSystem,
                launchIntentAvailable = launchIntentAvailable,
                accessibilityServiceDeclared = accessibilityServiceDeclared,
                accessibilityServiceEnabled = accessibilityServiceEnabled,
            )
            DriverTargetAppSnapshot(
                key = target.key,
                label = target.label,
                packageName = packageName,
                installed = detectedPackageName != null,
                enabledInSystem = enabledInSystem,
                launchIntentAvailable = launchIntentAvailable,
                appReady = missingCapabilities.isEmpty(),
                missingCapabilities = missingCapabilities,
                detectedPackageName = detectedPackageName,
            )
        }
    }

    private fun buildTargetAppMissingCapabilities(
        installed: Boolean,
        enabledInSystem: Boolean,
        launchIntentAvailable: Boolean,
        accessibilityServiceDeclared: Boolean,
        accessibilityServiceEnabled: Boolean,
    ): List<String> {
        val missing = mutableListOf<String>()
        if (!installed) {
            missing += "PACKAGE_NOT_INSTALLED"
        }
        if (installed && !enabledInSystem) {
            missing += "APP_DISABLED"
        }
        if (installed && !launchIntentAvailable) {
            missing += "LAUNCH_INTENT_UNAVAILABLE"
        }
        if (!accessibilityServiceDeclared) {
            missing += "ACCESSIBILITY_SERVICE_NOT_DECLARED"
        }
        if (!accessibilityServiceEnabled) {
            missing += "ACCESSIBILITY_SERVICE_DISABLED"
        }
        return missing
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun isApplicationEnabled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.ApplicationInfoFlags.of(0),
                ).enabled
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getApplicationInfo(packageName, 0).enabled
            }
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun hasLaunchIntent(packageName: String): Boolean {
        return context.packageManager.getLaunchIntentForPackage(packageName) != null
    }
}
